extends GutTest
## Lane B — SceneBackdrop (ansimuz Warped City CC0 parallax).

const ENV_DIR := "res://assets/environment/"


func test_is_parallax_background():
	var bg := SceneBackdrop.new()
	assert_true(bg is ParallaxBackground,
		"SceneBackdrop must be a ParallaxBackground so main.gd can add_child it directly")
	bg.free()


func test_expected_layer_count_is_three():
	# Warped City ships a 3-layer parallax.
	assert_eq(SceneBackdrop.expected_layer_count(), 3,
		"backdrop is configured for exactly 3 parallax layers")


func test_builds_one_parallaxlayer_per_spec():
	var bg := SceneBackdrop.new()
	add_child_autofree(bg)  # triggers _ready() -> build_layers()
	var layers := 0
	for child in bg.get_children():
		if child is ParallaxLayer:
			layers += 1
	assert_eq(layers, SceneBackdrop.expected_layer_count(),
		"one ParallaxLayer is built per configured layer")


func test_every_layer_has_a_sprite_with_texture():
	var bg := SceneBackdrop.new()
	add_child_autofree(bg)
	for child in bg.get_children():
		if child is ParallaxLayer:
			var spr := child.get_child(0)
			assert_true(spr is Sprite2D, "each layer holds a Sprite2D")
			assert_not_null(spr.texture, "each layer sprite has a texture loaded")


func test_layer_textures_resolve_by_path():
	# The real CC0 art drops in over placeholders at these exact paths.
	for spec in SceneBackdrop.LAYERS:
		var tex: Texture2D = load(ENV_DIR + spec.file)
		assert_not_null(tex, "layer texture exists at %s%s" % [ENV_DIR, spec.file])


func test_motion_scales_recede_far_to_near():
	# Declared far -> near: each layer scrolls faster than the previous.
	var prev := -1.0
	for spec in SceneBackdrop.LAYERS:
		assert_gt(spec.scroll, prev, "layer scroll scales increase far -> near")
		prev = spec.scroll


func test_build_layers_is_idempotent():
	var bg := SceneBackdrop.new()
	add_child_autofree(bg)
	# _ready already built once; build again should not duplicate.
	bg.build_layers()
	await get_tree().process_frame  # let queued_free settle
	var layers := 0
	for child in bg.get_children():
		if child is ParallaxLayer and not child.is_queued_for_deletion():
			layers += 1
	assert_eq(layers, SceneBackdrop.expected_layer_count(),
		"rebuilding does not duplicate layers")
