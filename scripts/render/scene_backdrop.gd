class_name SceneBackdrop
extends ParallaxBackground
## Self-contained cyberpunk parallax backdrop (Anokolisa "Sidescroller Shooter —
## Central City", free for commercial use w/ credit; see assets/environment/MANIFEST.md).
##
## Replaces the old MoonlitGraveyard parallax. main.gd only needs to
## `add_child(SceneBackdrop.new())` — this node builds all of its own
## ParallaxLayers from `assets/environment/**` in `_ready()`.
##
## Layer textures are loaded BY PATH so swapping art is a data-only edit to
## LAYERS. The Central City pack's BACKGROUND set is a purple-neon gradient sky
## plus two horizontally-tiling fog bands; the pack's buildings/props/tiles are
## a foreground tileset (level geometry), not parallax, and are not used here.

## Directory holding the parallax layer art.
const ENV_DIR := "res://assets/environment/"

## Layer specs, declared far → near. `scroll` = motion_scale (smaller = further
## away / scrolls slower). `scale` = per-sprite zoom. `offset` = where the layer
## sits (the fog bands sit low on screen; the sky covers the full 1920x1080).
## Each layer tiles horizontally via motion_mirroring. NOTE: the scale/offset
## values are a sensible first pass — fine-tune against a running viewport.
const LAYERS := [
	{ "file": "central-city-sky.png",        "scroll": 0.1,  "scale": Vector2(4, 4), "offset": Vector2(0, 0) },
	{ "file": "central-city-fog-mid.png",    "scroll": 0.4,  "scale": Vector2(3, 3), "offset": Vector2(0, 620) },
	{ "file": "central-city-fog-front.png",  "scroll": 0.75, "scale": Vector2(4, 4), "offset": Vector2(0, 540) },
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
		if _add_layer(ENV_DIR + spec.file, spec.scroll, spec.scale, spec.get("offset", Vector2.ZERO)):
			added += 1
	return added


## Number of layers this backdrop is configured to build (independent of the
## scene tree — usable from unit tests without instancing into a viewport).
static func expected_layer_count() -> int:
	return LAYERS.size()


func _add_layer(path: String, scroll_scale: float, scale_v: Vector2, offset: Vector2) -> bool:
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
	spr.position = offset
	# Pixel-art: keep the gradients/fog crisp instead of the project-default Linear.
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	layer.add_child(spr)
	add_child(layer)
	return true
