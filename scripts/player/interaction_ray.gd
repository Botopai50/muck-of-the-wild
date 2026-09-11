class_name InteractionRay
extends RayCast3D

## Raycast centralizado para detectar objetos interativos a até 3.5 metros.
## Detecta: arvores (madeira), pedras (mineracao), itens de chao (coleta com E),
## baus (abrir) e bancadas de trabalho (workbench).

signal prompt_changed(prompt_text: String)
signal interacted(target: Node3D, type: String)
signal hit_applied(target: Node3D, type: String, damage: float, hit_point: Vector3, hit_normal: Vector3)

@export var max_interaction_distance: float = 3.5
@export var player_reference: CharacterBody3D

var current_target: Node3D = null
var current_type: String = ""
var current_prompt: String = ""

func _ready() -> void:
	target_position = Vector3(0, 0, -max_interaction_distance)
	enabled = true
	collide_with_areas = true
	collide_with_bodies = true
	# Set to world and interactable collision masks
	collision_mask = 1 | 4 | 8

func _physics_process(_delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		if collider is Node3D and collider != current_target:
			_update_focused_target(collider)
	else:
		if current_target != null:
			_clear_target()

func _update_focused_target(target: Node3D) -> void:
	current_target = target
	current_type = _detect_target_type(target)
	current_prompt = _generate_prompt(target, current_type)
	prompt_changed.emit(current_prompt)

func _clear_target() -> void:
	current_target = null
	current_type = ""
	current_prompt = ""
	prompt_changed.emit("")

func _detect_target_type(target: Node3D) -> String:
	# Check groups or methods or node name
	if target.is_in_group("tree") or target.has_method("chop") or "tree" in target.name.to_lower() or "log" in target.name.to_lower():
		return "tree"
	if target.is_in_group("rock") or target.has_method("mine") or "rock" in target.name.to_lower() or "stone" in target.name.to_lower() or "ore" in target.name.to_lower():
		return "rock"
	if target.is_in_group("item") or target.has_method("pickup") or "item" in target.name.to_lower() or "drop" in target.name.to_lower():
		return "item"
	if target.is_in_group("chest") or target.has_method("open_chest") or "chest" in target.name.to_lower() or "bau" in target.name.to_lower():
		return "chest"
	if target.is_in_group("workbench") or target.has_method("open_crafting") or "workbench" in target.name.to_lower() or "craft" in target.name.to_lower():
		return "workbench"
	if target.is_in_group("enemy") or target.has_method("take_damage"):
		return "enemy"
	if target.has_method("interact"):
		return "generic_interactable"
	return "surface"

func _generate_prompt(target: Node3D, type: String) -> String:
	match type:
		"tree":
			return "[Click Esq.] Cortar Madeira"
		"rock":
			return "[Click Esq.] Minerar Pedra"
		"item":
			var item_name: String = target.get("item_name") if "item_name" in target else target.name
			return "[E] Coletar %s" % item_name
		"chest":
			return "[E] Abrir Baú"
		"workbench":
			return "[E] Usar Bancada de Trabalho"
		"enemy":
			return "[Click Esq.] Atacar"
		"generic_interactable":
			return "[E] Interagir"
		_:
			return ""

## Triggered when pressing 'E' (interact)
func interact() -> bool:
	if not is_colliding() or current_target == null:
		return false

	var target = current_target
	var type = current_type

	match type:
		"item":
			if target.has_method("pickup"):
				target.pickup(player_reference)
			elif target.has_method("collect"):
				target.collect(player_reference)
			else:
				target.queue_free()
			AudioManager.play_sound("item_pickup")
			interacted.emit(target, "item")
			_clear_target()
			return true

		"chest":
			if target.has_method("open"):
				target.open(player_reference)
			elif target.has_method("interact"):
				target.interact(player_reference)
			interacted.emit(target, "chest")
			return true

		"workbench":
			if target.has_method("open_crafting"):
				target.open_crafting(player_reference)
			elif target.has_method("interact"):
				target.interact(player_reference)
			interacted.emit(target, "workbench")
			return true

		"generic_interactable":
			if target.has_method("interact"):
				target.interact(player_reference)
			interacted.emit(target, "generic")
			return true

	return false

## Triggered when weapon/tool strikes in the direction of the ray
func apply_strike(tool_type: String, damage: float) -> bool:
	if not is_colliding():
		return false

	var target = get_collider()
	if not (target is Node3D):
		return false

	var hit_pos: Vector3 = get_collision_point()
	var hit_normal: Vector3 = get_collision_normal()
	var type: String = _detect_target_type(target)

	# Sound feedback based on material
	match type:
		"tree":
			var bonus_multiplier: float = 2.0 if tool_type == "axe" else 1.0
			var total_dmg: float = damage * bonus_multiplier
			if target.has_method("chop"):
				target.chop(total_dmg, hit_pos, hit_normal)
			elif target.has_method("take_hit"):
				target.take_hit(total_dmg, "axe", hit_pos, hit_normal)
			AudioManager.play_sound_3d("impact_wood", hit_pos)
			hit_applied.emit(target, "tree", total_dmg, hit_pos, hit_normal)
			return true

		"rock":
			var bonus_multiplier: float = 2.0 if tool_type == "pickaxe" else 1.0
			var total_dmg: float = damage * bonus_multiplier
			if target.has_method("mine"):
				target.mine(total_dmg, hit_pos, hit_normal)
			elif target.has_method("take_hit"):
				target.take_hit(total_dmg, "pickaxe", hit_pos, hit_normal)
			AudioManager.play_sound_3d("impact_stone", hit_pos)
			hit_applied.emit(target, "rock", total_dmg, hit_pos, hit_normal)
			return true

		"enemy":
			var bonus_multiplier: float = 1.5 if tool_type == "sword" else 1.0
			var total_dmg: float = damage * bonus_multiplier
			if target.has_method("take_damage"):
				target.take_damage(total_dmg, player_reference)
			AudioManager.play_sound_3d("damage", hit_pos)
			hit_applied.emit(target, "enemy", total_dmg, hit_pos, hit_normal)
			return true

		_:
			# Default surface impact
			if target.has_method("take_hit"):
				target.take_hit(damage, tool_type, hit_pos, hit_normal)
			AudioManager.play_sound_3d("impact_stone", hit_pos, 0.1, -4.0)
			hit_applied.emit(target, "surface", damage, hit_pos, hit_normal)
			return true
