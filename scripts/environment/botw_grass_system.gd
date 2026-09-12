class_name BotWGrassSystem
extends Node3D

## Sistema de Grama Estilizada Densa BotW (Breath of the Wild)
## Gera tufos volumétricos procedurais com MultiMeshInstance3D
## e sincroniza a ondulação do vento e interação de pisoteio com o jogador.

@export var grass_material: ShaderMaterial
@export var grass_count: int = 12000
@export var island_radius: float = 72.0
@export var base_ground_y: float = 2.0

# Parâmetros da elevação do morro distante (DistantHill)
@export var hill_center: Vector2 = Vector2(42.0, -38.0)
@export var hill_top_radius: float = 8.0
@export var hill_base_radius: float = 17.0
@export var hill_top_y: float = 6.0

@export var tuft_blades_count: int = 5
@export var tuft_height: float = 0.95
@export var tuft_base_width: float = 0.08

var multimesh_instance: MultiMeshInstance3D
var player_ref: Node3D = null

func _ready() -> void:
	if not grass_material:
		grass_material = preload("res://materials/m_botw_grass.tres")
	
	_build_grass_multimesh()

func _process(_delta: float) -> void:
	if not player_ref or not is_instance_valid(player_ref):
		_find_player()
	
	if player_ref and is_instance_valid(player_ref) and grass_material:
		grass_material.set_shader_parameter("player_position", player_ref.global_position)

func _find_player() -> void:
	if not is_inside_tree() or not get_tree():
		return
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
	else:
		player_ref = get_node_or_null("../Player")

## Gera a malha procedural do tufo estilizado de grama com lâminas triangulares curvas
func generate_tuft_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var blade_angles := [0.0, 1.25, 2.45, 3.8, 5.1]
	if tuft_blades_count != 5:
		blade_angles.clear()
		for i in range(tuft_blades_count):
			blade_angles.append((float(i) / float(tuft_blades_count)) * TAU)
	
	for i in range(tuft_blades_count):
		var base_angle = blade_angles[i] + randf_range(-0.15, 0.15)
		var dir = Vector2(cos(base_angle), sin(base_angle))
		var tan_dir = Vector2(-dir.y, dir.x)
		
		var b_height = tuft_height * randf_range(0.85, 1.2)
		var b_width = tuft_base_width * randf_range(0.8, 1.2)
		var curve_dist = randf_range(0.12, 0.22) * (b_height / tuft_height)
		
		# Ponto de raiz da lâmina (pequeno offset radial do tufo)
		var root_center = dir * randf_range(0.01, 0.04)
		
		# Vértices da base (y = 0.0)
		var v0 = Vector3(root_center.x - tan_dir.x * (b_width * 0.5), 0.0, root_center.y - tan_dir.y * (b_width * 0.5))
		var v1 = Vector3(root_center.x + tan_dir.x * (b_width * 0.5), 0.0, root_center.y + tan_dir.y * (b_width * 0.5))
		
		# Vértices intermediários (y = 45% da altura)
		var mid_h = b_height * 0.45
		var mid_center = root_center + dir * (curve_dist * 0.35)
		var mid_w = b_width * 0.65
		var v_mid0 = Vector3(mid_center.x - tan_dir.x * (mid_w * 0.5), mid_h, mid_center.y - tan_dir.y * (mid_w * 0.5))
		var v_mid1 = Vector3(mid_center.x + tan_dir.x * (mid_w * 0.5), mid_h, mid_center.y + tan_dir.y * (mid_w * 0.5))
		
		# Vértice ápice / ponta da folha (y = b_height)
		var tip_center = root_center + dir * curve_dist
		var v_tip = Vector3(tip_center.x, b_height, tip_center.y)
		
		# Normais voltadas para cima com leve dispersão radial (estilo BotW)
		var n_base = Vector3(dir.x * 0.15, 0.95, dir.y * 0.15).normalized()
		var n_mid = Vector3(dir.x * 0.35, 0.85, dir.y * 0.35).normalized()
		var n_tip = Vector3(dir.x * 0.5, 0.7, dir.y * 0.5).normalized()
		
		# Segmento 1: Quad da base (Triângulo A e B)
		# Tri A: v0 -> v1 -> v_mid1
		st.set_normal(n_base); st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(v0)
		st.set_normal(n_base); st.set_uv(Vector2(1.0, 0.0)); st.add_vertex(v1)
		st.set_normal(n_mid);  st.set_uv(Vector2(0.85, 0.45)); st.add_vertex(v_mid1)
		
		# Tri B: v0 -> v_mid1 -> v_mid0
		st.set_normal(n_base); st.set_uv(Vector2(0.0, 0.0)); st.add_vertex(v0)
		st.set_normal(n_mid);  st.set_uv(Vector2(0.85, 0.45)); st.add_vertex(v_mid1)
		st.set_normal(n_mid);  st.set_uv(Vector2(0.15, 0.45)); st.add_vertex(v_mid0)
		
		# Segmento 2: Ponta triangular (Triângulo C)
		# Tri C: v_mid0 -> v_mid1 -> v_tip
		st.set_normal(n_mid); st.set_uv(Vector2(0.15, 0.45)); st.add_vertex(v_mid0)
		st.set_normal(n_mid); st.set_uv(Vector2(0.85, 0.45)); st.add_vertex(v_mid1)
		st.set_normal(n_tip); st.set_uv(Vector2(0.5, 1.0));   st.add_vertex(v_tip)
	
	var mesh = st.commit()
	return mesh

func _get_ground_height(x: float, z: float) -> float:
	var p2 := Vector2(x, z)
	var d_hill := p2.distance_to(hill_center)
	if d_hill <= hill_top_radius:
		return hill_top_y
	elif d_hill < hill_base_radius:
		var t := (d_hill - hill_top_radius) / (hill_base_radius - hill_top_radius)
		return lerpf(hill_top_y, base_ground_y, smoothstep(0.0, 1.0, t))
	return base_ground_y

func _build_grass_multimesh() -> void:
	# Remover anterior se existir
	if multimesh_instance and is_instance_valid(multimesh_instance):
		multimesh_instance.queue_free()
	
	var tuft_mesh = generate_tuft_mesh()
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = grass_count
	mm.mesh = tuft_mesh
	
	# Preencher posições aleatórias distribuídas uniformemente na ilha
	var rng = RandomNumberGenerator.new()
	rng.seed = 133742 # Seed determinística para consistência visual
	
	for i in range(grass_count):
		# Distribuição uniforme em disco: r = sqrt(u) * R
		var u = rng.randf()
		var r = sqrt(u) * island_radius
		var theta = rng.randf() * TAU
		
		var x = r * cos(theta)
		var z = r * sin(theta)
		var y = _get_ground_height(x, z)
		
		# Variação sutil de escala e orientação
		var yaw = rng.randf() * TAU
		var pitch = rng.randf_range(-0.06, 0.06)
		var roll = rng.randf_range(-0.06, 0.06)
		
		var scale_xz = rng.randf_range(0.85, 1.35)
		var scale_y = rng.randf_range(0.88, 1.35)
		
		var t = Transform3D()
		t = t.rotated(Vector3.UP, yaw)
		t = t.rotated(Vector3.RIGHT, pitch)
		t = t.rotated(Vector3.FORWARD, roll)
		t = t.scaled(Vector3(scale_xz, scale_y, scale_xz))
		t.origin = Vector3(x, y, z)
		
		mm.set_instance_transform(i, t)
	
	multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.name = "BotWGrassMultiMesh"
	multimesh_instance.multimesh = mm
	multimesh_instance.material_override = grass_material
	multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF # Otimização excelente para grama
	add_child(multimesh_instance)
	print("[BotWGrassSystem] Grama densa gerada com sucesso! Total de tufos: ", grass_count, " (~", grass_count * tuft_blades_count, " laminas)")
