class_name TouchControls
extends CanvasLayer
## On-screen touch controls. Each button is a TouchScreenButton whose `action`
## synthesizes one of the game's input actions, so InputSystem is unchanged.
## Mouse drives them on desktop via emulate_touch_from_mouse.

var force_visible := false

## On-screen control layout for a 1920x1080 viewport. Positions are the top-left
## corner of each BTN-sized (square) button; all stay fully on-screen and never
## overlap (asserted by test_touch_controls.gd). Left thumb = movement, right
## thumb = a 3x3-minus-2 action cluster. Exact ergonomics need on-device tuning.
static func layout() -> Array:
	return [
		# Left thumb: movement
		{"action": "move_left",     "glyph": "<",     "pos": Vector2(140, 830),  "color": Color(1,1,1,0.25)},
		{"action": "move_right",    "glyph": ">",     "pos": Vector2(300, 830),  "color": Color(1,1,1,0.25)},
		{"action": "crouch",        "glyph": "v",     "pos": Vector2(220, 960),  "color": Color(1,1,1,0.2)},
		# Right thumb: actions (top row)
		{"action": "attack_heavy",  "glyph": "HVY",   "pos": Vector2(1480, 700), "color": Color(1,0.4,0.3,0.3)},
		{"action": "parry",         "glyph": "DEF",   "pos": Vector2(1620, 700), "color": Color(0.6,0.8,1,0.35)},
		{"action": "echo_activate", "glyph": "ECHO",  "pos": Vector2(1760, 700), "color": Color(0.9,0.6,1,0.3)},
		# Right thumb: actions (bottom rows)
		{"action": "dash",          "glyph": "DSH",   "pos": Vector2(1480, 830), "color": Color(0.8,1,0.6,0.3)},
		{"action": "attack_light",  "glyph": "ATK",   "pos": Vector2(1620, 830), "color": Color(1,0.5,0.4,0.3)},
		{"action": "jump",          "glyph": "JMP",   "pos": Vector2(1760, 830), "color": Color(0.4,0.9,1,0.3)},
		{"action": "dodge",         "glyph": "DODGE", "pos": Vector2(1620, 960), "color": Color(0.7,0.9,1,0.3)},
	]

static func should_show() -> bool:
	return DisplayServer.is_touchscreen_available()

const BTN := 120

func _ready() -> void:
	layer = 150
	process_mode = Node.PROCESS_MODE_ALWAYS
	for spec in layout():
		_make_button(spec)
	_apply_visibility()

func _make_button(spec: Dictionary) -> void:
	var b := TouchScreenButton.new()
	b.action = spec.action
	b.position = spec.pos
	b.texture_normal = _btn_texture(spec.color)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(BTN, BTN)
	b.shape = shape
	var lbl := Label.new()
	lbl.text = spec.glyph
	lbl.size = Vector2(BTN, BTN)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(1,1,1,0.9))
	b.add_child(lbl)
	add_child(b)

func _btn_texture(c: Color) -> ImageTexture:
	var img := Image.create(BTN, BTN, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		force_visible = not force_visible
		_apply_visibility()

func _apply_visibility() -> void:
	visible = force_visible or should_show()
