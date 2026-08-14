extends GutTest
## GameState: run lifecycle (lives / win / defeat), the state signal, and
## progression maths.
##
## Every test works on a fresh instance of the script rather than the GameState
## autoload, so nothing here leaks into other suites — and nothing calls
## save_game(), which would overwrite the real user:// save file.

var GameStateScript = preload("res://scripts/autoload/game_state.gd")

var state


func before_each():
	state = GameStateScript.new()
	autofree(state)


# =============================================================================
# RUN LIFECYCLE
# =============================================================================

func test_begin_run_restores_full_lives_and_starts_playing():
	state.lives = 1
	state.current_checkpoint = 4

	state.begin_run()

	assert_eq(state.lives, state.MAX_LIVES, "lives are refilled")
	assert_eq(state.current_checkpoint, 0, "checkpoint rewinds")
	assert_eq(state.current_state, state.State.PLAYING, "the run is live")


func test_lose_life_decrements_without_ending_the_run():
	state.begin_run()

	var run_over = state.lose_life()

	assert_eq(state.lives, 2, "one life spent")
	assert_false(run_over, "two lives left, run continues")
	assert_eq(state.current_state, state.State.PLAYING, "still playing")


func test_losing_the_last_life_ends_the_run():
	state.begin_run()
	state.lose_life()
	state.lose_life()

	var run_over = state.lose_life()

	assert_eq(state.lives, 0, "out of lives")
	assert_true(run_over, "the run reports itself over")
	assert_eq(state.current_state, state.State.GAME_OVER, "defeat state")


func test_lives_never_go_negative():
	state.begin_run()
	for _i in range(6):
		state.lose_life()
	assert_eq(state.lives, 0, "lives floor at zero")


func test_win_run_sets_victory():
	state.begin_run()
	state.win_run()
	assert_eq(state.current_state, state.State.VICTORY, "victory state")


# =============================================================================
# STATE SIGNAL
# =============================================================================

func test_state_change_emits_new_and_old():
	state.current_state = state.State.MENU
	watch_signals(state)

	state.current_state = state.State.PLAYING

	assert_signal_emitted_with_parameters(state, "state_changed",
		[state.State.PLAYING, state.State.MENU])


func test_setting_the_same_state_does_not_emit():
	state.current_state = state.State.PLAYING
	watch_signals(state)

	state.current_state = state.State.PLAYING

	assert_signal_not_emitted(state, "state_changed", "no-op assignment stays quiet")


# =============================================================================
# XP AND LEVELLING
# =============================================================================

func test_xp_accumulates_below_the_threshold():
	state.add_xp(40)
	assert_eq(state.player_data.xp, 40, "xp banked")
	assert_eq(state.player_data.level, 1, "not enough to level")


func test_hitting_the_threshold_levels_up_and_carries_the_remainder():
	# Level 1 needs 100 xp; the next threshold is 100 + 2*50 = 200.
	state.add_xp(130)

	assert_eq(state.player_data.level, 2, "levelled once")
	assert_eq(state.player_data.xp, 30, "remainder carried over")
	assert_eq(state.player_data.skill_points, 1, "one skill point granted")
	assert_eq(state.player_data.xp_to_next, 200, "threshold grew")


func test_a_single_award_can_grant_several_levels():
	state.add_xp(1000)
	assert_gt(state.player_data.level, 2, "one big award cascades through levels")
	assert_eq(state.player_data.skill_points, state.player_data.level - 1,
		"a skill point per level gained")


func test_levelling_stops_at_thirty():
	state.add_xp(10_000_000)
	assert_eq(state.player_data.level, 30, "level is capped at 30")


# =============================================================================
# CURRENCY AND UNLOCKS
# =============================================================================

func test_each_currency_accumulates_independently():
	state.add_currency("neon_yen", 250)
	state.add_currency("echo_fragments", 3)

	assert_eq(state.player_data.neon_yen, 250, "yen added")
	assert_eq(state.player_data.echo_fragments, 3, "fragments added")
	assert_eq(state.player_data.legacy_tokens, 0, "untouched currency stays put")


func test_unknown_currency_is_ignored():
	state.add_currency("bottlecaps", 100)
	assert_eq(state.player_data.neon_yen, 0, "nothing is credited by mistake")


func test_unlock_ability_flips_the_matching_flag():
	state.unlock_ability("dash")

	assert_true(state.player_data.has_dash, "dash unlocked")
	assert_false(state.player_data.has_grapple, "others untouched")


func test_unlock_weapon_adds_it_at_tier_one():
	state.unlock_weapon("kusarigama")

	assert_true("kusarigama" in state.player_data.weapons, "added to the arsenal")
	assert_eq(state.player_data.weapon_tiers["kusarigama"], 1, "starts at tier 1")


func test_unlocking_a_weapon_twice_does_not_duplicate_or_reset_it():
	state.unlock_weapon("kusarigama")
	state.upgrade_weapon("kusarigama")
	state.unlock_weapon("kusarigama")

	assert_eq(state.player_data.weapons.count("kusarigama"), 1, "listed once")
	assert_eq(state.player_data.weapon_tiers["kusarigama"], 2, "tier is not reset")


func test_upgrade_weapon_raises_the_tier():
	assert_true(state.upgrade_weapon("plasma_katana"), "upgrade accepted")
	assert_eq(state.player_data.weapon_tiers["plasma_katana"], 2, "now tier 2")


func test_upgrade_weapon_stops_at_tier_five():
	for _i in range(4):
		state.upgrade_weapon("plasma_katana")
	assert_eq(state.player_data.weapon_tiers["plasma_katana"], 5, "at the cap")

	assert_false(state.upgrade_weapon("plasma_katana"), "further upgrades refused")
	assert_eq(state.player_data.weapon_tiers["plasma_katana"], 5, "still 5")


func test_upgrading_an_unowned_weapon_fails():
	assert_false(state.upgrade_weapon("nonexistent_blade"), "cannot upgrade what you lack")


# =============================================================================
# MISSION GATING
# =============================================================================

func test_mission_one_is_always_unlocked():
	assert_true(state.is_mission_unlocked(1), "the first mission needs no key")


func test_later_missions_start_locked():
	assert_false(state.is_mission_unlocked(5), "not yet reachable")


func test_a_mission_marked_unlocked_is_unlocked():
	state.mission_progress["5"] = {"unlocked": true}
	assert_true(state.is_mission_unlocked(5), "explicit unlock is honoured")


func test_a_completed_mission_counts_as_unlocked():
	state.mission_progress["5"] = {"completed": true}
	assert_true(state.is_mission_unlocked(5), "completion implies access")
