class_name AudioManager
extends Node

const POOL := 8
var _sounds: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
@export var sfx_db := -6.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in ["slash", "hit", "hit_light", "jump", "dash", "dodge", "parry", "echo", "death"]:
		_sounds[n] = SfxGenerator.make(n)
	for i in range(POOL):
		var p := AudioStreamPlayer.new()
		p.volume_db = sfx_db
		add_child(p)
		_players.append(p)

func sound_count() -> int:
	return _sounds.size()

func play(name: String) -> void:
	if not _sounds.has(name) or _players.is_empty():
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sounds[name]
	p.play()
