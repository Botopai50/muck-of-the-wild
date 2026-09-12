class_name AudioSynth
extends Node

## Gerador de áudio procedural aprimorado para SFX estilizados (Zelda BotW / Muck)
## Não requer arquivos de áudio externos; sintetiza formas de onda PCM na hora
## com harmônicos ricos, reverberação simulada e decaimento acústico orgânico.

static var _cached_sounds: Dictionary = {}

static func play_sound(parent: Node, sound_type: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer3D:
	if not parent or not parent.is_inside_tree():
		return null
	var player := AudioStreamPlayer3D.new()
	player.bus = &"Master"
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.max_distance = 45.0
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
	if _cached_sounds.has(type):
		return _cached_sounds[type]

	var stream: AudioStreamWAV = null
	match type:
		# 1. Passos dinâmicos na grama
		"footstep_grass", "grass_step", "step":
			stream = _gen_grass_footstep()
			
		# 2. Pulo dinâmico
		"jump", "player_jump":
			stream = _gen_jump()
		"double_jump":
			stream = _gen_double_jump()
			
		# 3. Swing de arma com corte de vento realista
		"weapon_swing", "swing", "slash":
			stream = _gen_weapon_swing()
			
		# 4. Impacto seco de madeira
		"impact_wood", "wood_chop", "chop":
			stream = _gen_wood_impact()
			
		# 5. Clink de pedra / mineração
		"impact_stone", "rock_mine", "mine", "clink":
			stream = _gen_stone_clink()
			
		# 6. Fanfarra mágica de baú / relíquia Sheikah
		"chest_open", "fanfare", "relic", "relic_pickup":
			stream = _gen_magical_chest_fanfare()
			
		# 7. Golpe em inimigo
		"hit", "enemy_hit", "damage":
			stream = _gen_enemy_hit()
		"player_hit":
			stream = _gen_player_hit()
			
		# 8. Efeitos colossais do Golem e Goblin
		"golem_step":
			stream = _gen_golem_footstep()
		"golem_slam":
			stream = _gen_golem_slam()
		"golem_throw":
			stream = _gen_boulder_throw()
		"rock_break", "break":
			stream = _gen_rock_break()
		"goblin_screech":
			stream = _gen_goblin_screech()
		"goblin_attack":
			stream = _gen_goblin_attack()
		"coin", "item_pickup", "pickup":
			stream = _gen_coin_pickup()
		"sunset_suspense":
			stream = _gen_sunset_suspense()
		"night_roar":
			stream = _gen_night_roar()
		_:
			stream = _gen_enemy_hit()

	if stream:
		_cached_sounds[type] = stream
	return stream

# ====================================================================
# SÍNTESE PROCEDURAL REFINADA COM HARMÔNICOS E ACÚSTICA ORGÂNICA
# ====================================================================

## 1. Passos dinâmicos na grama: compressão turf suave + atrito granular de folhas
static func _gen_grass_footstep() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.16
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase_sub := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env_turf := exp(-t * 28.0)
		var env_blade := exp(-t * 16.0) * (0.8 + 0.2 * sin(t * 120.0))
		
		# Sub-impacto suave do solo (~75 Hz descendo para ~45 Hz)
		var freq_sub := lerpf(75.0, 45.0, t)
		phase_sub += 2.0 * PI * freq_sub / float(sample_rate)
		var turf := sin(phase_sub) * 0.45 * env_turf
		
		# Ruído filtrado de lâminas de grama estalando
		var blade_noise := randf_range(-1.0, 1.0) * env_blade * 0.4
		var val := (turf + blade_noise) * 0.85
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	return _build_wav(buffer, sample_rate)

## 2. Pulo: impulso corporal elástico com corte aerodinâmico ascendente
static func _gen_jump() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.22
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase1 := 0.0
	var phase2 := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := pow(1.0 - t, 1.6)
		
		# Frequência fundamental subindo com sweep suave (90 Hz -> 360 Hz)
		var freq := lerpf(90.0, 360.0, pow(t, 0.6))
		phase1 += 2.0 * PI * freq / float(sample_rate)
		phase2 += 2.0 * PI * (freq * 1.5) / float(sample_rate)
		
		# Harmônico fundamental + ar aspirado
		var tone := sin(phase1) * 0.65 + sin(phase2) * 0.2
		var whoosh := randf_range(-0.35, 0.35) * sin(t * PI)
		var val := (tone + whoosh) * env * 0.85
		
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	return _build_wav(buffer, sample_rate)

## Pulo duplo com pena / relíquia: mais arejado e agudo
static func _gen_double_jump() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.24
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := exp(-t * 8.0) * sin(t * PI)
		var freq := lerpf(240.0, 680.0, pow(t, 0.5))
		phase += 2.0 * PI * freq / float(sample_rate)
		
		var shimmer := (sin(phase) + 0.4 * sin(phase * 2.0)) * 0.55
		var airy := randf_range(-0.3, 0.3) * exp(-t * 6.0)
		var val := (shimmer + airy) * env * 0.85
		
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	return _build_wav(buffer, sample_rate)

## 3. Swing de arma com corte de vento realista: vórtice sonoro aerodinâmico
static func _gen_weapon_swing() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.24
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase_whistle := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		
		# Envelope com aceleração rápida até o meio e decaimento trailing
		var env := sin(t * PI) * (1.2 if t < 0.45 else exp(-(t - 0.45) * 7.0))
		
		# Frequência de corte do vórtice (1400 Hz caindo para 320 Hz)
		var sweep_freq := lerpf(1400.0, 320.0, pow(t, 1.2))
		phase_whistle += 2.0 * PI * sweep_freq / float(sample_rate)
		
		var wind_noise := randf_range(-1.0, 1.0) * 0.6
		var blade_whistle := sin(phase_whistle) * 0.35
		var sub_whoosh := sin(phase_whistle * 0.25) * 0.2
		
		var val := (wind_noise + blade_whistle + sub_whoosh) * env * 0.8
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	return _build_wav(buffer, sample_rate)

## 4. Impacto seco de madeira: transiente estalado + ressonância de cavidade oca
static func _gen_wood_impact() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.20
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase_body := 0.0
	var phase_over := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env_snap := exp(-t * 45.0) # Estalo seco de lascas
		var env_body := exp(-t * 24.0) # Corpo oco
		
		# Corpo ressonante de madeira em ~180 Hz com 2º harmônico em ~360 Hz
		var freq := lerpf(220.0, 160.0, t)
		phase_body += 2.0 * PI * freq / float(sample_rate)
		phase_over += 2.0 * PI * (freq * 2.1) / float(sample_rate)
		
		var wood_tone := (sin(phase_body) * 0.65 + sin(phase_over) * 0.35) * env_body
		var splinter_snap := randf_range(-1.0, 1.0) * env_snap * 0.6
		
		var val := (wood_tone + splinter_snap) * 0.95
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	return _build_wav(buffer, sample_rate)

## 5. Clink de pedra: ataque metálico cristalino, ressonância pétrea e reverberação
static func _gen_stone_clink() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.28
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var p_funda := 0.0
	var p_harm1 := 0.0
	var p_harm2 := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env_strike := exp(-t * 22.0)
		var env_crumble := exp(-t * 14.0)
		
		# Harmônicos cristalinos (1450 Hz, 2900 Hz, 4200 Hz)
		p_funda += 2.0 * PI * 1450.0 / float(sample_rate)
		p_harm1 += 2.0 * PI * 2900.0 / float(sample_rate)
		p_harm2 += 2.0 * PI * 4200.0 / float(sample_rate)
		
		var ring := (sin(p_funda) * 0.5 + sin(p_harm1) * 0.3 + sin(p_harm2) * 0.15) * env_strike
		var crumble := randf_range(-0.5, 0.5) * env_crumble
		
		var val := (ring * 0.75 + crumble * 0.35) * 0.9
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	# Reverberação simulada de caverna/pedreira
	_apply_simulated_reverb(buffer, sample_rate, 42.0, 0.32)
	return _build_wav(buffer, sample_rate)

## 6. Fanfarra mágica de baú / relíquia: acordes celestiais em Ré Lídio com reverb e brilho
static func _gen_magical_chest_fanfare() -> AudioStreamWAV:
	var sample_rate := 22050
	# Sequência harmônica estilo BotW: D5, F#5, A5, C#6, D6, F#6
	var notes := [587.33, 739.99, 880.00, 1108.73, 1174.66, 1479.98]
	var step_dur := 0.14
	var final_ring := 0.9
	var total_dur := (notes.size() - 1) * step_dur + final_ring
	var total_samples := int(total_dur * sample_rate)
	
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phases := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	
	for i in range(total_samples):
		var cur_time := float(i) / float(sample_rate)
		var val := 0.0
		
		for n in range(notes.size()):
			var note_start := n * step_dur
			if cur_time >= note_start:
				var t_note := cur_time - note_start
				var dur_note := final_ring if n == notes.size() - 1 else step_dur * 2.5
				var env := exp(-t_note * (3.0 if n == notes.size() - 1 else 5.5))
				
				var freq: float = notes[n]
				phases[n] += 2.0 * PI * freq / float(sample_rate)
				
				# Sino com fundamental + 2º harmônico + brilho cintilante
				var bell := sin(phases[n]) * 0.55 + sin(phases[n] * 2.0) * 0.28 + sin(phases[n] * 3.0) * 0.12
				val += bell * env * (0.35 if n < notes.size() - 1 else 0.55)
				
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	# Reverberação mágica expansiva (múltiplos ecos simulados)
	_apply_simulated_reverb(buffer, sample_rate, 65.0, 0.40)
	_apply_simulated_reverb(buffer, sample_rate, 120.0, 0.25)
	return _build_wav(buffer, sample_rate)

## 7. Golpe em inimigo: impacto carnal visceral, estalo de impacto e peso
static func _gen_enemy_hit() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.18
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase_sub := 0.0
	var phase_mid := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := exp(-t * 22.0)
		
		# Sub-punch impactante (110 Hz -> 50 Hz)
		var freq_sub := lerpf(110.0, 50.0, pow(t, 0.4))
		phase_sub += 2.0 * PI * freq_sub / float(sample_rate)
		var sub_thud := sin(phase_sub) * 0.65
		
		# Estalo mézio (650 Hz)
		phase_mid += 2.0 * PI * 650.0 / float(sample_rate)
		var mid_snap := sin(phase_mid) * exp(-t * 40.0) * 0.35
		
		# Crunch de textura
		var crunch := randf_range(-0.5, 0.5) * exp(-t * 30.0) * 0.35
		
		var val := (sub_thud + mid_snap + crunch) * env * 0.95
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	return _build_wav(buffer, sample_rate)

static func _gen_player_hit() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.22
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := exp(-t * 16.0)
		var freq := lerpf(160.0, 60.0, pow(t, 0.5))
		phase += 2.0 * PI * freq / float(sample_rate)
		
		var saw := (fmod(phase / PI, 2.0) - 1.0) * 0.4
		var sub := sin(phase) * 0.5
		var val := (saw + sub) * env * 0.9
		
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	return _build_wav(buffer, sample_rate)

## 8. Pisada colossal do Golem: tremor sísmico pesado
static func _gen_golem_footstep() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.42
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := exp(-t * 7.5)
		var freq := lerpf(70.0, 25.0, pow(t, 0.4))
		phase += 2.0 * PI * freq / float(sample_rate)
		
		var sub_bass := sin(phase) * 0.75 + sin(phase * 0.5) * 0.2
		var grit := randf_range(-0.4, 0.4) * exp(-t * 18.0)
		var val := (sub_bass + grit) * env * 0.95
		
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	_apply_simulated_reverb(buffer, sample_rate, 50.0, 0.35)
	return _build_wav(buffer, sample_rate)

## Onda de choque e pisão colossal do Golem
static func _gen_golem_slam() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.9
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := exp(-t * 3.8)
		var freq := lerpf(130.0, 24.0, pow(t, 0.35))
		phase += 2.0 * PI * freq / float(sample_rate)
		
		var seismic := sin(phase) * 0.65 + sin(phase * 2.0) * 0.25
		var rumble_noise := randf_range(-0.6, 0.6) * exp(-t * 5.0)
		var val := (seismic + rumble_noise) * env * 0.95
		
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	_apply_simulated_reverb(buffer, sample_rate, 75.0, 0.45)
	_apply_simulated_reverb(buffer, sample_rate, 150.0, 0.30)
	return _build_wav(buffer, sample_rate)

static func _gen_boulder_throw() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.38
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := sin(t * PI)
		var freq := lerpf(280.0, 80.0, t)
		phase += 2.0 * PI * freq / float(sample_rate)
		
		var whoosh := (sin(phase) * 0.4 + randf_range(-0.6, 0.6)) * env * 0.8
		var sample16 := int(clampf(whoosh, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	return _build_wav(buffer, sample_rate)

static func _gen_rock_break() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.36
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := exp(-t * 8.5)
		phase += 2.0 * PI * lerpf(380.0, 90.0, pow(t, 0.5)) / float(sample_rate)
		
		var crack := (sin(phase) * 0.4 + randf_range(-0.8, 0.8)) * env * 0.9
		var sample16 := int(clampf(crack, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	return _build_wav(buffer, sample_rate)

static func _gen_goblin_screech() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.28
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := sin(t * PI) * exp(-t * 2.5)
		var freq := lerpf(520.0, 280.0, t) + sin(t * 40.0) * 35.0
		phase += 2.0 * PI * freq / float(sample_rate)
		
		var rasp := (fmod(phase / PI, 2.0) - 1.0) * 0.6 + randf_range(-0.3, 0.3)
		var val := rasp * env * 0.75
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	return _build_wav(buffer, sample_rate)

static func _gen_goblin_attack() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.18
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := exp(-t * 18.0)
		var val := randf_range(-0.8, 0.8) * env * 0.8
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	return _build_wav(buffer, sample_rate)

static func _gen_coin_pickup() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.18
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var p1 := 0.0
	var p2 := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var env := exp(-t * 14.0)
		p1 += 2.0 * PI * 987.77 / float(sample_rate)
		p2 += 2.0 * PI * 1318.51 / float(sample_rate)
		
		var chime := sin(p1) * 0.5 + sin(p2) * 0.4
		var val := chime * env * 0.75
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	return _build_wav(buffer, sample_rate)

static func _gen_sunset_suspense() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 2.6
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
		
		var env := exp(-t * 1.8) * (0.8 + 0.2 * sin(t * 10.0))
		var chime := (sin(p1) + sin(p2) * 0.7 + sin(p3) * 0.5) / 2.2
		var val := chime * env * 0.75
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	_apply_simulated_reverb(buffer, sample_rate, 90.0, 0.35)
	return _build_wav(buffer, sample_rate)

static func _gen_night_roar() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 3.2
	var total_samples := int(duration * sample_rate)
	var buffer := PackedByteArray()
	buffer.resize(total_samples * 2)
	
	var phase := 0.0
	for i in range(total_samples):
		var t := float(i) / float(total_samples)
		var freq := lerpf(92.0, 72.0, t) + sin(t * 16.0) * 4.0
		phase += 2.0 * PI * freq / float(sample_rate)
		
		var env := sin(t * PI)
		var horn := sin(phase) * 0.6 + sin(phase * 2.0) * 0.3 + sin(phase * 3.0) * 0.15
		var val := horn * env * 0.7
		var sample16 := int(clampf(val, -1.0, 1.0) * 32767.0)
		buffer.encode_s16(i * 2, sample16)
		
	_apply_simulated_reverb(buffer, sample_rate, 80.0, 0.4)
	return _build_wav(buffer, sample_rate)

# ====================================================================
# UTILITÁRIOS: REVERB SIMULADO E BUFFER WAV
# ====================================================================

static func _apply_simulated_reverb(buffer: PackedByteArray, sample_rate: int, delay_ms: float, decay: float) -> void:
	var delay_samples := int(float(sample_rate) * (delay_ms / 1000.0))
	var total_samples := buffer.size() / 2
	for i in range(delay_samples, total_samples):
		var dry := buffer.decode_s16(i * 2)
		var echo := buffer.decode_s16((i - delay_samples) * 2)
		var mixed := int(float(dry) + float(echo) * decay)
		buffer.encode_s16(i * 2, clampi(mixed, -32768, 32767))

static func _build_wav(buffer: PackedByteArray, sample_rate: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = buffer
	return stream
