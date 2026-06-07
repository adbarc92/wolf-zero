extends GutTest
const Sfx = preload("res://scripts/audio/sfx_generator.gd")

func test_make_stream_has_pcm_data():
	var s = Sfx.from_samples([0.0, 0.5, -0.5, 0.0], 22050)
	assert_true(s is AudioStreamWAV, "returns an AudioStreamWAV")
	assert_eq(s.format, AudioStreamWAV.FORMAT_16_BITS)
	assert_eq(s.mix_rate, 22050)
	assert_eq(s.data.size(), 8, "4 samples * 2 bytes (16-bit mono)")

func test_named_sfx_are_nonempty():
	for n in ["slash", "hit", "jump", "dash", "dodge", "parry", "echo", "death"]:
		var s = Sfx.make(n)
		assert_true(s is AudioStreamWAV, "%s is a stream" % n)
		assert_gt(s.data.size(), 0, "%s has audio data" % n)

func test_music_is_a_looping_stream():
	var m = Sfx.music()
	assert_true(m is AudioStreamWAV, "music is an AudioStreamWAV")
	assert_eq(m.loop_mode, AudioStreamWAV.LOOP_FORWARD, "music loops")
	# at least ~4 seconds of 16-bit mono samples
	assert_gt(m.data.size(), 22050 * 4 * 2, "music is at least ~4s long")
