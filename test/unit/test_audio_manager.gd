extends GutTest
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

func _make_am():
	var am = AudioManagerScript.new()
	add_child_autofree(am)
	await get_tree().process_frame   # _ready builds streams + players
	return am

func test_builds_and_plays_without_crashing():
	var am = await _make_am()
	assert_gt(am.sound_count(), 0, "sounds were built")
	am.play("slash")                 # known
	am.play("nonexistent")           # unknown -> no crash
	assert_true(true)

func test_every_event_key_resolves_to_a_stream():
	# Each key main.gd plays must map to a usable AudioStream (file or fallback).
	var am = await _make_am()
	for key in ["slash", "hit", "hit_light", "jump", "dash", "dodge",
			"parry", "block", "echo", "death"]:
		assert_true(am._sounds.has(key), "key '%s' has a stream" % key)
		assert_true(am._sounds[key] is AudioStream, "key '%s' is an AudioStream" % key)

func test_lookup_resolves_real_file_when_present():
	# If a real file exists for a key, it must be preferred over procedural.
	var am = await _make_am()
	var path_ogg := "res://assets/audio/sfx/slash.ogg"
	var path_wav := "res://assets/audio/sfx/slash.wav"
	var file_present := ResourceLoader.exists(path_ogg) or ResourceLoader.exists(path_wav)
	# is_from_file must agree with whether the file is actually on disk.
	assert_eq(am.is_from_file("slash"), file_present,
		"is_from_file matches presence of a real file on disk")

func test_falls_back_to_procedural_when_file_missing():
	# A key with guaranteed no asset file must still produce a stream via fallback.
	var am = await _make_am()
	# 'death' has no shipped asset today -> procedural fallback expected.
	var path_ogg := "res://assets/audio/sfx/death.ogg"
	var path_wav := "res://assets/audio/sfx/death.wav"
	if not (ResourceLoader.exists(path_ogg) or ResourceLoader.exists(path_wav)):
		assert_false(am.is_from_file("death"), "death uses procedural fallback")
		assert_true(am._sounds["death"] is AudioStream, "fallback stream is valid")
	else:
		pass_test("death asset present; fallback path not exercised")

func test_play_after_fallback_does_not_crash():
	var am = await _make_am()
	for key in ["slash", "hit", "parry", "block", "death", "jump",
			"dodge", "echo", "hit_light"]:
		am.play(key)
	assert_true(true, "all event keys play without crashing")
