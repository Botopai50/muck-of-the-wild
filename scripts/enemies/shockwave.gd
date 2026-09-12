class_name Shockwave
extends Area3D

## Onda de Choque do Pisão Colossal do Golem (Zelda BotW x Muck)
## Anel de poeira expansivo, anel de energia Sheikah, dano em área
## e screen-shake intenso no jogador próximo.

@export var damage: float = 45.0
@export var max_radius: float = 9.5
@export var duration: float = 0.75

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var dust_particles: CPUParticles3D = $DustRingParticles

var current_radius: float = 0.6
var hit_entities: Array[Node] = []

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Detecta jogador (layer 2)
	
	body_entered.connect(_on_body_entered)
	
	# 1. Screen-shake no jogador próximo imediatamente ao detonar a onda de choque
	_apply_screen_shake_to_nearby_players()
	
	# 2. Ativar partículas de poeira expansiva
	if dust_particles:
		dust_particles.emitting = true
		dust_particles.restart()
		
	# 3. Animação de expansão rápida e dissipação da onda de energia
	var tween := create_tween().set_parallel(true)
	tween.tween_method(_update_radius, 0.6, max_radius, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if mesh_instance:
		var mat := mesh_instance.get_active_material(0)
		if mat and mat is StandardMaterial3D:
			var dup_mat = mat.duplicate()
			mesh_instance.material_override = dup_mat
			tween.tween_property(dup_mat, "albedo_color:a", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			if dup_mat.emission_enabled:
				tween.tween_property(dup_mat, "emission_energy_multiplier", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				
	# Remover após final da expansão e dissipação da poeira
	tween.chain().tween_interval(0.3)
	tween.chain().tween_callback(queue_free)

func _apply_screen_shake_to_nearby_players() -> void:
	var tree := get_tree()
	if not tree:
		return
	var players := tree.get_nodes_in_group("player")
	for p in players:
		if p is Node3D and is_instance_valid(p):
			var dist := global_position.distance_to(p.global_position)
			var max_shake_dist := max_radius * 2.2
			if dist < max_shake_dist and p.has_method("apply_camera_shake"):
				var factor := 1.0 - (dist / max_shake_dist)
				var intensity := clampf(factor * 1.3, 0.35, 1.4)
				p.apply_camera_shake(intensity, 0.55)

func _update_radius(r: float) -> void:
	current_radius = r
	if mesh_instance:
		mesh_instance.scale = Vector3(r, 1.0, r)
	if collision_shape:
		var cyl := collision_shape.shape as CylinderShape3D
		if cyl:
			cyl.radius = r

func _on_body_entered(body: Node) -> void:
	if hit_entities.has(body):
		return
	hit_entities.append(body)
	
	if body is Node3D and body.has_method("take_damage"):
		var knock_dir: Vector3 = (body.global_position - global_position).normalized()
		knock_dir.y = 0.75
		body.take_damage(damage, knock_dir * 18.0)
		AudioSynth.play_sound(body, "player_hit", 3.0, 0.75)
		if body.has_method("apply_camera_shake"):
			body.apply_camera_shake(1.2, 0.45)