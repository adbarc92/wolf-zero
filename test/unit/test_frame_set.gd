extends GutTest

const Anim = preload("res://scripts/ecs/systems/animation_system.gd")

func test_frames_for_known_set():
	var anim = Anim.new()
	var pf := SpriteFrames.new()
	var ef := SpriteFrames.new()
	anim.frame_sets = {"player": pf, "enemy": ef}
	assert_eq(anim.frames_for("player"), pf)
	assert_eq(anim.frames_for("enemy"), ef)

func test_frames_for_unknown_falls_back_to_player():
	var anim = Anim.new()
	var pf := SpriteFrames.new()
	anim.frame_sets = {"player": pf}
	assert_eq(anim.frames_for("nope"), pf, "unknown set falls back to player")
