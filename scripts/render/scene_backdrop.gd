class_name SceneBackdrop
extends ParallaxBackground
## Self-contained cyberpunk parallax backdrop (ansimuz "Warped City", CC0).
##
## Replaces the old MoonlitGraveyard parallax. main.gd only needs to
## `add_child(SceneBackdrop.new())` — this node builds all of its own
## ParallaxLayers from `assets/environment/**` in `_ready()`.
##
## Layer textures are loaded BY PATH so the real CC0 art drops in over the
## placeholder PNGs (same filenames) with no code change. See
## `assets/environment/MANIFEST.md`.

## Directory holding the parallax layer art.
const ENV_DIR := "res://assets/environment/"

## Layer specs, declared far → near. Mirrors the layer pattern in main.gd's
## old `_setup_parallax()`/`_add_layer()` (motion_scale, motion_mirroring,
## per-layer sprite scale). Smaller `scroll` = further away (scrolls slower).
const LAYERS := [
	{ "file": "warped-city-sky.png",       "scroll": 0.1, "scale": Vector2(2, 2) },
	{ "file": "warped-city-far.png",       "scroll": 0.3, "scale": Vector2(2, 2) },
	{ "file": "warped-city-buildings.png", "scroll": 0.6, "scale": Vector2(2, 2) },
]


func _ready() -> void:
	name = "Parallax"
	build_layers()


## Build every ParallaxLayer from LAYERS. Idempotent: clears any prior layers
## first so it is safe to call again. Returns the number of layers added.
func build_layers() -> int:
	for child in get_children():
		child.queue_free()
	var added := 0
	for spec in LAYERS:
		if _add_layer(ENV_DIR + spec.file, spec.scroll, spec.scale):
			added += 1
	return added


## Number of layers this backdrop is configured to build (independent of the
## scene tree — usable from unit tests without instancing into a viewport).
static func expected_layer_count() -> int:
	return LAYERS.size()


func _add_layer(path: String, scroll_scale: float, scale_v: Vector2) -> bool:
	var tex: Texture2D = load(path)
	if tex == null:
		push_warning("SceneBackdrop layer missing: " + path)
		return false
	var layer := ParallaxLayer.new()
	layer.motion_scale = Vector2(scroll_scale, scroll_scale)
	layer.motion_mirroring = Vector2(tex.get_width() * scale_v.x, 0)
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.centered = false
	spr.scale = scale_v
	spr.position = Vector2.ZERO
	layer.add_child(spr)
	add_child(layer)
	return true
