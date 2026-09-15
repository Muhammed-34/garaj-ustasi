extends SceneTree

# Synthesizes every sound effect from code, so the game ships no third-party audio.
#   godot --headless --path . -s tools/audio/make_sfx.gd
const RATE := 22050
const OUT := "res://game/audio/sfx/"
const C5 := 523.25
const E5 := 659.25
const G5 := 783.99
const C6 := 1046.5

var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 7
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_save("pop", _pop(), 0.6)
	_save("swap", _swap(), 0.45)
	_save("invalid", _invalid(), 0.5)
	_save("special", _special(), 0.7)
	_save("blast", _blast(), 0.85)
	_save("color", _color(), 0.7)
	_save("box", _box(), 0.7)
	_save("paw", _paw(), 0.55)
	_save("sack", _sack(), 0.7)
	_save("coin", _coin(), 0.6)
	_save("star", _star(), 0.6)
	_save("win", _win(), 0.8)
	_save("lose", _lose(), 0.6)
	_save("meow", _meow(), 0.75)
	_save("click", _click(), 0.35)
	quit()


func _pop() -> PackedFloat32Array:
	var buf := _buffer(0.14)
	_tone(buf, 0.0, 0.12, 760.0, 380.0, 1.0, 30.0)
	_noise(buf, 0.0, 0.015, 0.35, 200.0, 0.6)
	return buf


func _swap() -> PackedFloat32Array:
	var buf := _buffer(0.08)
	_tone(buf, 0.0, 0.07, 520.0, 640.0, 1.0, 50.0, "triangle")
	return buf


func _invalid() -> PackedFloat32Array:
	var buf := _buffer(0.22)
	_tone(buf, 0.0, 0.09, 210.0, 180.0, 1.0, 25.0, "triangle")
	_tone(buf, 0.1, 0.1, 190.0, 160.0, 1.0, 25.0, "triangle")
	return buf


func _special() -> PackedFloat32Array:
	var buf := _buffer(0.34)
	_tone(buf, 0.0, 0.3, 500.0, 1500.0, 1.0, 5.0)
	_tone(buf, 0.03, 0.28, 1000.0, 3000.0, 0.25, 7.0, "triangle")
	return buf


func _blast() -> PackedFloat32Array:
	var buf := _buffer(0.45)
	_tone(buf, 0.0, 0.42, 140.0, 45.0, 1.0, 9.0)
	_noise(buf, 0.0, 0.4, 0.7, 10.0, 0.15)
	return buf


func _color() -> PackedFloat32Array:
	var buf := _buffer(0.5)
	var notes := [C6, C6 * 1.26, C6 * 1.5, C6 * 2.0]
	for n in notes.size():
		_tone(buf, n * 0.06, 0.3, notes[n], notes[n], 0.7, 10.0)
		_tone(buf, n * 0.06, 0.3, notes[n] * 2.0, notes[n] * 2.0, 0.15, 14.0, "triangle")
	return buf


func _box() -> PackedFloat32Array:
	var buf := _buffer(0.2)
	_noise(buf, 0.0, 0.12, 1.0, 25.0, 0.5)
	_noise(buf, 0.05, 0.1, 0.6, 30.0, 0.7)
	_tone(buf, 0.0, 0.12, 180.0, 120.0, 0.35, 30.0, "square")
	return buf


func _paw() -> PackedFloat32Array:
	var buf := _buffer(0.12)
	_noise(buf, 0.0, 0.08, 0.6, 40.0, 0.08)
	_tone(buf, 0.0, 0.1, 260.0, 180.0, 1.0, 30.0)
	return buf


func _sack() -> PackedFloat32Array:
	var buf := _buffer(0.45)
	_tone(buf, 0.0, 0.18, 200.0, 110.0, 1.0, 20.0)
	_tone(buf, 0.06, 0.35, 1318.5, 1318.5, 0.45, 10.0)
	_tone(buf, 0.12, 0.3, 1760.0, 1760.0, 0.35, 10.0)
	return buf


func _coin() -> PackedFloat32Array:
	var buf := _buffer(0.35)
	_tone(buf, 0.0, 0.08, 988.0, 988.0, 0.8, 20.0, "triangle")
	_tone(buf, 0.07, 0.28, 1318.5, 1318.5, 0.9, 9.0, "triangle")
	return buf


func _star() -> PackedFloat32Array:
	var buf := _buffer(0.5)
	_tone(buf, 0.0, 0.45, 1568.0, 1568.0, 1.0, 7.0)
	_tone(buf, 0.0, 0.45, 2349.3, 2349.3, 0.4, 9.0)
	_tone(buf, 0.03, 0.2, 3136.0, 3136.0, 0.15, 20.0, "triangle")
	return buf


func _win() -> PackedFloat32Array:
	var buf := _buffer(1.3)
	var notes := [C5, E5, G5]
	for n in notes.size():
		_tone(buf, n * 0.12, 0.2, notes[n], notes[n], 0.9, 8.0, "triangle")
		_tone(buf, n * 0.12, 0.2, notes[n] * 2.0, notes[n] * 2.0, 0.25, 10.0)
	for note in [C6, E5 * 2.0, G5 * 2.0]:
		_tone(buf, 0.38, 0.9, note, note, 0.55, 3.5, "triangle")
	_tone(buf, 0.38, 0.9, C6 * 2.0, C6 * 2.0, 0.15, 5.0)
	return buf


func _lose() -> PackedFloat32Array:
	var buf := _buffer(0.95)
	var notes := [392.0, 329.63, 261.63]
	for n in notes.size():
		_tone(buf, n * 0.22, 0.3 if n < 2 else 0.6, notes[n], notes[n] * (1.0 if n < 2 else 0.94), 0.8, 5.0, "triangle")
	return buf


# A sawtooth voice with a rising-then-falling pitch, shaped by moving vowel formants ("mi-a-u").
func _meow() -> PackedFloat32Array:
	var length := 0.55
	var count := int(length * RATE)
	var buf := _buffer(length + 0.05)
	var f1 := _Resonator.new()
	var f2 := _Resonator.new()
	var phase := 0.0
	for n in count:
		var k := float(n) / count
		var pitch := 540.0 + 280.0 * sin(k * PI) - 160.0 * k
		phase += pitch / RATE
		var saw := 2.0 * fmod(phase, 1.0) - 1.0
		var env := minf(k * 14.0, 1.0) * minf((1.0 - k) * 5.0, 1.0)
		var first := lerpf(320.0, 850.0, k / 0.35) if k < 0.35 else lerpf(850.0, 380.0, (k - 0.35) / 0.65)
		var second := lerpf(2300.0, 1250.0, k / 0.35) if k < 0.35 else lerpf(1250.0, 820.0, (k - 0.35) / 0.65)
		buf[n] = (f1.process(saw, first, 6.0) + 0.6 * f2.process(saw, second, 8.0)) * env
	return buf


func _click() -> PackedFloat32Array:
	var buf := _buffer(0.04)
	_tone(buf, 0.0, 0.035, 1200.0, 900.0, 1.0, 90.0)
	return buf


func _buffer(seconds: float) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	buf.resize(int(seconds * RATE))
	return buf


# Adds a tone gliding exponentially from f0 to f1 with a short attack and exponential decay.
func _tone(buf: PackedFloat32Array, start: float, length: float, f0: float, f1: float, amp: float, decay: float, wave: String = "sine") -> void:
	var first := int(start * RATE)
	var count := int(length * RATE)
	var phase := 0.0
	for n in count:
		var i := first + n
		if i >= buf.size():
			break
		var t := float(n) / RATE
		phase += f0 * pow(f1 / f0, float(n) / count) / RATE
		var p := fmod(phase, 1.0)
		var v := sin(p * TAU)
		if wave == "triangle":
			v = 4.0 * absf(p - 0.5) - 1.0
		elif wave == "square":
			v = 1.0 if p < 0.5 else -1.0
		buf[i] += v * amp * minf(t / 0.004, 1.0) * exp(-t * decay)


# Adds low-passed white noise; smaller smooth values give a duller sound.
func _noise(buf: PackedFloat32Array, start: float, length: float, amp: float, decay: float, smooth: float) -> void:
	var first := int(start * RATE)
	var y := 0.0
	for n in int(length * RATE):
		var i := first + n
		if i >= buf.size():
			break
		y += smooth * (_rng.randf_range(-1.0, 1.0) - y)
		buf[i] += y * amp * exp(-float(n) / RATE * decay)


func _save(sound: String, samples: PackedFloat32Array, level: float) -> void:
	var peak := 0.0
	for s in samples:
		peak = maxf(peak, absf(s))
	var gain := level / peak if peak > 0.0 else 1.0
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for n in samples.size():
		bytes.encode_s16(n * 2, int(clampf(samples[n] * gain, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	var path := OUT + sound + ".wav"
	print("%s -> %s" % [path, error_string(wav.save_to_wav(ProjectSettings.globalize_path(path)))])


# Band-pass biquad whose centre frequency can change every sample.
class _Resonator:
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0

	func process(x: float, freq: float, q: float) -> float:
		var w0 := TAU * freq / RATE
		var alpha := sin(w0) / (2.0 * q)
		var a0 := 1.0 + alpha
		var y := (alpha * x - alpha * x2 + 2.0 * cos(w0) * y1 - (1.0 - alpha) * y2) / a0
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		return y
