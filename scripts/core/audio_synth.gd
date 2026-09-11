class_name AudioSynth
extends Node

## Gerador de audio procedural para SFX estilizados (Zelda BotW / Muck)
## Nao requer arquivos de audio externos; sintetiza formas de onda PCM na hora!

static func play_sound(parent: Node, sound_type: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer3D:
	if not parent or not parent.is_inside_tree():
		return null
	var player := AudioStreamPlayer3D.new()
	player.bus = &"Master"
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.max_distance = 40.0
	parent.add_child(player)
	
	var stream: AudioStreamWAV = create_sound(sound_type)
	if stream:
		player.stream = stream
		player.play()
		player.finished.connect(player.queue_free)
	else:
		player.queue_free()
	return player

static func play_sound_2d(parent: Node, sound_type: String, volume_db: float = 0.0) -> AudioStreamPlayer:
	if not parent or not parent.is_inside_tree():
		return null
	var player := AudioStreamPlayer.new()
	player.bus = &"Master"
	player.volume_db = volume_db
	parent.add_child(player)
	
	var stream: AudioStreamWAV = create_sound(sound_type)
	if stream:
		player.stream = stream
		player.play()
		player.finished.connect(player.queue_free)
	else:
		player.queue_free()
	return player

static func create_sound(type: String) -> AudioStreamWAV:
	match type:
		"hit":
			return _gen_noise_burst(0.12, 400.0, 80.0)
		"player_hit":
			return _gen_tone(0.2, 140.0, 70.0, "sawtooth")
		"jump":
			return _gen_tone(0.18, 180.0, 420.0, "sine")
		"goblin_screech":
			return _gen_tone(0.25, 480.0, 240.0, "sawtooth")
		"goblin_attack":
			return _gen_noise_burst(0.15, 600.0, 200.0)
		"golem_step":
			return _gen_heavy_thud(0.35, 65.0, 30.0)
		"golem_slam":
			return _gen_earthquake_slam(0.8)
		"golem_throw":
			return _gen_noise_burst(0.3, 300.0, 100.0)
		"rock_break":
			return _gen_noise_burst(0.25, 500.0, 150.0)
		"wood_chop":
			return _gen_noise_burst(0.16, 800.0, 250.0)
		"coin":
			return _gen_arpeggio([880.0, 1320.0], 0.12)
		"chest_open":
			return _gen_fanfare()
		"sunset_suspense":
			return _gen_suspense_cue()
		"night_roar":
			return _gen_night_horn()
		"pickup":
			return _gen_arpeggio([523.25, 659.25, 783.99], 0.08)
		_:
			return _gen_tone(0.1, 440.0, 440.0, "sine")

static func _gen_tone(duration: float, freq_start: float, freq_end: float, wave: String = "sine") -> AudioStreamWAV:
	var sample_rate := 22050
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var freq := lerpf(freq_start, freq_end, t)
		phase += 2.0 * PI * freq / float(sample_rate)
		
		var env := 1.0 - t
		var val := 0.0
		if wave == "sine":
			val = sin(phase)
		elif wave == "sawtooth":
			val = fmod(phase / PI, 2.0) - 1.0
		elif wave == "square":
			val = 1.0 if sin(phase) > 0.0 else -1.0
			
		val *= env * 0.75
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = buffer
	return stream

static func _gen_noise_burst(duration: float, freq_start: float, freq_end: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var freq := lerpf(freq_start, freq_end, t)
		phase += 2.0 * PI * freq / float(sample_rate)
		
		var noise := randf_range(-1.0, 1.0)
		var tone := sin(phase)
		var env := pow(1.0 - t, 2.0)
		var val := (tone * 0.5 + noise * 0.5) * env * 0.75
		
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = buffer
	return stream

static func _gen_heavy_thud(duration: float, freq_start: float, freq_end: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var freq := lerpf(freq_start, freq_end, pow(t, 0.5))
		phase += 2.0 * PI * freq / float(sample_rate)
		
		var env := exp(-t * 8.0)
		var sub_bass := sin(phase)
		var noise := randf_range(-0.3, 0.3) * exp(-t * 20.0)
		var val := (sub_bass * 0.85 + noise) * env * 0.95
		
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = buffer
	return stream

static func _gen_earthquake_slam(duration: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var freq := lerpf(120.0, 25.0, pow(t, 0.4))
		phase += 2.0 * PI * freq / float(sample_rate)
		
		var env := exp(-t * 3.5)
		var rumble := sin(phase) * 0.7
		var noise := randf_range(-0.6, 0.6) * exp(-t * 6.0)
		var val := (rumble + noise) * env * 0.95
		
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = buffer
	return stream

static func _gen_arpeggio(freqs: Array, step_time: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var total_duration: float = step_time * freqs.size()
	var total_samples := int(total_duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase := 0.0
	var samples_per_step := int(step_time * sample_rate)
	
	for i in range(total_samples):
		var note_idx := clampi(i / samples_per_step, 0, freqs.size() - 1)
		var note_t := float(i % samples_per_step) / float(samples_per_step)
		var freq: float = freqs[note_idx]
		
		phase += 2.0 * PI * freq / float(sample_rate)
		var env := 1.0 - note_t * 0.5
		var val := (sin(phase) * 0.7 + sin(phase * 2.0) * 0.2) * env * 0.6
		
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = buffer
	return stream

static func _gen_fanfare() -> AudioStreamWAV:
	var sample_rate := 22050
	var notes := [440.0, 554.37, 659.25, 880.0, 1108.73, 1318.51]
	var step_dur := 0.12
	var final_dur := 0.6
	var total_dur := (notes.size() - 1) * step_dur + final_dur
	var total_samples := int(total_dur * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase := 0.0
	for i in range(total_samples):
		var cur_time := float(i) / float(sample_rate)
		var note_idx := clampi(int(cur_time / step_dur), 0, notes.size() - 1)
		var freq: float = notes[note_idx]
		phase += 2.0 * PI * freq / float(sample_rate)
		
		var decay := 1.0 - (cur_time / total_dur) * 0.4
		var chime := sin(phase) * 0.5 + sin(phase * 2.0) * 0.25 + sin(phase * 3.0) * 0.1
		var val := chime * decay * 0.7
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = buffer
	return stream

static func _gen_suspense_cue() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 2.5
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var p1 := 0.0
	var p2 := 0.0
	var p3 := 0.0
	
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		p1 += 2.0 * PI * 220.0 / float(sample_rate)
		p2 += 2.0 * PI * 261.63 / float(sample_rate)
		p3 += 2.0 * PI * 311.13 / float(sample_rate)
		
		var env := exp(-t * 2.0) * (0.8 + 0.2 * sin(t * 12.0))
		var chime := (sin(p1) + sin(p2) * 0.7 + sin(p3) * 0.5) / 2.2
		var val := chime * env * 0.8
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = buffer
	return stream

static func _gen_night_horn() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 3.0
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var freq := lerpf(90.0, 75.0, t) + sin(t * 15.0) * 3.0
		phase += 2.0 * PI * freq / float(sample_rate)
		
		var env := sin(t * PI)
		var horn := sin(phase) + 0.5 * sin(phase * 2.0) + 0.3 * sin(phase * 3.0)
		var val := horn * env * 0.6
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = buffer
	return stream
