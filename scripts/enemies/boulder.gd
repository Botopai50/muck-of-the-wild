class_name Boulder
extends CharacterBody3D

## Pedregulho Gigante Arremessado pelo Golem (Zelda BotW x Muck)
## Possui rastro dinâmico de poeira durante o voo balístico,
## detonação com explosão de fragmentos de rocha e screen-shake no impacto.

@export var damage: float = 34.0
@export var speed: float = 25.0
@export var gravity: float = 15.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var dust_trail: CPUParticles3D = $DustTrailParticles
@onready var impact_particles: CPUParticles3D = $ImpactParticles

var direction: Vector3 = Vector3.FORWARD
var lifetime: float = 5.5
var has_exploded: bool = false

func launch(start_pos: Vector3, target_pos: Vector3) -> void:
	global_position = start_pos
	var to_target := (target_pos - start_pos)
	var dist_h := Vector2(to_target.x, to_target.z).length()
	var time_est := dist_h / speed
	var vy := (to_target.y + 0.5 * gravity * time_est * time_est) / maxf(time_est, 0.1)
	var dir_h := Vector3(to_target.x, 0, to_target.z).normalized()
	velocity = dir_h * speed + Vector3(0, vy, 0)
	
	if dust_trail:
		dust_trail.emitting = true
		
	AudioSynth.play_sound(self, "golem_throw", 2.0, 0.9)

func _physics_process(delta: float) -> void:
	if has_exploded:
		return
		
	lifetime -= delta
	if lifetime <= 0.0:
		_explode()
		return
		
	velocity.y -= gravity * delta
	mesh_instance.rotate_x(delta * 7.5)
	mesh_instance.rotate_z(delta * 5.0)
	
	var collision := move_and_collide(velocity * delta)
	if collision:
		var collider := collision.get_collider()
		if collider and collider.has_method("take_damage"):
			collider.take_damage(damage, velocity.normalized() * 14.0)
		_explode()

func _explode() -> void:
	if has_exploded:
		return
	has_exploded = true
	
	if dust_trail:
		dust_trail.emitting = false
		
	AudioSynth.play_sound(self, "rock_break", 3.0, 0.75)
	
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if p is Node3D and is_instance_valid(p):
			var dist := global_position.distance_to(p.global_position)
			if dist < 16.0 and p.has_method("apply_camera_shake"):
				var intensity := (1.0 - dist / 16.0) * 0.85
				p.apply_camera_shake(intensity, 0.45)
				
	if impact_particles:
		impact_particles.emitting = true
		impact_particles.restart()
		
	var tween := create_tween().set_parallel(true)
	tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_interval(0.4)
	tween.chain().tween_callback(queue_free)