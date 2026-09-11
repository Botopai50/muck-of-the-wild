class_name GameManager
extends Node

## Gerenciador Central de Muck of the Wild
## Controla o ciclo Dia/Noite, escala de dificuldade por dia, iluminacao e eventos globais

signal state_changed(new_state_name: String)
signal day_started(day_num: int)
signal sunset_started()
signal night_started(day_num: int, difficulty_mult: float)
signal dawn_started()
signal time_updated(hour: int, minute: int, state_name: String, progress: float)

enum CycleState {
	DAWN,
	DAY,
	SUNSET,
	NIGHT
}

const STATE_NAMES := {
	CycleState.DAWN: "Amanhecer",
	CycleState.DAY: "Dia",
	CycleState.SUNSET: "Pôr do Sol",
	CycleState.NIGHT: "Noite"
}

@export_group("Ciclo Dia e Noite")
@export var day_duration: float = 150.0    # 2.5 minutos de dia
@export var night_duration: float = 90.0   # 1.5 minutos de noite
@export var time_scale: float = 1.0        # Multiplicador para acelerar tempo (testes)
@export var current_day: int = 1
@export var current_state: CycleState = CycleState.DAY

@export_group("Ambiente e Iluminação")
@export var sun_light: DirectionalLight3D
@export var world_environment: WorldEnvironment

@export_group("Referências de Jogo")
@export var player: Node3D
@export var enemy_spawner: Node3D

var cycle_elapsed: float = 0.0
var _previous_state: CycleState = CycleState.DAY
var _audio_played_for_sunset: bool = false
var _audio_played_for_night: bool = false

# Cores e energias estilizadas Zelda BotW / Muck
const COLOR_DAWN_LIGHT := Color(1.0, 0.76, 0.55)
const COLOR_DAWN_FOG := Color(0.85, 0.72, 0.65)
const COLOR_DAWN_AMBIENT := Color(0.35, 0.38, 0.48)

const COLOR_DAY_LIGHT := Color(1.0, 0.98, 0.92)
const COLOR_DAY_FOG := Color(0.72, 0.85, 0.98)
const COLOR_DAY_AMBIENT := Color(0.5, 0.58, 0.68)

const COLOR_SUNSET_LIGHT := Color(1.0, 0.38, 0.18)
const COLOR_SUNSET_FOG := Color(0.92, 0.42, 0.28)
const COLOR_SUNSET_AMBIENT := Color(0.55, 0.32, 0.35)

const COLOR_NIGHT_LIGHT := Color(0.35, 0.48, 0.82)
const COLOR_NIGHT_FOG := Color(0.08, 0.1, 0.2)
const COLOR_NIGHT_AMBIENT := Color(0.12, 0.15, 0.26)

func _ready() -> void:
	if not world_environment:
		world_environment = get_node_or_null("../WorldEnvironment")
	if not sun_light:
		sun_light = get_node_or_null("../SunLight")
	if not player:
		player = get_node_or_null("../Player")
	if not enemy_spawner:
		enemy_spawner = get_node_or_null("../EnemySpawner")

	# Começar no início da manhã do Dia 1
	cycle_elapsed = day_duration * 0.15
	_update_cycle_state(true)
	_apply_lighting_and_atmosphere(1.0)

func _process(delta: float) -> void:
	var dt: float = delta * time_scale
	cycle_elapsed += dt
	
	var total_cycle: float = day_duration + night_duration
	if cycle_elapsed >= total_cycle:
		cycle_elapsed -= total_cycle
		current_day += 1
		print("[GameManager] Sobreviveu a mais uma noite! Iniciando Dia ", current_day)
		emit_signal("day_started", current_day)
		_audio_played_for_sunset = false
		_audio_played_for_night = false
	
	_update_cycle_state(false)
	_apply_lighting_and_atmosphere(dt)
	_notify_time_tick()

func _update_cycle_state(force: bool) -> void:
	var new_state: CycleState
	var is_daytime := cycle_elapsed < day_duration
	
	if is_daytime:
		var day_frac := cycle_elapsed / day_duration
		if day_frac < 0.15:
			new_state = CycleState.DAWN
		elif day_frac < 0.80:
			new_state = CycleState.DAY
		else:
			new_state = CycleState.SUNSET
	else:
		new_state = CycleState.NIGHT
		
	if new_state != current_state or force:
		current_state = new_state
		var state_name: String = STATE_NAMES[current_state]
		emit_signal("state_changed", state_name)
		print("[GameManager] Transição para: ", state_name, " (Dia ", current_day, ")")
		
		match current_state:
			CycleState.DAWN:
				emit_signal("dawn_started")
				_audio_played_for_sunset = false
				_audio_played_for_night = false
			CycleState.DAY:
				if _previous_state == CycleState.DAWN:
					emit_signal("day_started", current_day)
			CycleState.SUNSET:
				if not _audio_played_for_sunset:
					_audio_played_for_sunset = true
					emit_signal("sunset_started")
					AudioSynth.play_sound_2d(self, "sunset_suspense", -2.0)
					print("[GameManager] AVISO: O sol está se pondo... Prepare-se para a invasão noturna!")
			CycleState.NIGHT:
				if not _audio_played_for_night:
					_audio_played_for_night = true
					var diff: float = get_difficulty_multiplier()
					emit_signal("night_started", current_day, diff)
					AudioSynth.play_sound_2d(self, "night_roar", 0.0)
					print("[GameManager] A NOITE CAIU! Multiplicador de força: ", diff)
					
		_previous_state = current_state

func _apply_lighting_and_atmosphere(delta: float) -> void:
	var is_daytime := cycle_elapsed < day_duration
	var target_light_color: Color
	var target_fog_color: Color
	var target_ambient_color: Color
	var target_light_energy: float
	var target_fog_density: float
	var pitch_deg: float
	
	if is_daytime:
		var t := cycle_elapsed / day_duration
		pitch_deg = lerpf(12.0, 168.0, t)
		if t < 0.15:
			var sub_t := t / 0.15
			target_light_color = COLOR_DAWN_LIGHT.lerp(COLOR_DAY_LIGHT, sub_t)
			target_fog_color = COLOR_DAWN_FOG.lerp(COLOR_DAY_FOG, sub_t)
			target_ambient_color = COLOR_DAWN_AMBIENT.lerp(COLOR_DAY_AMBIENT, sub_t)
			target_light_energy = lerpf(0.7, 1.25, sub_t)
			target_fog_density = lerpf(0.003, 0.001, sub_t)
		elif t < 0.80:
			target_light_color = COLOR_DAY_LIGHT
			target_fog_color = COLOR_DAY_FOG
			target_ambient_color = COLOR_DAY_AMBIENT
			target_light_energy = 1.25
			target_fog_density = 0.001
		else:
			var sub_t := (t - 0.80) / 0.20
			target_light_color = COLOR_DAY_LIGHT.lerp(COLOR_SUNSET_LIGHT, sub_t)
			target_fog_color = COLOR_DAY_FOG.lerp(COLOR_SUNSET_FOG, sub_t)
			target_ambient_color = COLOR_DAY_AMBIENT.lerp(COLOR_SUNSET_AMBIENT, sub_t)
			target_light_energy = lerpf(1.25, 0.75, sub_t)
			target_fog_density = lerpf(0.001, 0.0045, sub_t)
	else:
		var t := (cycle_elapsed - day_duration) / night_duration
		# À noite, a luz atua como o luar vindo do alto com tom azulado prateado
		pitch_deg = 50.0
		target_light_color = COLOR_NIGHT_LIGHT
		target_fog_color = COLOR_NIGHT_FOG
		target_ambient_color = COLOR_NIGHT_AMBIENT
		target_light_energy = 0.45
		target_fog_density = 0.005
		
	# Suavizar rotação do Sol / Lua
	if sun_light:
		var target_rot: Vector3
		if is_daytime:
			target_rot = Vector3(deg_to_rad(-pitch_deg), deg_to_rad(-35.0), 0.0)
		else:
			# Luar vindo do ângulo oposto no céu
			target_rot = Vector3(deg_to_rad(-pitch_deg), deg_to_rad(145.0), 0.0)
			
		if delta >= 0.99:
			sun_light.rotation = target_rot
			sun_light.light_color = target_light_color
			sun_light.light_energy = target_light_energy
		else:
			sun_light.rotation = sun_light.rotation.lerp(target_rot, clampf(delta * 4.0, 0.0, 1.0))
			sun_light.light_color = sun_light.light_color.lerp(target_light_color, clampf(delta * 2.0, 0.0, 1.0))
			sun_light.light_energy = lerpf(sun_light.light_energy, target_light_energy, clampf(delta * 2.0, 0.0, 1.0))
		sun_light.shadow_enabled = true
		
	# Suavizar nevoeiro, céu e iluminação de ambiente no WorldEnvironment
	if world_environment and world_environment.environment:
		var env: Environment = world_environment.environment
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		if delta >= 0.99:
			env.ambient_light_color = target_ambient_color
			env.fog_light_color = target_fog_color
			env.fog_density = target_fog_density
		else:
			env.ambient_light_color = env.ambient_light_color.lerp(target_ambient_color, clampf(delta * 2.0, 0.0, 1.0))
			env.fog_light_color = env.fog_light_color.lerp(target_fog_color, clampf(delta * 2.0, 0.0, 1.0))
			env.fog_density = lerpf(env.fog_density, target_fog_density, clampf(delta * 2.0, 0.0, 1.0))
		env.ambient_light_energy = 1.0
		env.fog_enabled = true
		env.fog_sky_affect = 0.05
		
		# Sincronizar Céu Dinâmico BotW com a hora calculada
		if env.sky:
			env.sky.process_mode = Sky.PROCESS_MODE_REALTIME
			if env.sky.sky_material is ShaderMaterial:
				var total_cycle := day_duration + night_duration
				var prog := cycle_elapsed / total_cycle
				var sim_hour: float = fmod(6.0 + prog * 24.0, 24.0)
				env.sky.sky_material.set_shader_parameter("time_of_day", sim_hour)
				env.sky.sky_material.set_shader_parameter("use_light_direction", false)
			# print("[GM] Setting time_of_day = ", sim_hour)

func _notify_time_tick() -> void:
	var total_cycle := day_duration + night_duration
	var progress := cycle_elapsed / total_cycle
	# Mapear 0.0 a 1.0 para 06:00 a 06:00 do dia seguinte (24 horas)
	var total_minutes := int(progress * 1440.0) # 24h * 60m
	var hour := (6 + total_minutes / 60) % 24
	var minute := total_minutes % 60
	emit_signal("time_updated", hour, minute, STATE_NAMES[current_state], progress)

## Fórmulas de escala de dificuldade por Dia sobrevivido
func get_difficulty_multiplier() -> float:
	return 1.0 + float(current_day - 1) * 0.35

func get_enemy_health_multiplier() -> float:
	return 1.0 + float(current_day - 1) * 0.30

func get_enemy_damage_multiplier() -> float:
	return 1.0 + float(current_day - 1) * 0.25

func get_enemy_count_multiplier() -> float:
	return 1.0 + float(current_day - 1) * 0.40

func get_golem_spawn_count() -> int:
	# Noite 1: nenhum golem (apenas goblins)
	# Noite 2+: 1 ou mais golems mini-chefes conforme avança
	if current_day <= 1:
		return 0
	return clampi(current_day - 1, 1, 3)

func is_night() -> bool:
	return current_state == CycleState.NIGHT

func is_sunset() -> bool:
	return current_state == CycleState.SUNSET
