@tool
extends SceneTree

func _init():
	print("========================================")
	print("--- Shaders & Materials Validator ---")
	print("========================================")
	
	var shaders = [
		"res://shaders/botw_cel.gdshader",
		"res://shaders/botw_foliage.gdshader",
		"res://shaders/botw_grass.gdshader",
		"res://shaders/botw_water.gdshader",
		"res://shaders/botw_sky.gdshader"
	]
	
	var materials = [
		"res://materials/m_botw_cel_default.tres",
		"res://materials/m_botw_cel_character.tres",
		"res://materials/m_botw_cel_rock.tres",
		"res://materials/m_botw_foliage.tres",
		"res://materials/m_botw_grass.tres",
		"res://materials/m_botw_water.tres",
		"res://materials/m_botw_sky.tres"
	]
	
	var has_errors = false
	
	print("\n[1] Verificando Shaders...")
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
	
	print("\n[2] Verificando Materiais...")
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
		print("STATUS: SUCESSO!")
		print("========================================")
		quit(0)
