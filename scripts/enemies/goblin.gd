class_name Goblin
extends CharacterBody3D

## Inimigo ágil e agressivo das noites de Muck
## Persegue o jogador, salta obstáculos e desfere golpes de clava

signal died(goblin)

enum State {
	IDLE,
	CHASE,
	ATTACK,
	HURT,
	DEAD
}

@export_group("Atributos")
@export var max_health: float = 65.0
@export var current_health: float = 65.0
@export var base_speed: float = 7.2
@export var sprint_speed: float = 9.0
@export var jump_velocity: float = 8.0
@export var attack_damage: float = 14.0
@export var attack_range: float = 2.2
@export var detection_range: float = 38.0

@onready var visual_root: Node3D = $Visuals
@onready var club_pivot: Node3D = $Visuals/Torso/ArmR/ClubPivot
@onready var arm_l: Node3D = $Visuals/Torso/ArmL
@onready var leg_l: Node3D = $Visuals/LegL
@onready var leg_r: Node3D = $Visuals/LegR
@onready var head: Node3D = $Visuals/Torso/Head
@onready var health_bar: ProgressBar = $SubViewport/ProgressBar

var current_state: State = State.CHASE
var target_player: Node3D = null
var gravity: float = 18.0
var knockback_velocity: Vector3 = Vector3.ZERO
var attack_timer: float = 0.0
var jump_cooldown: float = 0.0
var walk_cycle: float = 0.0
var is_attacking: bool = false
var original_materials: Array[Material] = []
var mesh_instances: Array[MeshInstance3D] = []

func _ready() -> void:
	add_to_group("enemies")
	_cache_meshes(visual_root)
	_find_player()
	
	# Escala de dificuldade baseada no GameManager se existir
	var gm := get_tree().get_first_node_in_group("game_manager") as GameManager
	if gm:
		var hp_mult := gm.get_enemy_health_multiplier()
		var dmg_mult := gm.get_enemy_damage_multiplier()
		max_health *= hp_mult
		current_health = max_health
		attack_damage *= dmg_mult
		
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func _cache_meshes(node: Node) -> void:
	var gob_mat = load("res://materials/m_botw_cel_goblin.tres")
	if node is MeshInstance3D:
		mesh_instances.append(node)
		if gob_mat and not node.name.begins_with("Eye"):
			node.set_surface_override_material(0, gob_mat)
		original_materials.append(node.get_active_material(0))
	for child in node.get_children():
		_cache_meshes(child)

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
		
	# Gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if knockback_velocity.y < 0.0:
			knockback_velocity.y = 0.0
			
	# Processamento de Recuo (Knockback)
	if knockback_velocity.length() > 0.1:
		velocity.x = knockback_velocity.x
		velocity.z = knockback_velocity.z
		if knockback_velocity.y > 0.0:
			velocity.y = knockback_velocity.y
			knockback_velocity.y -= gravity * delta
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, delta * 18.0)
	else:
		if not is_attacking and current_state != State.HURT:
			_process_behavior(delta)
			
	if attack_timer > 0.0:
		attack_timer -= delta
	if jump_cooldown > 0.0:
		jump_cooldown -= delta
		
	move_and_slide()
	_animate_procedural(delta)

func _process_behavior(delta: float) -> void:
	if not target_player or not is_instance_valid(target_player):
		_find_player()
		return
		
	var dist_to_player := global_position.distance_to(target_player.global_position)
	if dist_to_player > detection_range:
		current_state = State.IDLE
		velocity.x = move_toward(velocity.x, 0.0, delta * 5.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 5.0)
		return
		
	current_state = State.CHASE
	var dir := (target_player.global_position - global_position)
	dir.y = 0.0
	dir = dir.normalized()
	
	# Olhar para o jogador suavemente
	if dir.length_squared() > 0.001:
		var target_yaw := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 10.0)
		
	# Checagem de Ataque
	if dist_to_player <= attack_range:
		if attack_timer <= 0.0:
			_perform_attack()
		else:
			velocity.x = move_toward(velocity.x, 0.0, delta * 8.0)
			velocity.z = move_toward(velocity.z, 0.0, delta * 8.0)
		return
		
	# Salto agressivo de Muck para fechar distância ou transpor obstáculos
	if is_on_floor() and jump_cooldown <= 0.0:
		var should_jump := false
		if is_on_wall():
			should_jump = true
		elif dist_to_player > 4.5 and dist_to_player < 10.0 and randf() < 0.04:
			should_jump = true
			
		if should_jump:
			velocity.y = jump_velocity
			jump_cooldown = randf_range(2.0, 3.5)
			AudioSynth.play_sound(self, "jump", -4.0, 1.4)
			
	# Movimento de Perseguição
	var speed := sprint_speed if dist_to_player > 8.0 else base_speed
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

func _perform_attack() -> void:
	is_attacking = true
	attack_timer = 1.3
	velocity.x = 0.0
	velocity.z = 0.0
	
	# Áudio de guincho de ataque do goblin
	AudioSynth.play_sound(self, "goblin_screech", -2.0, randf_range(1.1, 1.3))
	
	# Animação de golpe com a clava
	var tween := create_tween()
	# Puxar braço para trás (windup)
	tween.tween_property(club_pivot, "rotation_degrees:x", -70.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Descer clava com força
	tween.tween_property(club_pivot, "rotation_degrees:x", 65.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		_execute_hit()
		AudioSynth.play_sound(self, "goblin_attack", 0.0, 1.2)
	)
	# Recuperação
	tween.tween_property(club_pivot, "rotation_degrees:x", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): is_attacking = false)

func _execute_hit() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
	if global_position.distance_to(target_player.global_position) <= attack_range + 0.8:
		if target_player.has_method("take_damage"):
			var knock_dir := (target_player.global_position - global_position).normalized()
			target_player.take_damage(attack_damage, knock_dir * 8.0)

func take_damage(amount: float, knockback_source = null, knockback_force: float = 8.5) -> void:
	if current_state == State.DEAD:
		return
		
	current_health -= amount
	AudioSynth.play_sound(self, "hit", 0.0, randf_range(1.2, 1.4))
	
	# Spawn de dano flutuante
	_spawn_damage_number(amount)
	
	# Atualizar barra de vida
	if health_bar:
		health_bar.value = current_health
		
	# Aplicar Knockback
	var source_pos: Vector3 = global_position - Vector3(0, 0, 1)
	if knockback_source is Vector3:
		source_pos = knockback_source
	elif knockback_source is Node3D:
		source_pos = knockback_source.global_position
		
	var k_dir := (global_position - source_pos)
	k_dir.y = 0.0
	if k_dir.length_squared() > 0.001:
		k_dir = k_dir.normalized()
	else:
		k_dir = -global_transform.basis.z
	knockback_velocity = k_dir * knockback_force + Vector3(0, 3.5, 0)
	
	# Efeito de Flash vermelho de dano
	_flash_red()
	
	if current_health <= 0.0:
		_die()
	else:
		current_state = State.HURT
		get_tree().create_timer(0.2).timeout.connect(func():
			if current_state == State.HURT:
				current_state = State.CHASE
		)

func _flash_red() -> void:
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.1, 0.1)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(0.9, 0.1, 0.1)
	flash_mat.emission_energy_multiplier = 1.0
	
	for m in mesh_instances:
		m.material_override = flash_mat
		
	get_tree().create_timer(0.12).timeout.connect(func():
		for m in mesh_instances:
			m.material_override = null
	)

func _spawn_damage_number(amount: float) -> void:
	var ft_scene = load("res://scenes/ui/floating_text.tscn")
	if ft_scene:
		var ft = ft_scene.instantiate()
		get_parent().add_child(ft)
		ft.global_position = global_position + Vector3(0, 1.8, 0)
		ft.setup(str(int(amount)), Color(1.0, 0.9, 0.2))

func _die() -> void:
	current_state = State.DEAD
	emit_signal("died", self)
	collision_layer = 0
	collision_mask = 1
	
	AudioSynth.play_sound(self, "goblin_screech", 1.0, 0.7)
	_drop_loot()
	
	# Animação de queda e desintegração
	var tween := create_tween().set_parallel(true)
	tween.tween_property(visual_root, "rotation_degrees:x", -90.0, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_root, "scale", Vector3.ZERO, 0.35).set_delay(0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)

func _drop_loot() -> void:
	var drop_scene = load("res://scenes/items/drop_item.tscn")
	if not drop_scene:
		return
		
	# Moedas: 2 a 5
	var coins := randi_range(2, 5)
	for i in range(coins):
		var d = drop_scene.instantiate()
		get_parent().add_child(d)
		d.global_position = global_position + Vector3(0, 0.8, 0)
		d.setup(DropItem.ItemType.COIN, 1)
		
	# Comida (Carne ou Maca)
	var food = drop_scene.instantiate()
	get_parent().add_child(food)
	food.global_position = global_position + Vector3(0, 0.8, 0)
	var f_type := DropItem.ItemType.MEAT if randf() < 0.6 else DropItem.ItemType.APPLE
	food.setup(f_type, 1)
	
	# Recursos (Madeira ou Minerio de Ferro)
	if randf() < 0.7:
		var res = drop_scene.instantiate()
		get_parent().add_child(res)
		res.global_position = global_position + Vector3(0, 0.8, 0)
		var r_type := DropItem.ItemType.IRON_ORE if randf() < 0.4 else DropItem.ItemType.WOOD
		res.setup(r_type, randi_range(1, 2))

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]

func _animate_procedural(delta: float) -> void:
	var h_speed := Vector2(velocity.x, velocity.z).length()
	if h_speed > 0.5 and is_on_floor() and not is_attacking:
		walk_cycle += delta * h_speed * 2.2
		leg_l.rotation_degrees.x = sin(walk_cycle) * 35.0
		leg_r.rotation_degrees.x = -sin(walk_cycle) * 35.0
		arm_l.rotation_degrees.x = -sin(walk_cycle) * 30.0
		if not is_attacking:
			club_pivot.rotation_degrees.x = sin(walk_cycle) * 20.0
		visual_root.position.y = abs(sin(walk_cycle * 2.0)) * 0.12
	elif is_on_floor():
		leg_l.rotation_degrees.x = move_toward(leg_l.rotation_degrees.x, 0.0, delta * 120.0)
		leg_r.rotation_degrees.x = move_toward(leg_r.rotation_degrees.x, 0.0, delta * 120.0)
		arm_l.rotation_degrees.x = move_toward(arm_l.rotation_degrees.x, 0.0, delta * 120.0)
		if not is_attacking:
			club_pivot.rotation_degrees.x = move_toward(club_pivot.rotation_degrees.x, 0.0, delta * 120.0)
		visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 2.0)
	else:
		# Pose de salto
		leg_l.rotation_degrees.x = 25.0
		leg_r.rotation_degrees.x = -20.0
		arm_l.rotation_degrees.x = -45.0
