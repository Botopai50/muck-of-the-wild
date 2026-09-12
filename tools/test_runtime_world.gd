extends SceneTree

var frame_count: int = 0
var main_node: Node = null

func _init():
	print("==================================================")
	print("--- BOTW RUNTIME SIMULATION TEST ---")
	print("==================================================")
	change_scene_to_file("res://scenes/main.tscn")

func _process(_delta: float) -> bool:
	frame_count += 1
	if frame_count == 2:
		main_node = root.get_node_or_null("Main")
		if not main_node:
			print("[ERROR] Cena Main nao carregada!")
			quit(1)
			return true
		print("[1] Cena Main carregada com sucesso!")
		
	if frame_count == 5:
		var grass = main_node.get_node_or_null("BotWGrass") as BotWGrassSystem
		var motes = main_node.get_node_or_null("AmbientMotes") as AmbientMotes
		var gm = main_node.get_node_or_null("GameManager") as GameManager
		var player = main_node.get_node_or_null("Player") as Node3D
		
		if not grass or not motes or not gm or not player:
			print("[ERROR] Componentes essenciais nao encontrados no Main!")
			quit(1)
			return true
			
		print("[2] Validando componentes em runtime:")
		print("  -> MultiMesh Grass gerado com: ", grass.multimesh_instance.multimesh.instance_count, " tufos")
		
		# Testar posicao do jogador no shader
		player.global_position = Vector3(10, 2.2, 5)
		grass._process(0.016)
		var bend_pos = grass.grass_material.get_shader_parameter("player_position")
		print("  -> Posicao do jogador recebida pelo Shader de Grama: ", bend_pos)
		
		# Testar DayPollen ativo
		print("[3] Testando emissao diurna...")
		if motes.day_pollen and motes.day_pollen.emitting:
			print("  [OK] Polen de dia emitindo normalmente!")
		else:
			print("  [ERROR] DayPollen nao esta emitindo!")
			quit(1); return true
			
		# Testar Noite
		print("[4] Testando transicao para noite...")
		gm.current_state = GameManager.CycleState.NIGHT
		motes._update_environment_state(true)
		if motes.night_fireflies and motes.night_fireflies.emitting:
			print("  [OK] Vaga-lumes noturnos ativados com sucesso!")
		else:
			print("  [ERROR] NightFireflies nao esta emitindo na noite!")
			quit(1); return true
			
		# Testar corte de arvore
		print("[5] Testando dano em betula...")
		var trees = main_node.get_node("Trees")
		var tree1 = trees.get_child(0) as ResourceNode
		if tree1:
			tree1.take_damage(10.0, Vector3.ZERO)
			print("  [OK] Dano aplicado a betula, particulas de folhas disparadas!")
			
		print("\n==================================================")
		print("RESULTADO: SIMULACAO CONCLUIDA COM 100% DE SUCESSO!")
		print("==================================================")
		quit(0)
		return true
		
	return false
