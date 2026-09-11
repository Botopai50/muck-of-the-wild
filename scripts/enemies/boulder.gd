class_name Boulder
extends CharacterBody3D

@export var damage: float = 32.0
@export var speed: float = 24.0
@export var gravity: float = 14.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var direction: Vector3 = Vector3.FORWARD
var lifetime: float = 5.0
var has_exploded: bool = false

func launch(start_pos: Vector3, target_pos: Vector3) -> void:
	global_position = start_pos
	var to_target := (target_pos - start_pos)
	var dist_h := Vector2(to_target.x, to_target.z).length()
	var time_est := dist_h / speed
	# Compensar gravidade no arco de tiro
	var vy := (to_target.y + 0.5 * gravity * time_est * time_est) / maxf(time_est, 0.1)
	var dir_h := Vector3(to_target.x, 0, to_target.z).normalized()
	velocity = dir_h * speed + Vector3(0, vy, 0)
	
	AudioSynth.play_sound(self, "golem_throw", 0.0, 0.85)

func _physics_process(delta: float) -> void:
	if has_exploded:
		return
		
	lifetime -= delta
	if lifetime <= 0.0:
		_explode()
		return
		
	velocity.y -= gravity * delta
	mesh_instance.rotate_x(delta * 6.0)
	mesh_instance.rotate_z(delta * 4.0)
	
	var collision := move_and_collide(velocity * delta)
	if collision:
		var collider := collision.get_collider()
		if collider and collider.has_method("take_damage"):
			collider.take_damage(damage, velocity.normalized() * 12.0)
		_explode()

func _explode() -> void:
	if has_exploded:
		return
	has_exploded = true
	
	AudioSynth.play_sound(self, "rock_break", 2.0, 0.75)
	
	# Efeito de fragmentos de pedra
	var tween := create_tween().set_parallel(true)
	tween.tween_property(mesh_instance, "scale", Vector3.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
