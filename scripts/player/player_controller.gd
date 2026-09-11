class_name PlayerController
extends CharacterBody3D

## PlayerController: First-Person Controller for Muck of the Wild
## Handles full FPS movement, smooth sprint acceleration/deceleration,
## realistic gravity, double jump with Feather relic, mouse look with clamp,
## vital stats (Health, Stamina, Hunger), strafe tilt, and dynamic headbob.

signal health_changed(current: float, max_val: float)
signal stamina_changed(current: float, max_val: float)
signal hunger_changed(current: float, max_val: float)
signal hotbar_slot_changed(slot_index: int, item_name: String)
signal player_damaged(amount: float)
signal player_died()
signal relic_obtained(relic_data: Dictionary)

@export_group("Movement Speeds")
@export var walk_speed: float = 5.5
@export var sprint_speed: float = 9.2
@export var acceleration: float = 12.0
@export var deceleration: float = 14.0
@export var air_control_accel: float = 4.0

@export_group("Jumping & Gravity")
@export var jump_velocity: float = 7.0
@export var double_jump_velocity: float = 6.6
@export var gravity_multiplier: float = 2.0
@export var max_air_jumps: int = 0 ## Increased by Feather relics

@export_group("Mouse Look")
@export var mouse_sensitivity: float = 0.0022
@export var pitch_limit_deg: float = 89.0

@export_group("Game Feel - Strafe Tilt & Headbob")
@export var strafe_tilt_deg: float = 2.2
@export var tilt_speed: float = 8.0
@export var bob_frequency_walk: float = 10.0
@export var bob_frequency_sprint: float = 14.0
@export var bob_amplitude_y: float = 0.05
@export var bob_amplitude_x: float = 0.035

@export_group("Vital Stats")
@export var max_health: float = 100.0
@export var max_stamina: float = 100.0
@export var max_hunger: float = 100.0
@export var stamina_regen_rate: float = 22.0
@export var stamina_sprint_cost: float = 14.0
@export var stamina_jump_cost: float = 12.0
@export var stamina_double_jump_cost: float = 15.0
@export var stamina_regen_delay: float = 0.8
@export var hunger_drain_rate: float = 0.28
@export var hunger_sprint_drain_rate: float = 0.65

# Relics
# Relics & Stats
var relics: Dictionary = {}
var has_feather_relic: bool = false:
	get: return relics.get("feather", 0) > 0
var damage_bonus: float = 0.0
var defense_reduction: float = 0.0
var luck_multiplier: float = 1.0
var coins: int = 0
var shake_intensity: float = 0.0
var shake_timer: float = 0.0

# Runtime state
var health: float = 100.0
var stamina: float = 100.0
var hunger: float = 100.0
var stamina_timer: float = 0.0
var starvation_timer: float = 0.0
var natural_regen_timer: float = 0.0

var air_jumps_left: int = 0
var is_sprinting: bool = false
var current_speed: float = 0.0
var bob_cycle: float = 0.0
var has_stepped_this_cycle: bool = false

# Mouse state
var is_mouse_captured: bool = true

# Hotbar & inventory
var active_slot: int = 0
const HOTBAR_ITEMS: Array[String] = ["fists", "axe", "pickaxe", "sword", "food"]

# Node references
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interaction_ray: InteractionRay = $Head/Camera3D/InteractionRay
@onready var viewmodel: PlayerViewmodel = $Head/Camera3D/ViewmodelAnchor/Viewmodel
@onready var cam_default_pos: Vector3 = camera.position

# Fallback gravity
var gravity: float = 9.8

func _ready() -> void:
	health = max_health
	stamina = max_stamina
	hunger = max_hunger

	gravity = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8) * gravity_multiplier
	_capture_mouse()

	if viewmodel:
		viewmodel.attack_hit_frame.connect(_on_viewmodel_hit_frame)

	if interaction_ray:
		interaction_ray.player_reference = self

	# Emit initial vital signals
	health_changed.emit(health, max_health)
	stamina_changed.emit(stamina, max_stamina)
	hunger_changed.emit(hunger, max_hunger)
	hotbar_slot_changed.emit(active_slot, HOTBAR_ITEMS[active_slot])

func _input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion and is_mouse_captured:
		_handle_mouse_look(event.relative)

	# Mouse capture toggles
	if event.is_action_pressed("pause"):
		_release_mouse()
	elif event is InputEventMouseButton and event.pressed and not is_mouse_captured:
		_capture_mouse()

	# Hotbar slot selection
	if event.is_action_pressed("hotbar_1"): _select_slot(0)
	elif event.is_action_pressed("hotbar_2"): _select_slot(1)
	elif event.is_action_pressed("hotbar_3"): _select_slot(2)
	elif event.is_action_pressed("hotbar_4"): _select_slot(3)
	elif event.is_action_pressed("hotbar_5"): _select_slot(4)

	# Mouse wheel hotbar scroll
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_select_slot((active_slot - 1 + 5) % 5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_select_slot((active_slot + 1) % 5)

	# Interaction with 'E'
	if event.is_action_pressed("interact") and is_mouse_captured:
		if interaction_ray:
			interaction_ray.interact()

	# Attack / Primary action with left mouse click
	if event.is_action_pressed("attack") and is_mouse_captured:
		if viewmodel:
			viewmodel.trigger_primary_action()

func _physics_process(delta: float) -> void:
	_update_vitals(delta)
	_handle_movement(delta)
	_apply_game_feel(delta)

# ---------------------------------------------------------
# Mouse Look & Capture
# ---------------------------------------------------------

func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_mouse_captured = true

func _release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	is_mouse_captured = false

func _handle_mouse_look(relative: Vector2) -> void:
	# Yaw on player body
	rotate_y(-relative.x * mouse_sensitivity)

	# Pitch on head node, clamped to [-pitch_limit, +pitch_limit]
	head.rotation.x = clampf(
		head.rotation.x - relative.y * mouse_sensitivity,
		-deg_to_rad(pitch_limit_deg),
		deg_to_rad(pitch_limit_deg)
	)

	# Pass sway delta to procedural viewmodel
	if viewmodel:
		viewmodel.add_camera_sway(relative)

# ---------------------------------------------------------
# Movement & Physics
# ---------------------------------------------------------

func _handle_movement(delta: float) -> void:
	# Reset air jumps when grounded
	if is_on_floor():
		air_jumps_left = max_air_jumps + (1 if has_feather_relic else 0)
	else:
		# Apply gravity
		velocity.y -= gravity * delta

	# Sprint input check
	var wants_sprint: bool = Input.is_action_pressed("sprint")
	var has_sprint_stamina: bool = stamina > 2.0
	is_sprinting = wants_sprint and has_sprint_stamina and is_on_floor()

	# Target ground speed
	var target_speed: float = sprint_speed if is_sprinting else walk_speed

	# Input direction from WASD
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()

	# Jumping logic
	if Input.is_action_just_pressed("jump"):
		_try_jump()

	# Horizontal acceleration / deceleration
	var current_h_vel := Vector3(velocity.x, 0, velocity.z)
	var target_h_vel := direction * target_speed

	var accel_rate := acceleration if direction.length_squared() > 0.0 else deceleration
	if not is_on_floor():
		accel_rate = air_control_accel

	current_h_vel = current_h_vel.lerp(target_h_vel, accel_rate * delta)
	velocity.x = current_h_vel.x
	velocity.z = current_h_vel.z

	current_speed = current_h_vel.length()
	move_and_slide()

func _try_jump() -> void:
	if is_on_floor():
		# Ground Jump
		velocity.y = jump_velocity
		stamina = maxf(0.0, stamina - stamina_jump_cost)
		stamina_timer = stamina_regen_delay
		stamina_changed.emit(stamina, max_stamina)
		AudioManager.play_sound("jump", 0.05, 0.0)
	elif air_jumps_left > 0:
		# Double Jump (granted by Feather relic)
		air_jumps_left -= 1
		velocity.y = double_jump_velocity
		stamina = maxf(0.0, stamina - stamina_double_jump_cost)
		stamina_timer = stamina_regen_delay
		stamina_changed.emit(stamina, max_stamina)
		# Higher pitched airy jump sound for feather relic
		AudioManager.play_sound("jump", 0.08, 2.0)

# ---------------------------------------------------------
# Vital Stats Management
# ---------------------------------------------------------

func _update_vitals(delta: float) -> void:
	# Stamina consumption while sprinting
	if is_sprinting and current_speed > 1.0:
		stamina = maxf(0.0, stamina - stamina_sprint_cost * delta)
		stamina_timer = stamina_regen_delay
		stamina_changed.emit(stamina, max_stamina)
	else:
		# Stamina recovery after delay
		if stamina_timer > 0.0:
			stamina_timer -= delta
		elif stamina < max_stamina:
			stamina = minf(max_stamina, stamina + stamina_regen_rate * delta)
			stamina_changed.emit(stamina, max_stamina)

	# Hunger drain
	var current_hunger_drain = hunger_drain_rate
	if is_sprinting and current_speed > 1.0:
		current_hunger_drain += hunger_sprint_drain_rate

	if hunger > 0.0:
		hunger = maxf(0.0, hunger - current_hunger_drain * delta)
		hunger_changed.emit(hunger, max_hunger)

	# Starvation damage when hunger is empty
	if hunger <= 0.0:
		starvation_timer += delta
		if starvation_timer >= 2.0:
			starvation_timer = 0.0
			take_damage(4.0, "starvation")
	else:
		starvation_timer = 0.0

	# Natural health regeneration when well-fed (hunger > 80% and stamina == max)
	if hunger >= 80.0 and stamina >= max_stamina and health < max_health:
		natural_regen_timer += delta
		if natural_regen_timer >= 1.0:
			natural_regen_timer = 0.0
			heal(2.0)
	else:
		natural_regen_timer = 0.0

func take_damage(amount: float, source_or_knockback = null) -> void:
	var final_dmg := amount * (1.0 - defense_reduction)
	health = maxf(0.0, health - final_dmg)
	health_changed.emit(health, max_health)
	player_damaged.emit(final_dmg)
	AudioManager.play_sound("damage", 0.08, 2.0)

	if source_or_knockback is Vector3:
		velocity += source_or_knockback

	# Camera jolt on hit
	if camera:
		var punch := Vector3(randf_range(-0.06, 0.06), randf_range(-0.04, 0.04), 0.0)
		camera.position += punch

	if health <= 0.0:
		player_died.emit()

func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)

func consume_food(nutrition: float) -> void:
	hunger = minf(max_hunger, hunger + nutrition)
	hunger_changed.emit(hunger, max_hunger)
	heal(nutrition * 0.4)

func apply_camera_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_timer = duration

# ---------------------------------------------------------
# Relics System
# ---------------------------------------------------------

func grant_relic(relic: Dictionary) -> void:
	var relic_id: String = relic.get("id", "")
	relics[relic_id] = relics.get(relic_id, 0) + 1
	var stat = relic.get("stat", "")
	var val = relic.get("value", 0.0)
	match stat:
		"speed_mult":
			walk_speed *= (1.0 + float(val))
			sprint_speed *= (1.0 + float(val))
		"max_hp":
			max_health += float(val)
			health = max_health
			health_changed.emit(health, max_health)
		"damage_bonus":
			damage_bonus += float(val)
		"double_jump":
			max_air_jumps += int(val)
		"defense_mult":
			defense_reduction = minf(0.70, defense_reduction + float(val))
		"luck_mult":
			luck_multiplier += float(val)
	relic_obtained.emit(relic)

func add_item_drop(item_type: int, amount: int) -> void:
	if item_type == 0: # DropItem.ItemType.COIN
		coins += int(amount * luck_multiplier)
	elif item_type == 1 or item_type == 2: # MEAT or APPLE
		consume_food(25.0 * amount)

func add_relic(relic_id: String, amount: int = 1) -> void:
	relics[relic_id] = relics.get(relic_id, 0) + amount
	if relic_id == "feather":
		max_air_jumps = relics["feather"]

func get_relic_count(relic_id: String) -> int:
	return relics.get(relic_id, 0)

# ---------------------------------------------------------
# Game Feel: Strafe Tilt & Dynamic Headbob
# ---------------------------------------------------------

func _apply_game_feel(delta: float) -> void:
	if not camera:
		return

	# 1. Strafe Tilt: roll camera smoothly when moving sideways
	var raw_x: float = Input.get_axis("move_left", "move_right")
	var target_roll: float = -raw_x * deg_to_rad(strafe_tilt_deg)
	camera.rotation.z = lerpf(camera.rotation.z, target_roll, delta * tilt_speed)

	# 2. Dynamic Headbob
	if is_on_floor() and current_speed > 0.5:
		var bob_freq: float = bob_frequency_sprint if is_sprinting else bob_frequency_walk
		bob_cycle += delta * (current_speed / walk_speed) * bob_freq

		var bob_sin: float = sin(bob_cycle)
		var bob_cos: float = cos(bob_cycle * 0.5)

		var target_y: float = cam_default_pos.y + (bob_sin * bob_amplitude_y * (current_speed / sprint_speed))
		var target_x: float = cam_default_pos.x + (bob_cos * bob_amplitude_x * (current_speed / sprint_speed))
		camera.position.y = lerpf(camera.position.y, target_y, delta * 18.0)
		camera.position.x = lerpf(camera.position.x, target_x, delta * 18.0)

		# Footstep sound trigger on bob trough
		if bob_sin < -0.85:
			if not has_stepped_this_cycle:
				has_stepped_this_cycle = true
				AudioManager.play_sound("footstep_grass", 0.08, -3.0)
		else:
			has_stepped_this_cycle = false

		# Feed inertia bob to viewmodel
		if viewmodel:
			viewmodel.apply_movement_bob(bob_cycle, current_speed / walk_speed)
	else:
		# Smoothly reset camera bob to rest position
		camera.position = camera.position.lerp(cam_default_pos, delta * 10.0)
		bob_cycle = 0.0
		has_stepped_this_cycle = false

	# 3. Dynamic Camera Shake (Golem steps, shockwaves, slams)
	if shake_timer > 0.0:
		shake_timer -= delta
		var offset := Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * shake_intensity * 0.08
		camera.position += offset

# ---------------------------------------------------------
# Hotbar & Viewmodel Interaction
# ---------------------------------------------------------

func _select_slot(index: int) -> void:
	if index < 0 or index >= HOTBAR_ITEMS.size():
		return
	active_slot = index
	var item_name: String = HOTBAR_ITEMS[active_slot]
	hotbar_slot_changed.emit(active_slot, item_name)

	if viewmodel:
		match item_name:
			"fists": viewmodel.set_item(PlayerViewmodel.ItemType.FISTS)
			"axe": viewmodel.set_item(PlayerViewmodel.ItemType.AXE)
			"pickaxe": viewmodel.set_item(PlayerViewmodel.ItemType.PICKAXE)
			"sword": viewmodel.set_item(PlayerViewmodel.ItemType.SWORD)
			"food": viewmodel.set_item(PlayerViewmodel.ItemType.FOOD)

func _on_viewmodel_hit_frame(item_type: String) -> void:
	if item_type == "food":
		consume_food(28.0)
		return

	if interaction_ray:
		var dmg: float = viewmodel.get_damage() if viewmodel else 10.0
		interaction_ray.apply_strike(item_type, dmg)