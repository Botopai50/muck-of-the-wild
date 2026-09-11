@tool
extends SceneTree

func _init():
	print("--- Criando Cena de Teste 3D para os Shaders BotW ---")
	var root = Node3D.new()
	root.name = "TestBotwShaders"

	# DirectionalLight3D
	var sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-45.0, 30.0, 0.0)
	sun.shadow_enabled = true
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.light_energy = 1.2
	root.add_child(sun)
	sun.owner = root

	# WorldEnvironment com Sky Shader
	var env_node = WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_mat = ResourceLoader.load("res://materials/m_botw_sky.tres")
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env_node.environment = env
	root.add_child(env_node)
	env_node.owner = root

	# 1. Mesh de Personagem / Cel
	var sphere = MeshInstance3D.new()
	sphere.name = "CharacterSphere"
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radial_segments = 32
	sphere_mesh.rings = 16
	sphere.mesh = sphere_mesh
	sphere.position = Vector3(-2.0, 1.0, 0.0)
	sphere.material_override = ResourceLoader.load("res://materials/m_botw_cel_character.tres")
	root.add_child(sphere)
	sphere.owner = root

	# 2. Mesh de Rocha / Cel
	var rock = MeshInstance3D.new()
	rock.name = "RockBox"
	var box_mesh = BoxMesh.new()
	rock.mesh = box_mesh
	rock.position = Vector3(2.0, 0.5, 0.0)
	rock.material_override = ResourceLoader.load("res://materials/m_botw_cel_rock.tres")
	root.add_child(rock)
	rock.owner = root

	# 3. Mesh de Copa / Foliage
	var foliage = MeshInstance3D.new()
	foliage.name = "FoliageCluster"
	var foliage_mesh = SphereMesh.new()
	foliage.mesh = foliage_mesh
	foliage.position = Vector3(0.0, 2.5, -2.0)
	foliage.material_override = ResourceLoader.load("res://materials/m_botw_foliage.tres")
	root.add_child(foliage)
	foliage.owner = root

	# 4. Mesh de Grama
	var grass = MeshInstance3D.new()
	grass.name = "GrassPlane"
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(1.0, 1.0)
	grass.mesh = quad_mesh
	grass.position = Vector3(0.0, 0.5, 1.0)
	grass.material_override = ResourceLoader.load("res://materials/m_botw_grass.tres")
	root.add_child(grass)
	grass.owner = root

	# 5. Mesh de Agua
	var water = MeshInstance3D.new()
	water.name = "WaterPlane"
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(10.0, 10.0)
	plane_mesh.subdivide_width = 16
	plane_mesh.subdivide_depth = 16
	water.mesh = plane_mesh
	water.position = Vector3(0.0, 0.0, 0.0)
	water.material_override = ResourceLoader.load("res://materials/m_botw_water.tres")
	root.add_child(water)
	water.owner = root

	var packed = PackedScene.new()
	var pack_err = packed.pack(root)
	if pack_err == OK:
		var save_err = ResourceSaver.save(packed, "res://scenes/test_botw_shaders.tscn")
		print("Cena de teste salva com sucesso: ", save_err == OK)
	else:
		print("Erro ao empacotar cena: ", pack_err)

	quit(0)
