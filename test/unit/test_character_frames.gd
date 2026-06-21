extends GutTest

const CF = preload("res://scripts/render/character_frames.gd")

# The exact animation names that existed inline in main.gd today.
const PLAYER_ANIMS := [
	"idle", "run", "jump", "fall", "dash", "roll", "slide",
	"light_1", "light_2", "light_3", "light_4", "light_5",
	"hit", "crouch", "crouch_walk", "wall_slide", "wall_climb",
	"death", "jump_fall_inbetween", "turn_around",
	"crouch_transition", "crouch_attack",
	"light_1_nomove", "light_2_nomove", "light_3_nomove",
	"light_4_nomove", "light_5_nomove",
]

const ENEMY_ANIMS := [
	"idle", "run", "light_1", "slide", "hit",
	"wall_slide", "wall_climb", "death", "jump_fall_inbetween",
	"turn_around", "crouch_transition", "crouch_attack",
	"light_1_nomove", "light_2_nomove", "light_3_nomove",
	"light_4_nomove", "light_5_nomove",
]

# The boss (distinct Demon/Wolf Samurai sheet) covers the full clip set that
# derive_clip can emit — same names as the player, real or aliased.
const BOSS_ANIMS := PLAYER_ANIMS


func test_player_returns_sprite_frames():
	var sf = CF.player()
	assert_true(sf is SpriteFrames, "player() returns SpriteFrames")


func test_enemy_returns_sprite_frames():
	var sf = CF.enemy()
	assert_true(sf is SpriteFrames, "enemy() returns SpriteFrames")


func test_player_has_all_expected_anims():
	var sf = CF.player()
	for name in PLAYER_ANIMS:
		assert_true(sf.has_animation(name), "player has animation '%s'" % name)


func test_enemy_has_all_expected_anims():
	var sf = CF.enemy()
	for name in ENEMY_ANIMS:
		assert_true(sf.has_animation(name), "enemy has animation '%s'" % name)


func test_player_anim_count_matches():
	var sf = CF.player()
	assert_eq(sf.get_animation_names().size(), PLAYER_ANIMS.size(),
		"player animation count is exactly the documented set")


func test_enemy_anim_count_matches():
	var sf = CF.enemy()
	assert_eq(sf.get_animation_names().size(), ENEMY_ANIMS.size(),
		"enemy animation count is exactly the documented set")


func test_no_leftover_default_animation():
	var sf = CF.player()
	assert_false(sf.has_animation("default"), "default animation removed")


func test_player_fps_and_loop_parity_sample():
	# Spot-check fps/loop flags against the original inline values.
	var sf = CF.player()
	assert_eq(sf.get_animation_speed("idle"), 10.0, "idle fps")
	assert_true(sf.get_animation_loop("idle"), "idle loops")
	assert_eq(sf.get_animation_speed("run"), 14.0, "run fps")
	assert_true(sf.get_animation_loop("run"), "run loops")
	assert_eq(sf.get_animation_speed("light_1"), 16.0, "light_1 fps")
	assert_false(sf.get_animation_loop("light_1"), "light_1 does not loop")
	assert_eq(sf.get_animation_speed("crouch"), 8.0, "crouch fps")
	assert_false(sf.get_animation_loop("death"), "death does not loop")


func test_enemy_fps_and_loop_parity_sample():
	var sf = CF.enemy()
	assert_eq(sf.get_animation_speed("idle"), 10.0, "enemy idle fps")
	assert_eq(sf.get_animation_speed("run"), 12.0, "enemy run fps")
	assert_true(sf.get_animation_loop("run"), "enemy run loops")
	assert_eq(sf.get_animation_speed("light_1"), 14.0, "enemy light_1 fps")
	assert_false(sf.get_animation_loop("light_1"), "enemy light_1 does not loop")
	assert_eq(sf.get_animation_speed("light_1_nomove"), 16.0, "enemy light_1_nomove fps")


func test_boss_returns_sprite_frames():
	var sf = CF.boss()
	assert_true(sf is SpriteFrames, "boss() returns SpriteFrames")


func test_boss_has_full_clip_set():
	var sf = CF.boss()
	for name in BOSS_ANIMS:
		assert_true(sf.has_animation(name), "boss has animation '%s'" % name)


func test_boss_anim_count_matches():
	var sf = CF.boss()
	assert_eq(sf.get_animation_names().size(), BOSS_ANIMS.size(),
		"boss animation count is exactly the documented set")


# Frame dimensions: the strips are sliced at the documented per-character size,
# so the first idle frame must be exactly that wide/tall (player 96x96,
# enemy 96x64, boss 128x108).
func test_frame_sizes_match_source_sheets():
	var checks = [
		[CF.player(), 96, 96, "player"],
		[CF.enemy(), 96, 64, "enemy"],
		[CF.boss(), 128, 108, "boss"],
	]
	for c in checks:
		var tex = c[0].get_frame_texture("idle", 0)
		assert_eq(tex.get_width(), c[1], "%s idle frame width" % c[3])
		assert_eq(tex.get_height(), c[2], "%s idle frame height" % c[3])
