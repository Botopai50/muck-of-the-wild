class_name PlayerViewmodel
extends Node3D

## Procedural Viewmodel Controller for Muck of the Wild
## Controla braços em primeira pessoa com Túnica do Campeão BotW, armas ativas,
## balanço procedural (sway & inertia), bobbing de caminhada, sistema de combo
## de 3 golpes (Golpe 1 Direita, Golpe 2 Esquerda, Golpe 3 Pesado) e rastro de corte emissivo.

signal attack_hit_frame(item_type: String)
signal attack_finished(item_type: String)
signal attack_combo_advanced(combo_step: int, is_heavy: bool)

enum ItemType {
	FISTS,
	AXE,
	PICKAXE,
	SWORD,
	FOOD
}

@export_group("Sway & Inertia")
@export var sway_amount_pos: float = 0.0009
@export var sway_amount_rot: float = 0.0014
@export var sway_smooth: float = 14.0
@export var sway_max_pos: float = 0.07
@export var sway_max_rot: float = 0.14

@export_group("Bobbing")
@export var bob_pos_multiplier: Vector3 = Vector3(0.016, 0.022, 0.0)
@export var bob_rot_multiplier: Vector3 = Vector3(0.035, 0.022, 0.045)

# Current item state
var current_item: ItemType = ItemType.FISTS
var is_attacking: bool = false
var attack_cooldown: float = 0.0

# Combo system (Golpe 1 Direita, Golpe 2 Esquerda, Golpe 3 Pesado)
var combo_step: int = 0
var current_attack_step: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 0.85
var is_heavy_swing: bool = false

# Resting transforms
var rest_pos: Vector3 = Vector3.ZERO
var rest_rot: Vector3 = Vector3.ZERO

# Sway & recoil offsets
var target_sway_pos: Vector3 = Vector3.ZERO
var target_sway_rot: Vector3 = Vector3.ZERO
var current_sway_pos: Vector3 = Vector3.ZERO
var current_sway_rot: Vector3 = Vector3.ZERO
var anim_pos_offset: Vector3 = Vector3.ZERO
var anim_rot_offset: Vector3 = Vector3.ZERO

# Inertia offset (jump, land, hit recoil)
var inertia_pos_offset: Vector3 = Vector3.ZERO
var inertia_rot_offset: Vector3 = Vector3.ZERO

# Node references
@onready var slash_trail: Node3D = $SlashTrail
@onready var items_container: Node3D = $Items
@onready var fists_model: Node3D = $Items/Fists
@onready var axe_model: Node3D = $Items/Axe
@onready var pickaxe_model: Node3D = $Items/Pickaxe
@onready var sword_model: Node3D = $Items/Sword
@onready var food_model: Node3D = $Items/Food
@onready var right_arm: Node3D = $Arms/RightArm
@onready var left_arm: Node3D = $Arms/LeftArm

func _cache_nodes() -> void:
	if not slash_trail: slash_trail = get_node_or_null("SlashTrail")
	if not items_container: items_container = get_node_or_null("Items")
	if not fists_model: fists_model = get_node_or_null("Items/Fists")
	if not axe_model: axe_model = get_node_or_null("Items/Axe")
	if not pickaxe_model: pickaxe_model = get_node_or_null("Items/Pickaxe")
	if not sword_model: sword_model = get_node_or_null("Items/Sword")
	if not food_model: food_model = get_node_or_null("Items/Food")
	if not right_arm: right_arm = get_node_or_null("Arms/RightArm")
	if not left_arm: left_arm = get_node_or_null("Arms/LeftArm")

func _ready() -> void:
	_cache_nodes()
	rest_pos = position
	rest_rot = rotation
	set_item(ItemType.FISTS)

func _process(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown = maxf(0.0, attack_cooldown - delta)

	# Gerenciamento da janela de combo
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0 and not is_attacking:
			combo_step = 0
			current_attack_step = 0

	# Suaviza sway e inércia de volta ao centro
	target_sway_pos = target_sway_pos.lerp(Vector3.ZERO, delta * 7.0)
	target_sway_rot = target_sway_rot.lerp(Vector3.ZERO, delta * 7.0)

	current_sway_pos = current_sway_pos.lerp(target_sway_pos, delta * sway_smooth)
	current_sway_rot = current_sway_rot.lerp(target_sway_rot, delta * sway_smooth)

	inertia_pos_offset = inertia_pos_offset.lerp(Vector3.ZERO, delta * 8.0)
	inertia_rot_offset = inertia_rot_offset.lerp(Vector3.ZERO, delta * 8.0)

	# Aplica transformações combinadas no viewmodel
	position = rest_pos + current_sway_pos + anim_pos_offset + inertia_pos_offset
	rotation = rest_rot + current_sway_rot + anim_rot_offset + inertia_rot_offset

## Chamado pelo PlayerController quando o mouse se move
func add_camera_sway(mouse_delta: Vector2) -> void:
	var pos_x = clampf(-mouse_delta.x * sway_amount_pos, -sway_max_pos, sway_max_pos)
	var pos_y = clampf(-mouse_delta.y * sway_amount_pos, -sway_max_pos, sway_max_pos)
	target_sway_pos += Vector3(pos_x, pos_y, 0.0)

	var rot_y = clampf(-mouse_delta.x * sway_amount_rot, -sway_max_rot, sway_max_rot)
	var rot_x = clampf(-mouse_delta.y * sway_amount_rot, -sway_max_rot, sway_max_rot)
	var rot_z = clampf(mouse_delta.x * (sway_amount_rot * 0.6), -sway_max_rot, sway_max_rot)
	target_sway_rot += Vector3(rot_x, rot_y, rot_z)

## Chamado pelo PlayerController durante caminhada/corrida
func apply_movement_bob(bob_time: float, intensity: float) -> void:
	if is_attacking:
		return
	var sin_time = sin(bob_time)
	var cos_time = cos(bob_time * 0.5)

	var bob_pos = Vector3(
		cos_time * bob_pos_multiplier.x * intensity,
		sin_time * bob_pos_multiplier.y * intensity,
		0.0
	)
	var bob_rot = Vector3(
		sin_time * bob_rot_multiplier.x * intensity,
		cos_time * bob_rot_multiplier.y * intensity,
		sin_time * bob_rot_multiplier.z * intensity
	)

	current_sway_pos = current_sway_pos.lerp(bob_pos, 0.25)
	current_sway_rot = current_sway_rot.lerp(bob_rot, 0.25)

## Inércia de pulo: arma inclina suavemente para cima
func apply_jump_recoil() -> void:
	inertia_pos_offset += Vector3(0.01, 0.03, 0.02)
	inertia_rot_offset += Vector3(deg_to_rad(6.0), 0.0, deg_to_rad(-2.0))

## Inércia de aterrissagem: arma desce com amortecimento baseado na velocidade de impacto
func apply_land_recoil(impact_speed: float) -> void:
	var factor = clampf(impact_speed / 8.0, 0.6, 1.6)
	inertia_pos_offset += Vector3(0.0, -0.05 * factor, -0.02 * factor)
	inertia_rot_offset += Vector3(deg_to_rad(-8.0 * factor), 0.0, 0.0)

## Recuo de impacto físico ao golpear objetos/inimigos
func apply_hit_recoil() -> void:
	inertia_pos_offset += Vector3(randf_range(-0.02, 0.02), 0.02, 0.05)
	inertia_rot_offset += Vector3(deg_to_rad(5.0), randf_range(-0.04, 0.04), 0.0)

## Troca de item ativo
func set_item(type: ItemType) -> void:
	_cache_nodes()
	current_item = type
	if fists_model: fists_model.visible = (type == ItemType.FISTS)
	if axe_model: axe_model.visible = (type == ItemType.AXE)
	if pickaxe_model: pickaxe_model.visible = (type == ItemType.PICKAXE)
	if sword_model: sword_model.visible = (type == ItemType.SWORD)
	if food_model: food_model.visible = (type == ItemType.FOOD)

	# Braço esquerdo visível em punhos e comida
	if left_arm: left_arm.visible = (type == ItemType.FISTS or type == ItemType.FOOD)
	
	# Reseta combo ao trocar de arma
	combo_step = 0
	current_attack_step = 0
	combo_timer = 0.0

func get_item_name() -> String:
	match current_item:
		ItemType.FISTS: return "fists"
		ItemType.AXE: return "axe"
		ItemType.PICKAXE: return "pickaxe"
		ItemType.SWORD: return "sword"
		ItemType.FOOD: return "food"
	return "fists"

func get_attack_cooldown_time(step: int = 0) -> float:
	var mult: float = 1.25 if step == 2 else 1.0
	match current_item:
		ItemType.FISTS: return 0.22 * mult
		ItemType.SWORD: return 0.32 * mult
		ItemType.AXE: return 0.42 * mult
		ItemType.PICKAXE: return 0.46 * mult
		ItemType.FOOD: return 0.70
	return 0.32 * mult

func get_damage(step_override: int = -1) -> float:
	var base_dmg: float = 10.0
	match current_item:
		ItemType.FISTS: base_dmg = 10.0
		ItemType.AXE: base_dmg = 20.0
		ItemType.PICKAXE: base_dmg = 16.0
		ItemType.SWORD: base_dmg = 32.0
		ItemType.FOOD: base_dmg = 0.0

	var s = step_override if step_override >= 0 else current_attack_step
	match s:
		0: return base_dmg
		1: return base_dmg * 1.15
		2: return base_dmg * 1.75
	return base_dmg

func is_current_attack_heavy() -> bool:
	return is_heavy_swing

func get_trail_color() -> Color:
	match current_item:
		ItemType.SWORD:
			return Color(0.28, 0.80, 1.0) # Lâmina BotW Cyan
		ItemType.AXE:
			return Color(1.0, 0.65, 0.22)  # Corte Âmbar Flamejante
		ItemType.PICKAXE:
			return Color(0.96, 0.84, 0.32) # Faísca Mineral Ouro
		ItemType.FISTS:
			return Color(0.85, 0.95, 1.0)  # Lâmina de Vento Branca
	return Color(0.35, 0.78, 1.0)

## Dispara ação primária com encadeamento de combo
func trigger_primary_action() -> bool:
	if is_attacking or attack_cooldown > 0.0:
		return false

	_cache_nodes()
	is_attacking = true
	current_attack_step = combo_step
	is_heavy_swing = (current_attack_step == 2)
	attack_cooldown = get_attack_cooldown_time(current_attack_step)

	combo_step = (combo_step + 1) % 3
	combo_timer = COMBO_WINDOW
	attack_combo_advanced.emit(current_attack_step, is_heavy_swing)

	match current_item:
		ItemType.FISTS:
			_play_fists_combo_animation(current_attack_step)
		ItemType.AXE, ItemType.PICKAXE, ItemType.SWORD:
			_play_weapon_combo_animation(current_attack_step)
		ItemType.FOOD:
			_play_eat_animation()

	return true

# ---------------------------------------------------------
# Animações Procedurais de Combo (Golpe 1, 2 e Golpe Pesado)
# ---------------------------------------------------------

func _play_weapon_combo_animation(step: int) -> void:
	match step:
		0:
			_play_slash_strike_1() # Golpe 1: Corte diagonal da direita
		1:
			_play_slash_strike_2() # Golpe 2: Corte diagonal ascendente da esquerda
		2:
			_play_heavy_overhead_strike() # Golpe 3: Golpe pesado vertical (overhead cleave)

## Golpe 1: Corte rápido descendente da direita para esquerda
func _play_slash_strike_1() -> void:
	AudioManager.play_sound("weapon_swing", 0.08, 0.0)
	var tween: Tween = create_tween().set_parallel(false)

	# 1. Preparação (Wind-up no alto à direita)
	var windup_pos = Vector3(0.08, 0.10, 0.06)
	var windup_rot = Vector3(deg_to_rad(32.0), deg_to_rad(-26.0), deg_to_rad(22.0))
	var t_windup = tween.parallel()
	t_windup.tween_property(self, "anim_pos_offset", windup_pos, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t_windup.tween_property(self, "anim_rot_offset", windup_rot, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Corte diagonal para baixo e esquerda
	var slash_pos = Vector3(-0.18, -0.14, -0.22)
	var slash_rot = Vector3(deg_to_rad(-45.0), deg_to_rad(50.0), deg_to_rad(-42.0))
	var t_slash = tween.parallel()
	t_slash.tween_property(self, "anim_pos_offset", slash_pos, 0.10).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	t_slash.tween_property(self, "anim_rot_offset", slash_rot, 0.10).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	# Impacto e rastro de corte
	tween.tween_callback(func():
		if slash_trail and slash_trail.has_method("play_slash"):
			slash_trail.play_slash(0.20, get_trail_color(), false, -24.0, 4.0)
		attack_hit_frame.emit(get_item_name())
	)

	# 3. Retorno fluido
	var t_recover = tween.parallel()
	t_recover.tween_property(self, "anim_pos_offset", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t_recover.tween_property(self, "anim_rot_offset", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		is_attacking = false
		attack_finished.emit(get_item_name())
	)

## Golpe 2: Corte ascendente ágil da esquerda para a direita
func _play_slash_strike_2() -> void:
	AudioManager.play_sound("weapon_swing", 0.08, 1.8)
	var tween: Tween = create_tween().set_parallel(false)

	# 1. Preparação (Wind-up baixo à esquerda)
	var windup_pos = Vector3(-0.14, -0.12, 0.05)
	var windup_rot = Vector3(deg_to_rad(-16.0), deg_to_rad(36.0), deg_to_rad(-26.0))
	var t_windup = tween.parallel()
	t_windup.tween_property(self, "anim_pos_offset", windup_pos, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t_windup.tween_property(self, "anim_rot_offset", windup_rot, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Corte ascendente cruzado
	var slash_pos = Vector3(0.18, 0.16, -0.20)
	var slash_rot = Vector3(deg_to_rad(42.0), deg_to_rad(-52.0), deg_to_rad(38.0))
	var t_slash = tween.parallel()
	t_slash.tween_property(self, "anim_pos_offset", slash_pos, 0.10).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	t_slash.tween_property(self, "anim_rot_offset", slash_rot, 0.10).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	# Impacto e rastro de corte invertido
	tween.tween_callback(func():
		if slash_trail and slash_trail.has_method("play_slash"):
			slash_trail.play_slash(0.20, get_trail_color(), true, 32.0, -8.0)
		attack_hit_frame.emit(get_item_name())
	)

	# 3. Retorno fluido
	var t_recover = tween.parallel()
	t_recover.tween_property(self, "anim_pos_offset", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t_recover.tween_property(self, "anim_rot_offset", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		is_attacking = false
		attack_finished.emit(get_item_name())
	)

## Golpe 3: Golpe Pesado vertical com recuo acentuado (Heavy Overhead Cleave)
func _play_heavy_overhead_strike() -> void:
	AudioManager.play_sound("weapon_swing", 0.14, -2.5)
	var tween: Tween = create_tween().set_parallel(false)

	# 1. Elevação imponente acima da cabeça (maior antecipação)
	var windup_pos = Vector3(0.02, 0.24, 0.08)
	var windup_rot = Vector3(deg_to_rad(58.0), deg_to_rad(6.0), deg_to_rad(-8.0))
	var t_windup = tween.parallel()
	t_windup.tween_property(self, "anim_pos_offset", windup_pos, 0.13).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t_windup.tween_property(self, "anim_rot_offset", windup_rot, 0.13).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 2. Clivagem vertical devastadora
	var slam_pos = Vector3(0.0, -0.28, -0.28)
	var slam_rot = Vector3(deg_to_rad(-70.0), 0.0, 0.0)
	var t_slam = tween.parallel()
	t_slam.tween_property(self, "anim_pos_offset", slam_pos, 0.11).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	t_slam.tween_property(self, "anim_rot_offset", slam_rot, 0.11).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	# Impacto pesado com rastro de lâmina mais largo e brilhante
	tween.tween_callback(func():
		if slash_trail and slash_trail.has_method("play_slash"):
			slash_trail.play_slash(0.28, get_trail_color().lightened(0.25), false, -90.0, 0.0)
		attack_hit_frame.emit(get_item_name())
	)

	# 3. Recuo físico acentuado (rebound do impacto)
	var rebound_pos = Vector3(0.0, -0.10, -0.06)
	var rebound_rot = Vector3(deg_to_rad(-22.0), 0.0, 0.0)
	var t_rebound = tween.parallel()
	t_rebound.tween_property(self, "anim_pos_offset", rebound_pos, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t_rebound.tween_property(self, "anim_rot_offset", rebound_rot, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 4. Recuperação mais longa com peso
	var t_recover = tween.parallel()
	t_recover.tween_property(self, "anim_pos_offset", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t_recover.tween_property(self, "anim_rot_offset", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		is_attacking = false
		attack_finished.emit(get_item_name())
	)

## Combo de socos para Fists (Jab Direito -> Gancho Esquerdo -> Uppercut Pesado)
func _play_fists_combo_animation(step: int) -> void:
	var tween: Tween = create_tween().set_parallel(false)

	match step:
		0: # Jab direito rápido
			AudioManager.play_sound("weapon_swing", 0.10, -1.0)
			var jab_pos = Vector3(0.06, 0.02, -0.25)
			var jab_rot = Vector3(deg_to_rad(-6.0), deg_to_rad(6.0), deg_to_rad(8.0))
			var t1 = tween.parallel()
			t1.tween_property(self, "anim_pos_offset", jab_pos, 0.07).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			t1.tween_property(self, "anim_rot_offset", jab_rot, 0.07).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			tween.tween_callback(func(): attack_hit_frame.emit("fists"))
			var t2 = tween.parallel()
			t2.tween_property(self, "anim_pos_offset", Vector3.ZERO, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			t2.tween_property(self, "anim_rot_offset", Vector3.ZERO, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		1: # Cruzado de esquerda
			AudioManager.play_sound("weapon_swing", 0.10, 1.0)
			var cross_pos = Vector3(-0.08, 0.02, -0.26)
			var cross_rot = Vector3(deg_to_rad(-8.0), deg_to_rad(-12.0), deg_to_rad(-12.0))
			var t1 = tween.parallel()
			t1.tween_property(self, "anim_pos_offset", cross_pos, 0.07).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			t1.tween_property(self, "anim_rot_offset", cross_rot, 0.07).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			tween.tween_callback(func(): attack_hit_frame.emit("fists"))
			var t2 = tween.parallel()
			t2.tween_property(self, "anim_pos_offset", Vector3.ZERO, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			t2.tween_property(self, "anim_rot_offset", Vector3.ZERO, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		2: # Uppercut Pesado de finalização
			AudioManager.play_sound("weapon_swing", 0.14, -3.0)
			var windup_pos = Vector3(0.0, -0.10, 0.05)
			tween.tween_property(self, "anim_pos_offset", windup_pos, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			var upper_pos = Vector3(0.04, 0.18, -0.30)
			var upper_rot = Vector3(deg_to_rad(30.0), deg_to_rad(8.0), deg_to_rad(-12.0))
			var t1 = tween.parallel()
			t1.tween_property(self, "anim_pos_offset", upper_pos, 0.09).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
			t1.tween_property(self, "anim_rot_offset", upper_rot, 0.09).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
			tween.tween_callback(func():
				if slash_trail and slash_trail.has_method("play_slash"):
					slash_trail.play_slash(0.18, Color(0.85, 0.95, 1.0), false, -75.0, 0.0)
				attack_hit_frame.emit("fists")
			)
			var t2 = tween.parallel()
			t2.tween_property(self, "anim_pos_offset", Vector3.ZERO, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			t2.tween_property(self, "anim_rot_offset", Vector3.ZERO, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		is_attacking = false
		attack_finished.emit("fists")
	)

func _play_eat_animation() -> void:
	var tween: Tween = create_tween().set_parallel(false)

	var mouth_pos = Vector3(-0.08, 0.16, -0.15)
	var mouth_rot = Vector3(deg_to_rad(30.0), deg_to_rad(-15.0), deg_to_rad(20.0))

	var t_raise = tween.parallel()
	t_raise.tween_property(self, "anim_pos_offset", mouth_pos, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t_raise.tween_property(self, "anim_rot_offset", mouth_rot, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		AudioManager.play_sound("eat_food", 0.05, 1.0)
	)
	var bite_bob = mouth_pos + Vector3(0.0, -0.03, -0.04)
	tween.tween_property(self, "anim_pos_offset", bite_bob, 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		attack_hit_frame.emit("food")
	)

	var t_lower = tween.parallel()
	t_lower.tween_property(self, "anim_pos_offset", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t_lower.tween_property(self, "anim_rot_offset", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		is_attacking = false
		attack_finished.emit("food")
	)
