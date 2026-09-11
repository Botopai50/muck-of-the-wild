class_name PlayerViewmodel
extends Node3D

## Procedural Viewmodel Controller for Muck of the Wild
## Controls 1st-person arms, active hotbar item, weapon sway, bobbing, and procedural attack animations.

signal attack_hit_frame(item_type: String)
signal attack_finished(item_type: String)

enum ItemType {
	FISTS,
	AXE,
	PICKAXE,
	SWORD,
	FOOD
}

@export_group("Sway & Inertia")
@export var sway_amount_pos: float = 0.0008
@export var sway_amount_rot: float = 0.0012
@export var sway_smooth: float = 12.0
@export var sway_max_pos: float = 0.06
@export var sway_max_rot: float = 0.12

@export_group("Bobbing")
@export var bob_pos_multiplier: Vector3 = Vector3(0.015, 0.02, 0.0)
@export var bob_rot_multiplier: Vector3 = Vector3(0.03, 0.02, 0.04)

# Current item state
var current_item: ItemType = ItemType.FISTS
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var punch_alt: bool = false # toggles between left and right punch

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

# Node references
@onready var items_container: Node3D = $Items
@onready var fists_model: Node3D = $Items/Fists
@onready var axe_model: Node3D = $Items/Axe
@onready var pickaxe_model: Node3D = $Items/Pickaxe
@onready var sword_model: Node3D = $Items/Sword
@onready var food_model: Node3D = $Items/Food
@onready var right_arm: Node3D = $Arms/RightArm
@onready var left_arm: Node3D = $Arms/LeftArm

func _ready() -> void:
	rest_pos = position
	rest_rot = rotation
	set_item(ItemType.FISTS)

func _process(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown = maxf(0.0, attack_cooldown - delta)

	# Smoothly return sway to center
	target_sway_pos = target_sway_pos.lerp(Vector3.ZERO, delta * 6.0)
	target_sway_rot = target_sway_rot.lerp(Vector3.ZERO, delta * 6.0)

	current_sway_pos = current_sway_pos.lerp(target_sway_pos, delta * sway_smooth)
	current_sway_rot = current_sway_rot.lerp(target_sway_rot, delta * sway_smooth)

	# Apply combined transforms to viewmodel
	position = rest_pos + current_sway_pos + anim_pos_offset
	rotation = rest_rot + current_sway_rot + anim_rot_offset

## Called by PlayerController when mouse moves
func add_camera_sway(mouse_delta: Vector2) -> void:
	# Horizontal turn: sway X position and Y/Z rotation
	var pos_x = clampf(-mouse_delta.x * sway_amount_pos, -sway_max_pos, sway_max_pos)
	var pos_y = clampf(-mouse_delta.y * sway_amount_pos, -sway_max_pos, sway_max_pos)
	target_sway_pos += Vector3(pos_x, pos_y, 0.0)

	var rot_y = clampf(-mouse_delta.x * sway_amount_rot, -sway_max_rot, sway_max_rot)
	var rot_x = clampf(-mouse_delta.y * sway_amount_rot, -sway_max_rot, sway_max_rot)
	var rot_z = clampf(mouse_delta.x * (sway_amount_rot * 0.5), -sway_max_rot, sway_max_rot)
	target_sway_rot += Vector3(rot_x, rot_y, rot_z)

## Called by PlayerController during walking/sprinting
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

	current_sway_pos = current_sway_pos.lerp(bob_pos, 0.2)
	current_sway_rot = current_sway_rot.lerp(bob_rot, 0.2)

## Equips item by enum index
func set_item(type: ItemType) -> void:
	current_item = type
	fists_model.visible = (type == ItemType.FISTS)
	axe_model.visible = (type == ItemType.AXE)
	pickaxe_model.visible = (type == ItemType.PICKAXE)
	sword_model.visible = (type == ItemType.SWORD)
	food_model.visible = (type == ItemType.FOOD)

	# Left arm visibility: shown on fists, food, or idle
	left_arm.visible = (type == ItemType.FISTS or type == ItemType.FOOD)

func get_item_name() -> String:
	match current_item:
		ItemType.FISTS: return "fists"
		ItemType.AXE: return "axe"
		ItemType.PICKAXE: return "pickaxe"
		ItemType.SWORD: return "sword"
		ItemType.FOOD: return "food"
	return "fists"

func get_attack_cooldown_time() -> float:
	match current_item:
		ItemType.FISTS: return 0.25
		ItemType.SWORD: return 0.35
		ItemType.AXE: return 0.45
		ItemType.PICKAXE: return 0.50
		ItemType.FOOD: return 0.70
	return 0.35

func get_damage() -> float:
	match current_item:
		ItemType.FISTS: return 10.0
		ItemType.AXE: return 18.0
		ItemType.PICKAXE: return 15.0
		ItemType.SWORD: return 30.0
		ItemType.FOOD: return 0.0
	return 10.0

## Triggers attack/action if ready
func trigger_primary_action() -> bool:
	if is_attacking or attack_cooldown > 0.0:
		return false

	is_attacking = true
	attack_cooldown = get_attack_cooldown_time()

	match current_item:
		ItemType.FISTS:
			_play_punch_animation()
		ItemType.AXE, ItemType.PICKAXE, ItemType.SWORD:
			_play_swing_animation()
		ItemType.FOOD:
			_play_eat_animation()

	return true

# ---------------------------------------------------------
# Procedural Tween Animations
# ---------------------------------------------------------

func _play_swing_animation() -> void:
	AudioManager.play_sound("weapon_swing", 0.08, -1.0)
	var tween: Tween = create_tween()
	tween.set_parallel(false)

	# 1. Wind-up (pull back & raise weapon)
	var windup_pos = Vector3(0.06, 0.08, 0.05)
	var windup_rot = Vector3(deg_to_rad(25.0), deg_to_rad(-20.0), deg_to_rad(15.0))
	var t_windup = tween.parallel()
	t_windup.tween_property(self, "anim_pos_offset", windup_pos, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t_windup.tween_property(self, "anim_rot_offset", windup_rot, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Swift Slash forward & downward
	var slash_pos = Vector3(-0.16, -0.12, -0.18)
	var slash_rot = Vector3(deg_to_rad(-40.0), deg_to_rad(45.0), deg_to_rad(-35.0))
	var t_slash = tween.parallel()
	t_slash.tween_property(self, "anim_pos_offset", slash_pos, 0.11).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	t_slash.tween_property(self, "anim_rot_offset", slash_rot, 0.11).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	# Hit trigger callback at maximum velocity
	tween.tween_callback(func():
		attack_hit_frame.emit(get_item_name())
	)

	# 3. Recovery return to idle
	var t_recover = tween.parallel()
	t_recover.tween_property(self, "anim_pos_offset", Vector3.ZERO, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t_recover.tween_property(self, "anim_rot_offset", Vector3.ZERO, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		is_attacking = false
		attack_finished.emit(get_item_name())
	)

func _play_punch_animation() -> void:
	AudioManager.play_sound("weapon_swing", 0.12, -3.0)
	punch_alt = not punch_alt
	var tween: Tween = create_tween()
	tween.set_parallel(false)

	# Forward punch jab
	var forward_punch = Vector3(0.04 if punch_alt else -0.04, 0.02, -0.22)
	var punch_rot = Vector3(deg_to_rad(-8.0), deg_to_rad(5.0 if punch_alt else -5.0), deg_to_rad(10.0 if punch_alt else -10.0))

	var t_punch = tween.parallel()
	t_punch.tween_property(self, "anim_pos_offset", forward_punch, 0.08).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t_punch.tween_property(self, "anim_rot_offset", punch_rot, 0.08).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		attack_hit_frame.emit("fists")
	)

	# Quick retraction
	var t_retract = tween.parallel()
	t_retract.tween_property(self, "anim_pos_offset", Vector3.ZERO, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t_retract.tween_property(self, "anim_rot_offset", Vector3.ZERO, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_callback(func():
		is_attacking = false
		attack_finished.emit("fists")
	)

func _play_eat_animation() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(false)

	# 1. Bring food to mouth
	var mouth_pos = Vector3(-0.08, 0.16, -0.15)
	var mouth_rot = Vector3(deg_to_rad(30.0), deg_to_rad(-15.0), deg_to_rad(20.0))

	var t_raise = tween.parallel()
	t_raise.tween_property(self, "anim_pos_offset", mouth_pos, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t_raise.tween_property(self, "anim_rot_offset", mouth_rot, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 2. Bite munch sound & little bob
	tween.tween_callback(func():
		AudioManager.play_sound("eat_food", 0.05, 1.0)
	)
	var bite_bob = mouth_pos + Vector3(0.0, -0.03, -0.04)
	tween.tween_property(self, "anim_pos_offset", bite_bob, 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	# Hit frame (triggers food consumption in player)
	tween.tween_callback(func():
		attack_hit_frame.emit("food")
	)

	# 3. Lower arm back to rest
	var t_lower = tween.parallel()
	t_lower.tween_property(self, "anim_pos_offset", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t_lower.tween_property(self, "anim_rot_offset", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_callback(func():
		is_attacking = false
		attack_finished.emit("food")
	)
