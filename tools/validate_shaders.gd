@tool
extends SceneTree

func _init():
	print("========================================")
	print("--- Shaders & Materials Validator ---")
	print("========================================")
	
	var dir_shaders = DirAccess.open("res://shaders")
	var shaders: Array[String] = []
	if dir_shaders:
		dir_shaders.list_dir_begin()
		var file_name = dir_shaders.get_next()
		while file_name != "":
			if not dir_shaders.current_is_dir() and file_name.ends_with(".gdshader"):
				shaders.append("res://shaders/" + file_name)
			file_name = dir_shaders.get_next()
	shaders.sort()

	var dir_materials = DirAccess.open("res://materials")
	var materials: Array[String] = []
	if dir_materials:
		dir_materials.list_dir_begin()
		var file_name = dir_materials.get_next()
		while file_name != "":
			if not dir_materials.current_is_dir() and file_name.ends_with(".tres"):
				materials.append("res://materials/" + file_name)
			file_name = dir_materials.get_next()
	materials.sort()

	var has_errors = false
	
	print("\n[1] Verificando Shaders (%d encontrados)..." % shaders.size())
	for s_path in shaders:
		if not FileAccess.file_exists(s_path):
			print("  [PENDING/MISSING] %s" % s_path)
			continue
		var s = ResourceLoader.load(s_path)
		if s == null:
			print("  [ERROR] Falha ao carregar shader: %s" % s_path)
			has_errors = true
		else:
			print("  [OK] Shader valido: %s (%s)" % [s_path, s.get_class()])
			var sm = ShaderMaterial.new()
			sm.shader = s
			if sm.shader == null:
				print("  [ERROR] Falha ao atribuir shader: %s" % s_path)
				has_errors = true
	
	print("\n[2] Verificando Materiais (%d encontrados)..." % materials.size())
	for m_path in materials:
		if not FileAccess.file_exists(m_path):
			print("  [PENDING/MISSING] %s" % m_path)
			continue
		var m = ResourceLoader.load(m_path)
		if m == null:
			print("  [ERROR] Falha ao carregar material: %s" % m_path)
			has_errors = true
		else:
			print("  [OK] Material valido: %s (%s)" % [m_path, m.get_class()])
			
	print("\n========================================")
	if has_errors:
		print("STATUS: ERROS ENCONTRADOS")
		print("========================================")
		quit(1)
	else:
		print("STATUS: SUCESSO COMPLETO!")
		print("========================================")
		quit(0)
