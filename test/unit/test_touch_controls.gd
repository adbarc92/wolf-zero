extends GutTest
const TC = preload("res://scripts/ui/touch_controls.gd")

func test_layout_covers_core_actions():
	var actions := []
	for spec in TC.layout():
		actions.append(spec.action)
	for a in ["move_left", "move_right", "jump", "attack_light", "parry", "dash", "echo_activate"]:
		assert_true(actions.has(a), "touch layout includes %s" % a)

func test_every_button_has_glyph_and_pos():
	for spec in TC.layout():
		assert_true(spec.has("action") and spec.has("glyph") and spec.has("pos"))
		assert_true(spec.pos is Vector2)
