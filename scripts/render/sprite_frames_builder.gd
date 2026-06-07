class_name SpriteFramesBuilder
extends RefCounted
## Builds Godot SpriteFrames from horizontal sprite-strip PNGs
## (each frame is frame_w x frame_h, laid left-to-right).


## Add one animation clip to `sf` by slicing `texture` into AtlasTextures.
static func add_strip(sf: SpriteFrames, clip: String, texture: Texture2D,
		frame_w: int, frame_h: int, fps: float, loop: bool = true) -> void:
	if texture == null:
		return
	var count := int(texture.get_width() / frame_w)
	if not sf.has_animation(clip):
		sf.add_animation(clip)
	sf.set_animation_speed(clip, fps)
	sf.set_animation_loop(clip, loop)
	for i in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		sf.add_frame(clip, atlas)
