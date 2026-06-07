class_name SfxGenerator
extends RefCounted
## Procedural SFX: synthesize AudioStreamWAV (16-bit mono PCM) — no external files.

const RATE := 22050

## Build a stream from float samples in [-1, 1].
static func from_samples(samples: Array, rate: int = RATE) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v: float = clampf(samples[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(v * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.stereo = false
	s.mix_rate = rate
	s.data = bytes
	return s

static func make(name: String) -> AudioStreamWAV:
	match name:
		"slash":     return from_samples(_noise_sweep(0.12, 1.0, 0.2, 0.7))
		"hit":       return from_samples(_noise_burst(0.10, 0.9))
		"hit_light": return from_samples(_noise_burst(0.06, 0.5))
		"jump":      return from_samples(_blip(0.10, 320.0, 620.0, 0.5))
		"dash":      return from_samples(_noise_sweep(0.18, 0.6, 0.9, 0.3))
		"dodge":     return from_samples(_blip(0.12, 500.0, 300.0, 0.4))
		"parry":     return from_samples(_chime(0.30, 1200.0, 0.6))
		"block":     return from_samples(_mix(_noise_burst(0.08, 0.4), _blip(0.10, 180.0, 120.0, 0.4)))
		"echo":      return from_samples(_chime(0.40, 700.0, 0.45))
		"death":     return from_samples(_blip(0.45, 300.0, 80.0, 0.6))
		_:           return from_samples(_noise_burst(0.05, 0.4))

static func _mix(a: Array, b: Array) -> Array:
	var n: int = max(a.size(), b.size())
	var out := []; out.resize(n)
	for i in range(n):
		var av: float = a[i] if i < a.size() else 0.0
		var bv: float = b[i] if i < b.size() else 0.0
		out[i] = clampf(av + bv, -1.0, 1.0)
	return out

static func _env(i: int, n: int, attack: float) -> float:
	var t := float(i) / float(n)
	var a := minf(t / maxf(attack, 0.001), 1.0)
	var d := 1.0 - t
	return a * d

static func _noise_burst(dur: float, amp: float) -> Array:
	var n := int(dur * RATE); var out := []; out.resize(n)
	for i in range(n):
		out[i] = (randf() * 2.0 - 1.0) * amp * _env(i, n, 0.01)
	return out

static func _noise_sweep(dur: float, amp: float, lp_start: float, lp_end: float) -> Array:
	var n := int(dur * RATE); var out := []; out.resize(n); var prev := 0.0
	for i in range(n):
		var raw := (randf() * 2.0 - 1.0)
		var lp: float = lerpf(lp_start, lp_end, float(i) / float(n))
		prev = lerpf(prev, raw, lp)
		out[i] = prev * amp * _env(i, n, 0.02)
	return out

static func _blip(dur: float, f0: float, f1: float, amp: float) -> Array:
	var n := int(dur * RATE); var out := []; out.resize(n); var phase := 0.0
	for i in range(n):
		var f: float = lerpf(f0, f1, float(i) / float(n))
		phase += TAU * f / float(RATE)
		out[i] = sin(phase) * amp * _env(i, n, 0.01)
	return out

static func _chime(dur: float, f0: float, amp: float) -> Array:
	var n := int(dur * RATE); var out := []; out.resize(n)
	for i in range(n):
		var t := float(i) / float(RATE)
		var s := sin(TAU * f0 * t) * 0.6 + sin(TAU * f0 * 2.0 * t) * 0.3 + sin(TAU * f0 * 3.0 * t) * 0.1
		out[i] = s * amp * _env(i, n, 0.005)
	return out

## A short looping synth-koto bed (procedural, low amplitude).
static func music() -> AudioStreamWAV:
	var total := int(8.0 * RATE)
	var out := []
	out.resize(total)
	for i in range(total):
		out[i] = 0.0
	# Minor-pentatonic semitone offsets from a base; A3 = 220 Hz base.
	var base := 220.0
	var scale := [0, 3, 5, 7, 10, 12]
	var note_dur := 0.4
	var step := int(0.4 * RATE)  # ~2.5 notes/sec
	var idx := 0
	var pos := 0
	while pos < total:
		var semis: int = scale[idx % scale.size()]
		var freq := base * pow(2.0, semis / 12.0)
		var note := _chime(note_dur, freq, 0.22)
		for j in range(note.size()):
			var p := pos + j
			if p < total:
				out[p] += note[j]
		idx += 1
		pos += step
	# Soft clip
	for i in range(total):
		out[i] = clampf(out[i], -0.9, 0.9)
	var s := from_samples(out, RATE)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = total - 1
	return s
