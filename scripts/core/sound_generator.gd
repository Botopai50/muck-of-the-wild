class_name SoundGenerator
extends RefCounted

## Gerador Procedural de Efeitos Sonoros para Muck of the Wild
## Sintetiza ondas de áudio limpas em tempo de execução sem dependências de arquivos externos.

static var _cached_streams: Dictionary = {}

static func play_sound_2d_or_ui(target: Node, stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not target or not target.is_inside_tree() or not stream:
		return
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db
	player.bus = "Master"
	target.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

static func play_sound_3d(target: Node3D, stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if not target or not target.is_inside_tree() or not stream:
		return
	var player = AudioStreamPlayer3D.new()
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db
	player.max_distance = 35.0
	player.unit_size = 8.0
	target.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

static func get_craft_sound() -> AudioStreamWAV:
	if _cached_streams.has("craft"):
		return _cached_streams["craft"]
	
	# Arpeggio ascendente estilo Zelda (Do5, Mi5, Sol5, Do6)
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
		var val = (sin(note_t * freq * TAU) + 0.35 * sin(note_t * freq * 2.0 * TAU)) * env
		val *= (1.0 - t / duration)
		
		var ival = clampi(int(val * 24000.0), -32768, 32767)
		var uval = ival if ival >= 0 else 65536 + ival
		data[i * 2] = uval & 0xFF
		data[i * 2 + 1] = (uval >> 8) & 0xFF
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	_cached_streams["craft"] = stream
	return stream

static func get_chop_sound() -> AudioStreamWAV:
	if _cached_streams.has("chop"):
		return _cached_streams["chop"]
	
	var sample_rate = 22050
	var duration = 0.2
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
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	_cached_streams["chop"] = stream
	return stream

static func get_mine_sound() -> AudioStreamWAV:
	if _cached_streams.has("mine"):
		return _cached_streams["mine"]
	
	var sample_rate = 22050
	var duration = 0.22
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
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	_cached_streams["mine"] = stream
	return stream

static func get_pickup_sound() -> AudioStreamWAV:
	if _cached_streams.has("pickup"):
		return _cached_streams["pickup"]
	
	var sample_rate = 22050
	var duration = 0.18
	var sample_count = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	for i in range(sample_count):
		var t = float(i) / float(sample_rate)
		var env = exp(-t * 16.0)
		var freq = 987.77 if t < 0.08 else 1318.51 # Si5 depois Mi6
		var val = sin(t * freq * TAU) * env
		
		var ival = clampi(int(val * 24000.0), -32768, 32767)
		var uval = ival if ival >= 0 else 65536 + ival
		data[i * 2] = uval & 0xFF
		data[i * 2 + 1] = (uval >> 8) & 0xFF
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	_cached_streams["pickup"] = stream
	return stream

static func get_eat_sound() -> AudioStreamWAV:
	if _cached_streams.has("eat"):
		return _cached_streams["eat"]
	
	var sample_rate = 22050
	var duration = 0.28
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
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	_cached_streams["eat"] = stream
	return stream

static func get_break_sound() -> AudioStreamWAV:
	if _cached_streams.has("break"):
		return _cached_streams["break"]
	
	var sample_rate = 22050
	var duration = 0.4
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
	
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	_cached_streams["break"] = stream
	return stream
