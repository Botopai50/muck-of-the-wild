class_name Golem
extends CharacterBody3D

## Mini-chefe noturno de Muck: Golem colossal de pedra ancestral
## Executa passos pesados, golpe esmagador com onda de choque e arremesso de pedras

signal died(golem)

enum State {
	IDLE,
	CHASE,
	SLAM_WINDUP,
	SLAM_EXECUTE,
	THROW_WINDUP,
	THROW_EXECUTE,
	HURT,
	DEAD
}

@export_group("Atributos de Chefe")
@export var max_health: float = 450.0
@export var current_health: float = 450.0
@export var move_speed: float = 3.8
@export var slam_damage: float = 45.0
@export var throw_damage: float = 32.0
@export var detection_range: float = 45.0

@onready var visual_root: Node3D = $Visuals
@onready var torso: Node3D = $Visuals/Torso
@onready var arm_l: Node3D = $Visuals/Torso/ArmL
@onready var arm_r: Node3D = $Visuals/Torso/ArmR
@onready var leg_l: Node3D = $Visuals/LegL
@onready var leg_r: Node3D = $Visuals/LegR
@onready var head: Node3D = $Visuals/Torso/Head
@onready var eye_light: OmniLight3D = $Visuals/Torso/Head/EyeLight
@onready var health_bar: ProgressBar = $SubViewport/ProgressBar

var current_state: State = State.CHASE
var target_player: Node3D = null
var gravity: float = 22.0
var knockback_velocity: Vector3 = Vector3.ZERO

var slam_cooldown: float = 2.0
var throw_cooldown: float = 4.0
var step_timer: float = 0.0
var walk_phase: float = 0.0
var is_acting: bool = false
var mesh_instances: Array[MeshInstance3D] = []

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	_cache_meshes(visual_root)
	_find_player()
	
	var gm := get_tree().get_first_node_in_group("game_manager") as GameManager
	if gm:
		var hp_mult := gm.get_enemy_health_multiplier() * 1.2
		var dmg_mult := gm.get_enemy_damage_multiplier() * 1.15
		max_health *= hp_mult
		current_health = max_health
		slam_damage *= dmg_mult
		throw_damage *= dmg_mult
		
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func _cache_meshes(node: Node) -> void:
	var rock_mat = load("res://materials/m_botw_cel_rock.tres")
	if node is MeshInstance3D:
		mesh_instances.append(node)
		if rock_mat and not node.name.begins_with("Eye"):
			node.set_surface_override_material(0, rock_mat)
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
			
	# Processar knockback reduzido (resiste 90% do recuo)
	if knockback_velocity.length() > 0.1:
		velocity.x = knockback_velocity.x
		velocity.z = knockback_velocity.z
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, delta * 25.0)
	else:
		if not is_acting:
			_process_boss_ai(delta)
			
	if slam_cooldown > 0.0:
		slam_cooldown -= delta
	if throw_cooldown > 0.0:
		throw_cooldown -= delta
		
	move_and_slide()
	_animate_boss(delta)

func _process_boss_ai(delta: float) -> void:
	if not target_player or not is_instance_valid(target_player):
		_find_player()
		return
		
	var dist := global_position.distance_to(target_player.global_position)
	if dist > detection_range:
		current_state = State.IDLE
		velocity.x = move_toward(velocity.x, 0.0, delta * 4.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 4.0)
		return
		
	current_state = State.CHASE
	var dir := (target_player.global_position - global_position)
	dir.y = 0.0
	dir = dir.normalized()
	
	if dir.length_squared() > 0.001:
		var target_yaw := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, delta * 4.5)
		
	# Decisão de Habilidade: Golpe Esmagador corpo a corpo
	if dist <= 6.2 and slam_cooldown <= 0.0:
		_perform_ground_slam()
		return
		
	# Decisão de Habilidade: Arremesso de Pedra à distância
	if dist > 7.5 and dist < 28.0 and throw_cooldown <= 0.0 and randf() < 0.35:
		_perform_rock_throw()
		return
		
	# Movimento pesado em direção ao jogador
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	
	# Passos sonoros e tremor de tela
	step_timer += delta
	if step_timer >= 0.75:
		step_timer = 0.0
		_trigger_footstep()

func _trigger_footstep() -> void:
	AudioSynth.play_sound(self, "golem_step", 3.0, randf_range(0.85, 1.05))
	if target_player and is_instance_valid(target_player):
		var dist := global_position.distance_to(target_player.global_position)
		if dist < 16.0 and target_player.has_method("apply_camera_shake"):
			var intensity := (1.0 - dist / 16.0) * 0.4
			target_player.apply_camera_shake(intensity, 0.25)

## 1. Golpe Esmagador no Chão gerando Onda de Choque
func _perform_ground_slam() -> void:
	is_acting = true
	current_state = State.SLAM_WINDUP
	velocity.x = 0.0
	velocity.z = 0.0
	slam_cooldown = randf_range(4.5, 6.0)
	
	var tween := create_tween()
	# Levantar ambos os punhos colossais no ar
	tween.tween_property(arm_l, "rotation_degrees:x", -110.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(arm_r, "rotation_degrees:x", -110.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(torso, "position:y", 1.9, 0.7)
	
	# Pausa de suspense no topo
	tween.tween_interval(0.2)
	
	# Esmagar com violência no chão!
	tween.tween_callback(func(): current_state = State.SLAM_EXECUTE)
	tween.tween_property(arm_l, "rotation_degrees:x", 70.0, 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(arm_r, "rotation_degrees:x", 70.0, 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(torso, "position:y", 1.3, 0.16)
	
	# Impacto no chão: som estrondoso, tremor violento e onda de choque!
	tween.tween_callback(func():
		_execute_ground_slam_impact()
	)
	
	# Recuperação
	tween.tween_interval(0.5)
	tween.tween_property(arm_l, "rotation_degrees:x", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(arm_r, "rotation_degrees:x", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(torso, "position:y", 1.6, 0.4)
	tween.tween_callback(func():
		is_acting = false
		current_state = State.CHASE
	)

func _execute_ground_slam_impact() -> void:
	AudioSynth.play_sound(self, "golem_slam", 6.0, 0.8)
	
	if target_player and is_instance_valid(target_player):
		var dist := global_position.distance_to(target_player.global_position)
		if target_player.has_method("apply_camera_shake"):
			target_player.apply_camera_shake(1.0, 0.6)
			
	# Spawnar a Onda de Choque
	var sw_scene = load("res://scenes/enemies/shockwave.tscn")
	if sw_scene:
		var sw = sw_scene.instantiate()
		get_parent().add_child(sw)
		var impact_pos := global_position + (-global_transform.basis.z * 1.8)
		impact_pos.y = global_position.y + 0.1
		sw.global_position = impact_pos
		sw.damage = slam_damage

## 2. Arremesso de Pedra à distância
func _perform_rock_throw() -> void:
	is_acting = true
	current_state = State.THROW_WINDUP
	velocity.x = 0.0
	velocity.z = 0.0
	throw_cooldown = randf_range(5.0, 7.5)
	
	var tween := create_tween()
	# Abaixar braço direito até o chão para arrancar pedra
	tween.tween_property(arm_r, "rotation_degrees:x", 85.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(torso, "rotation_degrees:x", 15.0, 0.5)
	
	# Arrancar do solo
	tween.tween_callback(func():
		AudioSynth.play_sound(self, "rock_break", 1.0, 0.8)
	)
	
	# Puxar braço lá atrás preparando arremesso
	tween.tween_property(arm_r, "rotation_degrees:x", -120.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(torso, "rotation_degrees:x", -10.0, 0.45)
	
	# Arremessar pedra com força para frente
	tween.tween_callback(func(): current_state = State.THROW_EXECUTE)
	tween.tween_property(arm_r, "rotation_degrees:x", 45.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(torso, "rotation_degrees:x", 5.0, 0.18)
	
	tween.tween_callback(func():
		_execute_rock_projectile()
	)
	
	# Retorno à postura normal
	tween.tween_interval(0.3)
	tween.tween_property(arm_r, "rotation_degrees:x", 0.0, 0.35)
	tween.parallel().tween_property(torso, "rotation_degrees:x", 0.0, 0.35)
	tween.tween_callback(func():
		is_acting = false
		current_state = State.CHASE
	)

func _execute_rock_projectile() -> void:
	if not target_player or not is_instance_valid(target_player):
		return
		
	var boulder_scene = load("res://scenes/enemies/boulder.tscn")
	if boulder_scene:
		var b = boulder_scene.instantiate()
		get_parent().add_child(b)
		var spawn_pos := global_position + (-global_transform.basis.z * 2.0) + Vector3(0, 2.8, 0)
		var target_pos := target_player.global_position + Vector3(0, 1.0, 0)
		b.damage = throw_damage
		b.launch(spawn_pos, target_pos)

func take_damage(amount: float, knockback_source = null, knockback_force: float = 6.0) -> void:
	if current_state == State.DEAD:
		return
		
	current_health -= amount
	AudioSynth.play_sound(self, "hit", 1.0, randf_range(0.75, 0.95))
	
	_spawn_damage_number(amount)
	
	if health_bar:
		health_bar.value = current_health
		
	# Golem tem alta resistência a knockback (apenas 10% do impacto recebido)
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
	knockback_velocity = k_dir * (knockback_force * 0.12)
	
	_flash_rock()
	
	if current_health <= 0.0:
		_die()

func _flash_rock() -> void:
	var flash_mat := StandardMaterial3D.new()
	flash_mat.albedo_color = Color(1.0, 0.3, 0.3)
	flash_mat.emission_enabled = true
	flash_mat.emission = Color(0.9, 0.2, 0.1)
	flash_mat.emission_energy_multiplier = 0.8
	
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
		ft.global_position = global_position + Vector3(0, 4.0, 0)
		ft.setup(str(int(amount)), Color(1.0, 0.65, 0.1), true)

func _die() -> void:
	current_state = State.DEAD
	emit_signal("died", self)
	collision_layer = 0
	collision_mask = 1
	
	AudioSynth.play_sound(self, "golem_slam", 8.0, 0.6)
	_drop_boss_treasures()
	
	# Animação de desmoronamento do golem
	var tween := create_tween().set_parallel(true)
	tween.tween_property(visual_root, "position:y", -2.0, 1.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_root, "rotation_degrees:z", 35.0, 1.2)
	tween.tween_property(visual_root, "scale", Vector3.ZERO, 0.5).set_delay(1.5)
	tween.chain().tween_callback(queue_free)

func _drop_boss_treasures() -> void:
	var drop_scene = load("res://scenes/items/drop_item.tscn")
	if not drop_scene:
		return
		
	# Chuva de moedas douradas (15 a 30)
	var coins := randi_range(15, 30)
	for i in range(coins):
		var d = drop_scene.instantiate()
		get_parent().add_child(d)
		d.global_position = global_position + Vector3(randf_range(-1.0, 1.0), 1.5, randf_range(-1.0, 1.0))
		d.setup(DropItem.ItemType.COIN, 1)
		
	# Gemas raras: Rubis e Diamantes!
	var rubies := randi_range(2, 4)
	for i in range(rubies):
		var d = drop_scene.instantiate()
		get_parent().add_child(d)
		d.global_position = global_position + Vector3(randf_range(-1.5, 1.5), 2.0, randf_range(-1.5, 1.5))
		d.setup(DropItem.ItemType.RUBY, 1)
		
	var diamonds := randi_range(1, 2)
	for i in range(diamonds):
		var d = drop_scene.instantiate()
		get_parent().add_child(d)
		d.global_position = global_position + Vector3(randf_range(-1.5, 1.5), 2.2, randf_range(-1.5, 1.5))
		d.setup(DropItem.ItemType.DIAMOND, 1)
		
	# Minérios de Ferro de alta qualidade
	for i in range(4):
		var d = drop_scene.instantiate()
		get_parent().add_child(d)
		d.global_position = global_position + Vector3(randf_range(-1.0, 1.0), 1.8, randf_range(-1.0, 1.0))
		d.setup(DropItem.ItemType.IRON_ORE, randi_range(2, 3))
		
	# E como recompensa máxima de chefe: Gera um Baú de Relíquia no local!
	var chest_scene = load("res://scenes/environment/chest.tscn")
	if chest_scene:
		var chest = chest_scene.instantiate()
		get_parent().add_child(chest)
		chest.global_position = global_position + Vector3(0, 0.2, 0)
		print("[Golem] Derrotado! Um Baú de Relíquia emergiu dos escombros!")

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]

func _animate_boss(delta: float) -> void:
	var h_speed := Vector2(velocity.x, velocity.z).length()
	if h_speed > 0.3 and is_on_floor() and not is_acting:
		walk_phase += delta * 3.5
		leg_l.rotation_degrees.x = sin(walk_phase) * 25.0
		leg_r.rotation_degrees.x = -sin(walk_phase) * 25.0
		arm_l.rotation_degrees.x = -sin(walk_phase) * 22.0
		arm_r.rotation_degrees.x = sin(walk_phase) * 22.0
		torso.rotation_degrees.z = sin(walk_phase) * 3.5
		visual_root.position.y = abs(sin(walk_phase)) * 0.15
	elif not is_acting and is_on_floor():
		leg_l.rotation_degrees.x = move_toward(leg_l.rotation_degrees.x, 0.0, delta * 60.0)
		leg_r.rotation_degrees.x = move_toward(leg_r.rotation_degrees.x, 0.0, delta * 60.0)
		arm_l.rotation_degrees.x = move_toward(arm_l.rotation_degrees.x, 0.0, delta * 60.0)
		arm_r.rotation_degrees.x = move_toward(arm_r.rotation_degrees.x, 0.0, delta * 60.0)
		torso.rotation_degrees.z = move_toward(torso.rotation_degrees.z, 0.0, delta * 20.0)
		visual_root.position.y = move_toward(visual_root.position.y, 0.0, delta * 1.5)
