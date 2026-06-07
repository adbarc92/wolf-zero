extends GutTest

const Builder = preload("res://scripts/render/sprite_frames_builder.gd")

func test_builds_clip_from_strip():
	var tex_path = "res://assets/FreeKnight_v1/Colour1/NoOutline/120x80_PNGSheets/_Idle.png"
	var tex: Texture2D = load(tex_path)
	assert_not_null(tex, "FreeKnight idle strip loads")

	var sf := SpriteFrames.new()
	Builder.add_strip(sf, "idle", tex, 120, 80, 10.0)

	assert_true(sf.has_animation("idle"), "clip 'idle' added")
	var expected_frames = int(tex.get_width() / 120)
	assert_eq(sf.get_frame_count("idle"), expected_frames, "frame count = strip width / frame width")
