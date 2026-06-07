extends GutTest
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

func test_builds_and_plays_without_crashing():
	var am = AudioManagerScript.new()
	add_child_autofree(am)
	await get_tree().process_frame   # _ready builds streams + players
	assert_gt(am.sound_count(), 0, "sounds were built")
	am.play("slash")                 # known
	am.play("nonexistent")           # unknown -> no crash
	assert_true(true)
