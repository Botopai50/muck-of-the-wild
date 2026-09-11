class_name Shockwave
extends Area3D

@export var damage: float = 40.0
@export var max_radius: float = 8.5
@export var duration: float = 0.65

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var current_radius: float = 0.5
var hit_entities: Array[Node] = []

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Detecta jogador (layer 2)
	
	body_entered.connect(_on_body_entered)
	
	var tween := create_tween().set_parallel(true)
	tween.tween_method(_update_radius, 0.5, max_radius, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var mat := mesh_instance.get_active_material(0)
	if mat and mat is StandardMaterial3D:
		var dup_mat = mat.duplicate()
		mesh_instance.material_override = dup_mat
		tween.tween_property(dup_mat, "albedo_color:a", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		
	tween.chain().tween_callback(queue_free)

func _update_radius(r: float) -> void:
	current_radius = r
	mesh_instance.scale = Vector3(r, 1.0, r)
	var cyl := collision_shape.shape as CylinderShape3D
	if cyl:
		cyl.radius = r

func _on_body_entered(body: Node) -> void:
	if hit_entities.has(body):
		return
	hit_entities.append(body)
	
	if body.has_method("take_damage"):
		var knock_dir := (body.global_position - global_position).normalized()
		knock_dir.y = 0.8
		body.take_damage(damage, knock_dir * 16.0)
		AudioSynth.play_sound(body, "player_hit", 2.0, 0.8)
