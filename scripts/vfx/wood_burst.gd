class_name WoodBurst
extends Node3D

## Efeito de impacto e desintegração de madeira (estilo BotW)
## Emite lascas de madeira, folhas flutuantes e fumaça/serragem cartunesca.

@onready var chips_particles: GPUParticles3D = $Chips
@onready var leaves_particles: GPUParticles3D = $Leaves
@onready var dust_particles: GPUParticles3D = $Dust

var _pending_normal: Vector3 = Vector3.UP

func _ready() -> void:
	_orient_to_normal(_pending_normal)
	play()

func setup(hit_normal: Vector3 = Vector3.UP, scale_mult: float = 1.0) -> void:
	scale = Vector3.ONE * scale_mult
	_pending_normal = hit_normal
	if is_inside_tree():
		_orient_to_normal(hit_normal)

func _orient_to_normal(norm: Vector3) -> void:
	if not is_inside_tree() or norm.length_squared() < 0.001:
		return
	if abs(norm.dot(Vector3.UP)) < 0.99:
		look_at(global_position + norm, Vector3.UP)
	else:
		look_at(global_position + norm, Vector3.FORWARD)

func play() -> void:
	if not chips_particles: chips_particles = get_node_or_null("Chips") as GPUParticles3D
	if not leaves_particles: leaves_particles = get_node_or_null("Leaves") as GPUParticles3D
	if not dust_particles: dust_particles = get_node_or_null("Dust") as GPUParticles3D

	if chips_particles:
		chips_particles.restart()
		chips_particles.emitting = true
	if leaves_particles:
		leaves_particles.restart()
		leaves_particles.emitting = true
	if dust_particles:
		dust_particles.restart()
		dust_particles.emitting = true

	get_tree().create_timer(0.85).timeout.connect(queue_free)
