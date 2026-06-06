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
