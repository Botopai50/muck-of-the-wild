class_name ResourceNode
extends StaticBody3D

## Nó de recurso coletável no mundo (Árvore cortável ou Rocha minerável)
## Reage a golpes com oscilação física e libera itens ao ser destruído

enum NodeType {
	TREE,
	ROCK
}

@export var node_type: NodeType = NodeType.TREE
@export var max_health: float = 50.0
@export var current_health: float = 50.0

@onready var visual_node: Node3D = $Visual

var is_destroyed: bool = false
var original_rotation: Vector3

func _ready() -> void:
	add_to_group("resources")
	if node_type == NodeType.TREE:
		add_to_group("tree")
	else:
		add_to_group("rock")
		
	collision_layer = 5 # Layer 1 (mundo) + Layer 3 (recursos: bit 4)
	if visual_node:
		original_rotation = visual_node.rotation
	_apply_botw_materials()

func _apply_botw_materials() -> void:
	if not visual_node:
		return
	if node_type == NodeType.TREE:
		var bark_mat = load("res://materials/m_botw_cel_birch_bark.tres")
		var stripe_mat = load("res://materials/m_botw_cel_birch_stripes.tres")
		var leaf_mat = load("res://materials/m_botw_foliage.tres")
		for child in visual_node.find_children("*", "MeshInstance3D", true):
			if child is MeshInstance3D:
				if bark_mat: child.set_surface_override_material(0, bark_mat)
				if stripe_mat: child.set_surface_override_material(1, stripe_mat)
				if leaf_mat:
					child.set_surface_override_material(2, leaf_mat)
					child.set_surface_override_material(3, leaf_mat)
	else:
		var rock_mat = load("res://materials/m_botw_cel_rock.tres")
		for child in visual_node.find_children("*", "MeshInstance3D", true):
			if child is MeshInstance3D:
				if rock_mat: child.set_surface_override_material(0, rock_mat)

func chop(amount: float, hit_pos: Vector3, _hit_normal: Vector3 = Vector3.UP) -> void:
	take_damage(amount, hit_pos)

func mine(amount: float, hit_pos: Vector3, _hit_normal: Vector3 = Vector3.UP) -> void:
	take_damage(amount, hit_pos)

func take_hit(amount: float, _tool_type: String, hit_pos: Vector3, _hit_normal: Vector3 = Vector3.UP) -> void:
	take_damage(amount, hit_pos)

func take_damage(amount: float, hit_source: Vector3, _knockback: float = 0.0) -> void:
	if is_destroyed:
		return
		
	current_health -= amount
	
	if node_type == NodeType.TREE:
		AudioSynth.play_sound(self, "wood_chop", 1.0, randf_range(0.9, 1.15))
	else:
		AudioSynth.play_sound(self, "rock_break", 1.0, randf_range(0.9, 1.15))
		
	_spawn_damage_number(amount)
	_wobble(hit_source)
	
	if current_health <= 0.0:
		_destroy()

func _wobble(hit_source: Vector3) -> void:
	if not visual_node or not is_inside_tree():
		return
	var dir := (global_position - hit_source).normalized()
	var wobble_angle := 0.08
	
	var tween := create_tween()
	tween.tween_property(visual_node, "rotation:x", original_rotation.x + dir.z * wobble_angle, 0.08)
	tween.parallel().tween_property(visual_node, "rotation:z", original_rotation.z - dir.x * wobble_angle, 0.08)
	tween.tween_property(visual_node, "rotation", original_rotation, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _spawn_damage_number(amount: float) -> void:
	if not is_inside_tree():
		return
	var ft_scene = load("res://scenes/ui/floating_text.tscn")
	if ft_scene:
		var ft = ft_scene.instantiate()
		get_parent().add_child(ft)
		ft.global_position = global_position + Vector3(0, 2.5 if node_type == NodeType.TREE else 1.2, 0)
		var col := Color(0.9, 0.75, 0.3) if node_type == NodeType.TREE else Color(0.7, 0.7, 0.8)
		ft.setup(str(int(amount)), col)

func _destroy() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	collision_layer = 0
	
	_drop_resources()
	
	var tween := create_tween().set_parallel(true)
	if node_type == NodeType.TREE:
		tween.tween_property(visual_node, "rotation_degrees:x", 85.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(visual_node, "scale", Vector3.ZERO, 0.4).set_delay(0.65)
	else:
		tween.tween_property(visual_node, "scale", Vector3.ZERO, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		
	tween.chain().tween_callback(queue_free)

func _drop_resources() -> void:
	var drop_scene = load("res://scenes/items/drop_item.tscn")
	if not drop_scene:
		return
		
	var count := randi_range(3, 5)
	for i in range(count):
		var d = drop_scene.instantiate()
		get_parent().add_child(d)
		d.global_position = global_position + Vector3(randf_range(-0.5, 0.5), 1.0, randf_range(-0.5, 0.5))
		if node_type == NodeType.TREE:
			# Madeira e chance de Maçã
			if randf() < 0.25:
				d.setup(DropItem.ItemType.APPLE, 1)
			else:
				d.setup(DropItem.ItemType.WOOD, randi_range(2, 3))
		else:
			# Pedra e chance de Minério de Ferro
			if randf() < 0.35:
				d.setup(DropItem.ItemType.IRON_ORE, randi_range(1, 2))
			else:
				d.setup(DropItem.ItemType.STONE, randi_range(2, 4))
