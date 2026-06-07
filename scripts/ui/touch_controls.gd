class_name TouchControls
extends CanvasLayer
## On-screen touch controls. Each button is a TouchScreenButton whose `action`
## synthesizes one of the game's input actions, so InputSystem is unchanged.
## Mouse drives them on desktop via emulate_touch_from_mouse.

var force_visible := false

static func layout() -> Array:
	return [
		{"action": "move_left",     "glyph": "<",    "pos": Vector2(150, 920),  "color": Color(1,1,1,0.25)},
		{"action": "move_right",    "glyph": ">",    "pos": Vector2(310, 920),  "color": Color(1,1,1,0.25)},
		{"action": "crouch",        "glyph": "v",    "pos": Vector2(230, 1010), "color": Color(1,1,1,0.2)},
		{"action": "jump",          "glyph": "JMP",  "pos": Vector2(1790, 940), "color": Color(0.4,0.9,1,0.3)},
		{"action": "attack_light",  "glyph": "ATK",  "pos": Vector2(1650, 980), "color": Color(1,0.5,0.4,0.3)},
		{"action": "parry",         "glyph": "DEF",  "pos": Vector2(1700, 840), "color": Color(0.6,0.8,1,0.35)},
		{"action": "dash",          "glyph": "DSH",  "pos": Vector2(1540, 940), "color": Color(0.8,1,0.6,0.3)},
		{"action": "echo_activate", "glyph": "ECHO", "pos": Vector2(1850, 820), "color": Color(0.9,0.6,1,0.3)},
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
