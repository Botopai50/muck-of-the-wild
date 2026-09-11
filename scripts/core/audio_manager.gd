class_name AudioManager
extends Node

## Gerenciador Central de Efeitos Sonoros e Síntese de Áudio
## Permite tocar efeitos procedurais em 2D/UI e no espaço 3D

static var _cached_streams: Dictionary = {}

static func play_sound(arg1, arg2 = null, arg3 = null, arg4 = null) -> void:
	var target: Node = null
	var sound_name: String = ""
	var pitch_scale: float = 1.0
	var volume_db: float = 0.0

	if arg1 is String:
		sound_name = arg1
		if arg2 is float or arg2 is int:
			pitch_scale = float(arg2)
		if arg3 is float or arg3 is int:
			volume_db = float(arg3)
		var tree := Engine.get_main_loop() as SceneTree
		if tree and tree.current_scene:
			target = tree.current_scene
		elif tree and tree.root:
			target = tree.root
	elif arg1 is Node:
		target = arg1
		if arg2 is String:
			sound_name = arg2
		if arg3 is float or arg3 is int:
			pitch_scale = float(arg3)
		if arg4 is float or arg4 is int:
			volume_db = float(arg4)

	if not target or not target.is_inside_tree() or sound_name.is_empty():
		return
	var stream = get_sound(sound_name)
	if not stream:
		return

	var p = AudioStreamPlayer.new()
	p.stream = stream
	p.pitch_scale = pitch_scale
	p.volume_db = volume_db
	target.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

static func play_sound_3d(sound_name: String, global_pos: Vector3, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree or not tree.root:
		return
	var stream = get_sound(sound_name)
	if not stream:
		return
	var p3d = AudioStreamPlayer3D.new()
	p3d.stream = stream
	p3d.pitch_scale = pitch_scale
	p3d.volume_db = volume_db
	p3d.max_distance = 40.0
	tree.root.add_child(p3d)
	p3d.global_position = global_pos
	p3d.finished.connect(p3d.queue_free)
	p3d.play()

static func get_sound_stream(sound_name: String) -> AudioStreamWAV:
	return get_sound(sound_name)

static func get_sound(sound_name: String) -> AudioStreamWAV:
	if _cached_streams.has(sound_name):
		return _cached_streams[sound_name]
	
	var stream: AudioStreamWAV = null
	match sound_name:
		"craft", "craft_success":
			stream = _synth_craft_sound()
		"chop", "wood_chop":
			stream = _synth_chop_sound()
		"mine", "rock_mine":
			stream = _synth_mine_sound()
		"pickup", "item_pickup":
			stream = _synth_pickup_sound()
		"eat", "eat_food":
			stream = _synth_eat_sound()
		"tree_fall":
			stream = _synth_tree_fall_sound()
		"rock_break", "break":
			stream = _synth_rock_break_sound()
		"relic", "relic_pickup":
			stream = _synth_relic_sound()
		_:
			stream = _synth_pickup_sound()
	
	if stream:
		_cached_streams[sound_name] = stream
	return stream

static func _synth_craft_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.45
	var sample_count = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	var notes = [523.25, 659.25, 783.99, 1046.50]
	var note_duration = duration / float(notes.size())
	
	for i in range(sample_count):
		var t = float(i) / float(sample_rate)
		var note_idx = clampi(int(t / note_duration), 0, notes.size() - 1)
		var freq = notes[note_idx]
		var note_t = fmod(t, note_duration)
		var env = exp(-note_t * 9.0)
		var val = (sin(note_t * freq * TAU) + 0.35 * sin(note_t * freq * 2.0 * TAU)) * env * (1.0 - t / duration)
		var ival = clampi(int(val * 24000.0), -32768, 32767)
		var uval = ival if ival >= 0 else 65536 + ival
		data[i * 2] = uval & 0xFF
		data[i * 2 + 1] = (uval >> 8) & 0xFF
	
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = data
	return s

static func _synth_chop_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.18
	var sample_count = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t = float(i) / float(sample_rate)
		var env = exp(-t * 26.0)
		var thud = sin(t * (130.0 - t * 250.0) * TAU)
		var noise = (randf() * 2.0 - 1.0) * exp(-t * 40.0)
		var val = (thud * 0.7 + noise * 0.5) * env
		var ival = clampi(int(val * 26000.0), -32768, 32767)
		var uval = ival if ival >= 0 else 65536 + ival
		data[i * 2] = uval & 0xFF
		data[i * 2 + 1] = (uval >> 8) & 0xFF
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = data
	return s

static func _synth_mine_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.2
	var sample_count = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t = float(i) / float(sample_rate)
		var env = exp(-t * 22.0)
		var ring = (sin(t * 880.0 * TAU) + 0.4 * sin(t * 1760.0 * TAU)) * exp(-t * 16.0)
		var crack = (randf() * 2.0 - 1.0) * exp(-t * 38.0)
		var val = (ring * 0.6 + crack * 0.5) * env
		var ival = clampi(int(val * 26000.0), -32768, 32767)
		var uval = ival if ival >= 0 else 65536 + ival
		data[i * 2] = uval & 0xFF
		data[i * 2 + 1] = (uval >> 8) & 0xFF
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = data
	return s

static func _synth_pickup_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.16
	var sample_count = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t = float(i) / float(sample_rate)
		var env = exp(-t * 18.0)
		var freq = 987.77 if t < 0.07 else 1318.51
		var val = sin(t * freq * TAU) * env
		var ival = clampi(int(val * 24000.0), -32768, 32767)
		var uval = ival if ival >= 0 else 65536 + ival
		data[i * 2] = uval & 0xFF
		data[i * 2 + 1] = (uval >> 8) & 0xFF
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = data
	return s

static func _synth_eat_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.25
	var sample_count = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t = float(i) / float(sample_rate)
		var env = sin((t / duration) * PI) * exp(-t * 8.0)
		var noise = (randf() * 2.0 - 1.0)
		var bite = sin(t * 320.0 * TAU) * 0.4
		var val = (noise * 0.6 + bite) * env
		var ival = clampi(int(val * 23000.0), -32768, 32767)
		var uval = ival if ival >= 0 else 65536 + ival
		data[i * 2] = uval & 0xFF
		data[i * 2 + 1] = (uval >> 8) & 0xFF
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = data
	return s

static func _synth_tree_fall_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.6
	var sample_count = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t = float(i) / float(sample_rate)
		var env = exp(-t * 4.0)
		var creak = sin(t * (70.0 - t * 30.0) * TAU)
		var noise = (randf() * 2.0 - 1.0) * (0.3 + 0.5 * (1.0 - t / duration))
		var val = (creak * 0.5 + noise * 0.5) * env
		var ival = clampi(int(val * 28000.0), -32768, 32767)
		var uval = ival if ival >= 0 else 65536 + ival
		data[i * 2] = uval & 0xFF
		data[i * 2 + 1] = (uval >> 8) & 0xFF
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = data
	return s

static func _synth_rock_break_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.35
	var sample_count = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t = float(i) / float(sample_rate)
		var env = exp(-t * 9.0)
		var noise = (randf() * 2.0 - 1.0) * exp(-t * 11.0)
		var low = sin(t * 65.0 * TAU) * exp(-t * 7.0)
		var val = (noise * 0.6 + low * 0.6) * env
		var ival = clampi(int(val * 27000.0), -32768, 32767)
		var uval = ival if ival >= 0 else 65536 + ival
		data[i * 2] = uval & 0xFF
		data[i * 2 + 1] = (uval >> 8) & 0xFF
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = data
	return s

static func _synth_relic_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.7
	var sample_count = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t = float(i) / float(sample_rate)
		var env = exp(-t * 3.5)
		var shimmer = sin(t * 1174.66 * TAU) * 0.5 + sin(t * 1760.0 * TAU) * 0.3
		var val = shimmer * env
		var ival = clampi(int(val * 24000.0), -32768, 32767)
		var uval = ival if ival >= 0 else 65536 + ival
		data[i * 2] = uval & 0xFF
		data[i * 2 + 1] = (uval >> 8) & 0xFF
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = data
	return s
