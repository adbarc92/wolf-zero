extends GutTest
## Pure trigger-state tests for the onboarding prompts (Lane D).
## Drives Tutorial.TriggerState and the static trigger map directly — no scene.

const TutorialScript = preload("res://scripts/ui/tutorial.gd")


func _state() -> RefCounted:
	return TutorialScript.TriggerState.new()


# --- show-once semantics ----------------------------------------------------

func test_prompt_fires_once_then_is_spent():
	var s = _state()
	assert_eq(s.request(TutorialScript.PROMPT_PARRY), TutorialScript.PROMPT_PARRY,
		"first request returns the prompt id")
	assert_eq(s.request(TutorialScript.PROMPT_PARRY), "",
		"second request for same prompt returns nothing (show once)")


func test_was_shown_tracks_state():
	var s = _state()
	assert_false(s.was_shown(TutorialScript.PROMPT_ECHO), "not shown before request")
	s.request(TutorialScript.PROMPT_ECHO)
	assert_true(s.was_shown(TutorialScript.PROMPT_ECHO), "shown after request")


func test_prompts_are_independent():
	var s = _state()
	s.request(TutorialScript.PROMPT_MOMENTUM)
	# Spending momentum must not spend echo or parry.
	assert_eq(s.request(TutorialScript.PROMPT_ECHO), TutorialScript.PROMPT_ECHO)
	assert_eq(s.request(TutorialScript.PROMPT_PARRY), TutorialScript.PROMPT_PARRY)


func test_unknown_prompt_id_is_ignored():
	var s = _state()
	assert_eq(s.request("flux_capacitor"), "", "unknown id never shows")
	assert_false(s.was_shown("flux_capacitor"))


func test_all_shown_only_after_every_prompt():
	var s = _state()
	assert_false(s.all_shown(), "nothing shown yet")
	s.request(TutorialScript.PROMPT_MOMENTUM)
	s.request(TutorialScript.PROMPT_ECHO)
	assert_false(s.all_shown(), "parry still pending")
	s.request(TutorialScript.PROMPT_PARRY)
	assert_true(s.all_shown(), "all three mechanics taught")


# --- trigger map (event -> mechanic) ----------------------------------------

func test_momentum_changed_maps_to_momentum_when_rising():
	assert_eq(TutorialScript.prompt_for_momentum_changed(5.0), TutorialScript.PROMPT_MOMENTUM,
		"positive momentum teaches momentum")


func test_momentum_changed_at_zero_does_not_trigger():
	assert_eq(TutorialScript.prompt_for_momentum_changed(0.0), "",
		"zero/initial momentum should not teach anything")


func test_echo_threshold_maps_to_echo():
	assert_eq(TutorialScript.prompt_for_echo_threshold(), TutorialScript.PROMPT_ECHO)


func test_player_damaged_maps_to_parry():
	assert_eq(TutorialScript.prompt_for_player_damaged(), TutorialScript.PROMPT_PARRY,
		"first hit teaches parry")


# --- copy is present and short ----------------------------------------------

func test_every_prompt_has_copy():
	for id in [TutorialScript.PROMPT_MOMENTUM, TutorialScript.PROMPT_ECHO, TutorialScript.PROMPT_PARRY]:
		assert_true(TutorialScript.COPY.has(id), "%s has copy" % id)
		assert_true(TutorialScript.COPY[id].length() > 0, "%s copy non-empty" % id)
		assert_true(TutorialScript.COPY[id].length() <= 60, "%s copy stays short" % id)
