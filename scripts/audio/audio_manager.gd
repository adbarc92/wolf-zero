class_name AudioManager
extends Node
## Asset-driven SFX manager.
##
## For each event key it tries to load a real CC0 audio file from
## `res://assets/audio/sfx/<key>.<ext>` (OGG preferred for mobile, then WAV).
## If no file is present it falls back to the procedural `SfxGenerator`,
## so audio always works even before real assets are dropped in.
##
## The public API — play(key), sound_count(), set_music_enabled(on) — is
## unchanged so main.gd needs no edit.

const POOL := 8
const SFX_DIR := "res://assets/audio/sfx"
## File extensions to probe, in priority order (OGG first for mobile).
const EXTENSIONS := ["ogg", "wav"]

## Event keys wired up by main.gd's _on_sfx_* handlers (+ dash, kept for parity).
const EVENT_KEYS := [
	"slash", "hit", "hit_light", "jump", "dash", "dodge",
	"parry", "block", "echo", "death",
]

var _sounds: Dictionary = {}
## key -> true if the stream came from a real file, false if procedural fallback.
var _from_file: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
@export var sfx_db := -6.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key in EVENT_KEYS:
		_load_sound(key)
	for i in range(POOL):
		var p := AudioStreamPlayer.new()
		p.volume_db = sfx_db
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.stream = SfxGenerator.music()
	_music.volume_db = -16.0
	add_child(_music)
	_music.play()

## Resolve one event key to a stream: real file if present, else procedural.
func _load_sound(key: String) -> void:
	var stream := _try_load_file(key)
	if stream != null:
		_sounds[key] = stream
		_from_file[key] = true
	else:
		_sounds[key] = SfxGenerator.make(key)
		_from_file[key] = false

## Returns a loaded AudioStream for `key` from disk, or null if no file exists.
func _try_load_file(key: String) -> AudioStream:
	for ext in EXTENSIONS:
		var path := "%s/%s.%s" % [SFX_DIR, key, ext]
		if ResourceLoader.exists(path):
			var res := ResourceLoader.load(path)
			if res is AudioStream:
				return res
	return null

func set_music_enabled(on: bool) -> void:
	if not _music: return
	if on and not _music.playing: _music.play()
	elif not on and _music.playing: _music.stop()

func sound_count() -> int:
	return _sounds.size()

## True if `key` resolved to a real audio file (false = procedural fallback).
func is_from_file(key: String) -> bool:
	return _from_file.get(key, false)

func play(name: String) -> void:
	if not _sounds.has(name) or _players.is_empty():
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sounds[name]
	p.play()
