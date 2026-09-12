class_name SlashTrail
extends Node3D

## Gerador procedural e controlador do efeito de rastro de corte estilo anime (BotW)
## Gera uma malha em arco e anima o shader emissivo 'slash_trail.gdshader'.

@export var inner_radius: float = 0.35
@export var outer_radius: float = 1.15
@export var sweep_degrees: float = 150.0
@export var segments: int = 32

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var material: ShaderMaterial
var active_tween: Tween

func _ready() -> void:
	_ensure_mesh_instance()
	_generate_arc_mesh()
	_setup_material()
	visible = false

func _ensure_mesh_instance() -> void:
	if not mesh_instance:
		mesh_instance = get_node_or_null("MeshInstance3D") as MeshInstance3D
		if not mesh_instance:
			mesh_instance = MeshInstance3D.new()
			mesh_instance.name = "MeshInstance3D"
			add_child(mesh_instance)

func _setup_material() -> void:
	_ensure_mesh_instance()
	var shader = load("res://shaders/slash_trail.gdshader")
	if shader:
		material = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("progress", 0.0)
		material.set_shader_parameter("trail_length", 0.60)
		material.set_shader_parameter("emission_intensity", 3.2)
		mesh_instance.material_override = material

func _generate_arc_mesh() -> void:
	_ensure_mesh_instance()
	var arr_mesh = ArrayMesh.new()
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var half_angle = deg_to_rad(sweep_degrees * 0.5)
	var start_angle = -half_angle
	var end_angle = half_angle

	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var angle = lerpf(start_angle, end_angle, t)
		var cos_a = cos(angle)
		var sin_a = sin(angle)

		var v_inner = Vector3(cos_a * inner_radius, sin_a * inner_radius, 0.0)
		var v_outer = Vector3(cos_a * outer_radius, sin_a * outer_radius, 0.0)

		verts.append(v_inner)
		verts.append(v_outer)

		uvs.append(Vector2(t, 0.0))
		uvs.append(Vector2(t, 1.0))

		normals.append(Vector3(0, 0, 1))
		normals.append(Vector3(0, 0, 1))

		if i < segments:
			var base = i * 2
			# Triângulo 1
			indices.append(base)
			indices.append(base + 1)
			indices.append(base + 2)
			# Triângulo 2
			indices.append(base + 1)
			indices.append(base + 3)
			indices.append(base + 2)

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = arr_mesh

## Dispara o rastro de corte com cor, orientação e duração ajustáveis
func play_slash(duration: float = 0.22, color: Color = Color(0.35, 0.78, 1.0), reverse: bool = false, tilt_deg: float = -25.0, yaw_deg: float = 0.0) -> void:
	_ensure_mesh_instance()
	if not mesh_instance.mesh:
		_generate_arc_mesh()
	if not material:
		_setup_material()
	if not material:
		return

	if active_tween and active_tween.is_valid():
		active_tween.kill()

	visible = true
	rotation_degrees = Vector3(tilt_deg, yaw_deg, 180.0 if reverse else 0.0)

	var core_color = Color(1.0, 1.0, 1.0, 1.0)
	var tip_color = color.lerp(Color.BLACK, 0.45)
	tip_color.a = 1.0

	material.set_shader_parameter("trail_color", color)
	material.set_shader_parameter("tip_color", tip_color)
	material.set_shader_parameter("core_color", core_color)
	material.set_shader_parameter("alpha_mult", 1.0)

	active_tween = create_tween().set_parallel(true)
	
	material.set_shader_parameter("progress", 0.0)
	active_tween.tween_method(
		func(val: float): material.set_shader_parameter("progress", val),
		0.0, 1.35, duration
	).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	active_tween.tween_method(
		func(a: float): material.set_shader_parameter("alpha_mult", a),
		1.0, 0.0, duration * 0.4
	).set_delay(duration * 0.65)

	active_tween.chain().tween_callback(func():
		visible = false
	)
