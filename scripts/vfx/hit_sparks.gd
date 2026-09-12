class_name HitSparks
extends Node3D

## Efeito visual de impacto e faíscas cortantes estilo anime / Zelda BotW
## Inclui estrela de impacto (star flash), anel de choque e faíscas direcionadas.

@onready var star_flash: MeshInstance3D = $StarFlash
@onready var impact_ring: MeshInstance3D = $ImpactRing
@onready var spark_particles: GPUParticles3D = $Sparks

var _pending_color: Color = Color(1.0, 0.85, 0.3)
var _pending_normal: Vector3 = Vector3.UP

func _ready() -> void:
	_orient_to_normal(_pending_normal)
	_apply_color(_pending_color)
	play()

func setup(color: Color = Color(1.0, 0.85, 0.3), hit_normal: Vector3 = Vector3.UP, scale_mult: float = 1.0) -> void:
	scale = Vector3.ONE * scale_mult
	_pending_color = color
	_pending_normal = hit_normal
	if is_inside_tree():
		_orient_to_normal(hit_normal)
		_apply_color(color)

func _orient_to_normal(norm: Vector3) -> void:
	if not is_inside_tree() or norm.length_squared() < 0.001:
		return
	if abs(norm.dot(Vector3.UP)) < 0.99:
		look_at(global_position + norm, Vector3.UP)
	else:
		look_at(global_position + norm, Vector3.FORWARD)

func _apply_color(col: Color) -> void:
	if not star_flash:
		star_flash = get_node_or_null("StarFlash") as MeshInstance3D
	if not impact_ring:
		impact_ring = get_node_or_null("ImpactRing") as MeshInstance3D
	if not spark_particles:
		spark_particles = get_node_or_null("Sparks") as GPUParticles3D

	if star_flash and star_flash.material_override:
		var mat = star_flash.material_override.duplicate() as StandardMaterial3D
		if mat:
			mat.albedo_color = col
			mat.emission = col
			star_flash.material_override = mat

	if impact_ring and impact_ring.material_override:
		var r_mat = impact_ring.material_override.duplicate() as StandardMaterial3D
		if r_mat:
			r_mat.albedo_color = col
			r_mat.emission = col
			impact_ring.material_override = r_mat

	if spark_particles and spark_particles.draw_pass_1:
		var p_mat = spark_particles.draw_pass_1.material
		if p_mat and p_mat is StandardMaterial3D:
			var dup_p_mat = p_mat.duplicate() as StandardMaterial3D
			dup_p_mat.albedo_color = col
			dup_p_mat.emission = col
			spark_particles.draw_pass_1 = spark_particles.draw_pass_1.duplicate()
			spark_particles.draw_pass_1.material = dup_p_mat

func play() -> void:
	if not spark_particles:
		spark_particles = get_node_or_null("Sparks") as GPUParticles3D
	if spark_particles:
		spark_particles.restart()
		spark_particles.emitting = true

	var tween := create_tween().set_parallel(true)

	if star_flash:
		star_flash.scale = Vector3.ZERO
		star_flash.rotation.z = randf_range(0.0, PI)
		tween.tween_property(star_flash, "scale", Vector3(1.3, 1.3, 1.3), 0.05).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(star_flash, "scale", Vector3.ZERO, 0.12).set_delay(0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	if impact_ring:
		impact_ring.scale = Vector3(0.1, 0.1, 0.1)
		tween.tween_property(impact_ring, "scale", Vector3(1.8, 1.8, 1.8), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var r_mat = impact_ring.material_override as StandardMaterial3D
		if r_mat:
			tween.tween_property(r_mat, "albedo_color:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	get_tree().create_timer(0.45).timeout.connect(queue_free)
