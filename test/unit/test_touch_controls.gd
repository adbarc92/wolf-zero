extends GutTest
const TC = preload("res://scripts/ui/touch_controls.gd")

const VIEWPORT = Vector2(1920, 1080)

func test_layout_covers_all_core_actions():
	var actions := []
	for spec in TC.layout():
		actions.append(spec.action)
	# Buttons are the canonical touch scheme, so every core verb must be reachable.
	for a in ["move_left", "move_right", "crouch", "jump", "attack_light",
			"attack_heavy", "parry", "dodge", "dash", "echo_activate"]:
		assert_true(actions.has(a), "touch layout includes %s" % a)

func test_every_button_has_glyph_and_pos():
	for spec in TC.layout():
		assert_true(spec.has("action") and spec.has("glyph") and spec.has("pos"))
		assert_true(spec.pos is Vector2)

func test_no_two_buttons_overlap():
	var specs := TC.layout()
	var size := float(TC.BTN)
	for i in range(specs.size()):
		for j in range(i + 1, specs.size()):
			var a: Vector2 = specs[i].pos
			var b: Vector2 = specs[j].pos
			var overlaps: bool = (abs(a.x - b.x) < size) and (abs(a.y - b.y) < size)
			assert_false(overlaps,
				"%s and %s overlap" % [specs[i].action, specs[j].action])

func test_all_buttons_fully_on_screen():
	var size := float(TC.BTN)
	for spec in TC.layout():
		var p: Vector2 = spec.pos
		assert_true(p.x >= 0 and p.y >= 0, "%s off top/left" % spec.action)
		assert_true(p.x + size <= VIEWPORT.x, "%s off right edge" % spec.action)
		assert_true(p.y + size <= VIEWPORT.y, "%s off bottom edge" % spec.action)
