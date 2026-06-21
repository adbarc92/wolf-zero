class_name Levels
extends RefCounted
## Registry of playable levels in progression order. Decouples the rest of the
## game from concrete level classes — add a level by writing a Level subclass and
## registering it in `_make` + `_ORDER`.

const _ORDER: Array[String] = ["level_one"]


## Build a fresh Level instance for the given id (falls back to the first level).
static func create(id: String) -> Level:
	match id:
		"level_one":
			return LevelOne.new()
		_:
			push_warning("Levels: unknown level id '%s', using first level" % id)
			return LevelOne.new()


## Ordered list of level ids.
static func order() -> Array:
	return _ORDER.duplicate()


## The first level's id.
static func first() -> String:
	return _ORDER[0]


## The id of the level after `id`, or "" if `id` is last/unknown.
static func next_after(id: String) -> String:
	var i := _ORDER.find(id)
	if i < 0 or i + 1 >= _ORDER.size():
		return ""
	return _ORDER[i + 1]
