class_name WinLabel
extends Label

func _ready() -> void:
	text = "VICTORY"
	add_theme_font_size_override("font_size", 96)
	add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	set_anchors_preset(Control.PRESET_CENTER)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
