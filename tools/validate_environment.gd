@tool
extends SceneTree

func _init():
	print("==================================================")
	print("--- BOTW VEGETATION & ENVIRONMENT VALIDATOR ---")
	print("==================================================")
	
	var has_errors = false
	
	# 1. Validar Shaders
	print("\n[1] Validando Shaders...")
	var grass_shader = load("res://shaders/botw_grass.gdshader")
	if grass_shader == null:
		print("  [ERROR] Falha ao carregar shaders/botw_grass.gdshader")
		has_errors = true
	else:
		print("  [OK] botw_grass.gdshader carregado com sucesso!")
		
	var foliage_shader = load("res://shaders/botw_foliage.gdshader")
	if foliage_shader == null:
		print("  [ERROR] Falha ao carregar shaders/botw_foliage.gdshader")
		has_errors = true
	else:
		print("  [OK] botw_foliage.gdshader carregado com sucesso!")

	# 2. Validar Materiais
	print("\n[2] Validando Materiais...")
	var grass_mat = load("res://materials/m_botw_grass.tres")
	if grass_mat == null:
		print("  [ERROR] Falha ao carregar materials/m_botw_grass.tres")
		has_errors = true
	else:
		print("  [OK] m_botw_grass.tres carregado!")
		
	var foliage_autumn = load("res://materials/m_botw_foliage_autumn.tres")
	if foliage_autumn == null:
		print("  [ERROR] Falha ao carregar materials/m_botw_foliage_autumn.tres")
		has_errors = true
	else:
		print("  [OK] m_botw_foliage_autumn.tres carregado!")

	# 3. Validar Cenas de VFX e Vegetacao
	print("\n[3] Validando Cenas de Efeitos e Vegetação...")
	var scenes_to_check = [
		"res://scenes/vfx/ambient_motes.tscn",
		"res://scenes/vfx/falling_leaves.tscn",
		"res://scenes/environment/botw_grass.tscn",
		"res://scenes/environment/tree.tscn",
		"res://scenes/environment/tree_birch_2.tscn",
		"res://scenes/environment/tree_birch_autumn.tscn",
		"res://scenes/environment/bush.tscn",
		"res://scenes/environment/bush_berries.tscn"
	]
	
	for s_path in scenes_to_check:
		if not ResourceLoader.exists(s_path):
			print("  [ERROR] Cena inexistente: %s" % s_path)
			has_errors = true
			continue
		var packed_scene = load(s_path) as PackedScene
		if packed_scene == null:
			print("  [ERROR] Falha ao carregar: %s" % s_path)
			has_errors = true
		else:
			var inst = packed_scene.instantiate()
			if inst == null:
				print("  [ERROR] Falha ao instanciar: %s" % s_path)
				has_errors = true
			else:
				print("  [OK] Cena instanciada com sucesso: %s (%s)" % [s_path, inst.name])
				inst.queue_free()

	# 4. Validar Cena Principal (Main.tscn)
	print("\n[4] Validando Integracao da Cena Principal (res://scenes/main.tscn)...")
	var main_packed = load("res://scenes/main.tscn") as PackedScene
	if main_packed == null:
		print("  [ERROR] Falha ao carregar res://scenes/main.tscn")
		has_errors = true
	else:
		var main_node = main_packed.instantiate()
		if main_node == null:
			print("  [ERROR] Falha ao instanciar res://scenes/main.tscn")
			has_errors = true
		else:
			print("  [OK] Main instanciado!")
			var grass = main_node.get_node_or_null("BotWGrass")
			if grass:
				print("    -> BotWGrass encontrado no Main!")
			else:
				print("    [ERROR] BotWGrass ausente no Main")
				has_errors = true
				
			var motes = main_node.get_node_or_null("AmbientMotes")
			if motes:
				print("    -> AmbientMotes encontrado no Main!")
			else:
				print("    [ERROR] AmbientMotes ausente no Main")
				has_errors = true
				
			var trees = main_node.get_node_or_null("Trees")
			if trees:
				print("    -> Trees: ", trees.get_child_count(), " arvores variadas presentes.")
			else:
				print("    [ERROR] Trees ausente")
				has_errors = true
				
			var bushes = main_node.get_node_or_null("Bushes")
			if bushes:
				print("    -> Bushes: ", bushes.get_child_count(), " arbustos sob copa presentes.")
			else:
				print("    [ERROR] Bushes ausente")
				has_errors = true
				
			main_node.queue_free()

	print("\n==================================================")
	if has_errors:
		print("RESULTADO: FALHA NA VALIDACAO")
		print("==================================================")
		quit(1)
	else:
		print("RESULTADO: TUDO VALIDADO E APROVADO COM SUCESSO!")
		print("==================================================")
		quit(0)
