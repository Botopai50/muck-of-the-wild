class_name EnemySpawner
extends Node3D

## Spawner Noturno de Monstros (Goblins e Mini-chefes Golems)
## Escala o número de monstros e tipos conforme os dias sobrevividos.

@export var goblin_scene: PackedScene
@export var golem_scene: PackedScene
@export var player: Node3D
@export var game_manager: GameManager

@export var base_goblins_per_night: int = 5
@export var min_spawn_radius: float = 16.0
@export var max_spawn_radius: float = 28.0

var goblins_remaining_to_spawn: int = 0
var golems_remaining_to_spawn: int = 0
var is_night_active: bool = false
var spawn_wave_timer: float = 0.0
var active_enemies: Array[Node3D] = []

func _ready() -> void:
	if not goblin_scene:
		goblin_scene = load("res://scenes/enemies/goblin.tscn")
	if not golem_scene:
		golem_scene = load("res://scenes/enemies/golem.tscn")

	if not game_manager:
		game_manager = get_tree().get_first_node_in_group("game_manager") as GameManager

	if game_manager:
		game_manager.night_started.connect(_on_night_started)
		game_manager.day_started.connect(_on_day_started)

func _physics_process(delta: float) -> void:
	if not is_night_active:
		return

	spawn_wave_timer -= delta
	if spawn_wave_timer <= 0.0:
		spawn_wave_timer = randf_range(6.0, 10.0)
		_spawn_next_wave()

func _on_night_started(day_num: int, diff_mult: float) -> void:
	is_night_active = true
	spawn_wave_timer = 2.5 # Primeiro spawn 2.5s apos o inicio da noite
	
	# Formula de escala por dia sobrevivido
	goblins_remaining_to_spawn = int(base_goblins_per_night * diff_mult) + (day_num - 1) * 3
	if game_manager:
		golems_remaining_to_spawn = game_manager.get_golem_spawn_count()
	else:
		golems_remaining_to_spawn = 0 if day_num <= 1 else 1

	print("[Spawner] Invasao Noturna iniciada! Goblins na fila: ", goblins_remaining_to_spawn, " | Golems: ", golems_remaining_to_spawn)

func _on_day_started(_day_num: int) -> void:
	is_night_active = false
	goblins_remaining_to_spawn = 0
	golems_remaining_to_spawn = 0
	print("[Spawner] O dia nasceu! Monstros remanescentes se dissipam com a luz do sol.")
	_clean_up_night_creatures()

func _clean_up_night_creatures() -> void:
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			if enemy.has_method("take_damage"):
				enemy.take_damage(9999.0, global_position)
	active_enemies.clear()

func _spawn_next_wave() -> void:
	if not player:
		_find_player()
	if not player:
		return

	# Priorizar Golem se houver pendente e se ja estivermos a meio caminho
	if golems_remaining_to_spawn > 0 and randf() < 0.45:
		_spawn_single_golem()
		golems_remaining_to_spawn -= 1
		return

	# Spawn de pequeno bando de goblins (1 a 3)
	if goblins_remaining_to_spawn > 0:
		var wave_size := clampi(randi_range(1, 3), 1, goblins_remaining_to_spawn)
		for i in range(wave_size):
			_spawn_single_goblin()
			goblins_remaining_to_spawn -= 1

func _spawn_single_goblin() -> void:
	if not goblin_scene:
		return
	var spawn_pos := _calculate_spawn_pos()
	var goblin := goblin_scene.instantiate() as Node3D
	get_parent().add_child(goblin)
	goblin.global_position = spawn_pos
	active_enemies.append(goblin)
	goblin.tree_exited.connect(func(): active_enemies.erase(goblin))
	print("[Spawner] Goblin invadiu em: ", spawn_pos)

func _spawn_single_golem() -> void:
	if not golem_scene:
		return
	var spawn_pos := _calculate_spawn_pos()
	var golem := golem_scene.instantiate() as Node3D
	get_parent().add_child(golem)
	golem.global_position = spawn_pos
	active_enemies.append(golem)
	golem.tree_exited.connect(func(): active_enemies.erase(golem))
	print("[Spawner] ALERTA DE CHEFE: Golem Ancestral emergiu em: ", spawn_pos)

func _calculate_spawn_pos() -> Vector3:
	var center := player.global_position if player else global_position
	var angle := randf_range(0.0, TAU)
	var dist := randf_range(min_spawn_radius, max_spawn_radius)
	var candidate := center + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	
	# Raycast para baixo para alinhar com o terreno
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(candidate + Vector3(0, 30.0, 0), candidate + Vector3(0, -30.0, 0), 1)
	var result := space_state.intersect_ray(query)
	if result:
		return result.position + Vector3(0, 0.1, 0)
	return candidate + Vector3(0, 0.5, 0)

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]