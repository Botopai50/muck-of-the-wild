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
@export var foliage_material: Material = null
@export var bark_material: Material = null

const HIT_SPARKS_SCENE = preload("res://scenes/vfx/hit_sparks.tscn")
const WOOD_BURST_SCENE = preload("res://scenes/vfx/wood_burst.tscn")
const ROCK_DEBRIS_SCENE = preload("res://scenes/vfx/rock_debris.tscn")

@onready var visual_node: Node3D = $Visual

var is_destroyed: bool = false
var original_rotation: Vector3
var original_scale: Vector3 = Vector3.ONE

func _ready() -> void:
	add_to_group("resources")
	if node_type == NodeType.TREE:
		add_to_group("tree")
	else:
		add_to_group("rock")
		
	collision_layer = 5 # Layer 1 (mundo) + Layer 3 (recursos: bit 4)
	if visual_node:
		original_rotation = visual_node.rotation
		original_scale = visual_node.scale
	_apply_botw_materials()

func _apply_botw_materials() -> void:
	if not visual_node:
		return
	if node_type == NodeType.TREE:
		var bark_mat = bark_material if bark_material else load("res://materials/m_botw_cel_birch_bark.tres")
		var stripe_mat = load("res://materials/m_botw_cel_birch_stripes.tres")
		var leaf_mat = foliage_material if foliage_material else load("res://materials/m_botw_foliage.tres")
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

func chop(amount: float, hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> void:
	take_damage(amount, hit_pos, 0.0, hit_pos, hit_normal)

func mine(amount: float, hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> void:
	take_damage(amount, hit_pos, 0.0, hit_pos, hit_normal)

func take_hit(amount: float, _tool_type: String, hit_pos: Vector3, hit_normal: Vector3 = Vector3.UP) -> void:
	take_damage(amount, hit_pos, 0.0, hit_pos, hit_normal)

func on_hit(amount: float, hit_pos: Vector3 = Vector3.ZERO, hit_normal: Vector3 = Vector3.UP) -> void:
	take_damage(amount, hit_pos, 0.0, hit_pos, hit_normal)

func take_damage(amount: float, hit_source: Vector3, _knockback: float = 0.0, hit_pos: Vector3 = Vector3.ZERO, hit_normal: Vector3 = Vector3.UP) -> void:
	if is_destroyed:
		return
		
	current_health -= amount
	
	if node_type == NodeType.TREE:
		AudioSynth.play_sound(self, "wood_chop", 1.0, randf_range(0.9, 1.15))
		var leaves = get_node_or_null("FallingLeaves")
		if leaves and leaves.has_method("burst_flurry"):
			leaves.burst_flurry()
	else:
		AudioSynth.play_sound(self, "rock_break", 1.0, randf_range(0.9, 1.15))
		
	_spawn_damage_number(amount)
	_spawn_hit_vfx(hit_pos, hit_normal, hit_source)
	_wobble(hit_source)
	
	if current_health <= 0.0:
		_destroy()

func _spawn_hit_vfx(hit_pos: Vector3, hit_normal: Vector3, hit_source: Vector3) -> void:
	if not is_inside_tree():
		return
	
	var actual_pos := hit_pos
	if actual_pos == Vector3.ZERO:
		actual_pos = global_position + Vector3(0, 2.0 if node_type == NodeType.TREE else 1.0, 0)
		
	var actual_normal := hit_normal
	if actual_normal == Vector3.UP and hit_source != Vector3.ZERO:
		var dir := (actual_pos - hit_source).normalized()
		if not dir.is_zero_approx():
			actual_normal = dir

	if node_type == NodeType.TREE:
		if WOOD_BURST_SCENE:
			var wb = WOOD_BURST_SCENE.instantiate()
			get_parent().add_child(wb)
			wb.global_position = actual_pos
			if wb.has_method("setup"):
				wb.setup(actual_normal, 1.0)
				
		if HIT_SPARKS_SCENE:
			var hs = HIT_SPARKS_SCENE.instantiate()
			get_parent().add_child(hs)
			hs.global_position = actual_pos
			if hs.has_method("setup"):
				hs.setup(Color(1.0, 0.85, 0.35), actual_normal, 0.9)
	else:
		if ROCK_DEBRIS_SCENE:
			var rd = ROCK_DEBRIS_SCENE.instantiate()
			get_parent().add_child(rd)
			rd.global_position = actual_pos
			if rd.has_method("setup"):
				rd.setup(actual_normal, 1.0)
				
		if HIT_SPARKS_SCENE:
			var hs = HIT_SPARKS_SCENE.instantiate()
			get_parent().add_child(hs)
			hs.global_position = actual_pos
			if hs.has_method("setup"):
				hs.setup(Color(0.85, 0.92, 1.0), actual_normal, 1.0)

func _wobble(hit_source: Vector3) -> void:
	if not visual_node or not is_inside_tree():
		return
	var dir := (global_position - hit_source)
	dir.y = 0.0
	dir = dir.normalized()
	if dir.is_zero_approx():
		dir = Vector3(1, 0, 0)
	var wobble_angle := 0.12
	
	var tween := create_tween().set_parallel(true)
	
	# Inclinação física elástica com ressalto suave (BotW style spring)
	var target_rot := Vector3(
		original_rotation.x + dir.z * wobble_angle,
		original_rotation.y,
		original_rotation.z - dir.x * wobble_angle
	)
	visual_node.rotation = target_rot
	tween.tween_property(visual_node, "rotation", original_rotation, 0.55).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Efeito de compressão elástica (Squash & Stretch)
	visual_node.scale = original_scale * Vector3(1.10, 0.88, 1.10)
	tween.tween_property(visual_node, "scale", original_scale, 0.48).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

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

func on_destroyed() -> void:
	_destroy()

func _destroy() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	collision_layer = 0
	
	_spawn_destruction_vfx()
	_drop_resources()
	
	var leaves = get_node_or_null("FallingLeaves")
	if leaves:
		leaves.emitting = false
	
	var tween := create_tween().set_parallel(true)
	if node_type == NodeType.TREE:
		tween.tween_property(visual_node, "rotation_degrees:x", 85.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(visual_node, "scale", Vector3.ZERO, 0.4).set_delay(0.65)
	else:
		tween.tween_property(visual_node, "scale", Vector3.ZERO, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		
	tween.chain().tween_callback(queue_free)

func _spawn_destruction_vfx() -> void:
	if not is_inside_tree():
		return
	if node_type == NodeType.TREE:
		if WOOD_BURST_SCENE:
			var wb = WOOD_BURST_SCENE.instantiate()
			get_parent().add_child(wb)
			wb.global_position = global_position + Vector3(0, 2.0, 0)
			if wb.has_method("setup"):
				wb.setup(Vector3.UP, 1.8)
		if HIT_SPARKS_SCENE:
			var hs = HIT_SPARKS_SCENE.instantiate()
			get_parent().add_child(hs)
			hs.global_position = global_position + Vector3(0, 2.0, 0)
			if hs.has_method("setup"):
				hs.setup(Color(1.0, 0.85, 0.35), Vector3.UP, 1.5)
	else:
		if ROCK_DEBRIS_SCENE:
			var rd = ROCK_DEBRIS_SCENE.instantiate()
			get_parent().add_child(rd)
			rd.global_position = global_position + Vector3(0, 1.0, 0)
			if rd.has_method("setup"):
				rd.setup(Vector3.UP, 2.0)
		if HIT_SPARKS_SCENE:
			var hs = HIT_SPARKS_SCENE.instantiate()
			get_parent().add_child(hs)
			hs.global_position = global_position + Vector3(0, 1.0, 0)
			if hs.has_method("setup"):
				hs.setup(Color(0.85, 0.95, 1.0), Vector3.UP, 1.6)

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
