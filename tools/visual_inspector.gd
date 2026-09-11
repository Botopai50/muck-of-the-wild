extends SceneTree

## Inspetor Visual Automatizado para Avaliacao Estilo BotW + Muck
## Renderiza capturas de alta definicao em diferentes condicoes e angulos para inspecao visual

var frame_count: int = 0
var main_scene: Node = null
var cam: Camera3D = null
var current_step: int = 0
var wait_frames: int = 0

func _init() -> void:
	print("[VisualInspector] Iniciando auditoria visual...")
	DirAccess.make_dir_absolute("res://captures")

func _process(_delta: float) -> bool:
	frame_count += 1
	
	if frame_count == 2:
		# Instancia a cena principal
		var packed = load("res://scenes/main.tscn")
		if not packed:
			print("[VisualInspector] ERRO: Falha ao carregar scenes/main.tscn")
			quit(1)
			return true
		main_scene = packed.instantiate()
		root.add_child(main_scene)
		
		# Cria camera cinematica de captura (permanece inativa ate ser chamada)
		cam = Camera3D.new()
		main_scene.add_child(cam)
		wait_frames = 20
		return false
	
	if wait_frames > 0:
		wait_frames -= 1
		return false
		
	match current_step:
		0:
			# Captura 1: Visao em primeira pessoa do jogador
			print("[VisualInspector] Capturando 1/5: Visao em Primeira Pessoa (Viewmodel + Ilha)")
			_setup_first_person_cam()
			wait_frames = 12
			current_step += 1
			
		1:
			_save_screenshot("res://captures/01_first_person_gameplay.png")
			# Captura 2: Vista panoramica ampla da Ilha ao Meio-dia
			print("[VisualInspector] Capturando 2/5: Vista Panoramica Estilo BotW (Great Plateau)")
			_setup_island_vista()
			wait_frames = 12
			current_step += 1
			
		2:
			_save_screenshot("res://captures/02_island_vista_noon.png")
			# Captura 3: Entardecer dramático (Sunset Haze)
			print("[VisualInspector] Capturando 3/5: Entardecer Dourado/Magenta (Sunset)")
			_setup_sunset()
			wait_frames = 12
			current_step += 1
			
		3:
			_save_screenshot("res://captures/03_sunset_dusk_haze.png")
			# Captura 4: Noite cósmica com invasão de Goblins e Golens
			print("[VisualInspector] Capturando 4/5: Invasao Noturna de Muck com Lua Estilizada")
			_setup_night_invasion()
			wait_frames = 15
			current_step += 1
			
		4:
			_save_screenshot("res://captures/04_night_invasion_horde.png")
			# Captura 5: Close-up de corte de árvore e mineração com cel-shading e rim light
			print("[VisualInspector] Capturando 5/5: Detalhe de Cel-shading e Rim Light em Recursos")
			_setup_resource_closeup()
			wait_frames = 12
			current_step += 1
			
		5:
			_save_screenshot("res://captures/05_cel_shading_rim_light_detail.png")
			print("[VisualInspector] Todas as 5 capturas foram geradas com sucesso em res://captures/!")
			quit(0)
			return true

	return false

func _setup_first_person_cam() -> void:
	if not main_scene:
		return
	var gm = main_scene.get_node_or_null("GameManager")
	if gm:
		gm.cycle_elapsed = gm.day_duration * 0.22 # ~09:30 da manha
		gm._update_cycle_state(true)
		gm._apply_lighting_and_atmosphere(1.0)
		gm._notify_time_tick()
	var player_node = main_scene.get_node_or_null("Player")
	if player_node:
		player_node.rotation_degrees.y = -35.0
		if player_node.has_method("equip_slot"):
			player_node.equip_slot(1) # Machado na hotbar e viewmodel

func _setup_island_vista() -> void:
	if not cam or not main_scene:
		return
	var gm = main_scene.get_node_or_null("GameManager")
	if gm:
		gm.cycle_elapsed = gm.day_duration * 0.45 # ~12:00 meio-dia BotW
		gm._update_cycle_state(true)
		gm._apply_lighting_and_atmosphere(1.0)
		gm._notify_time_tick()
	cam.make_current()
	cam.global_position = Vector3(-35, 22, 38)
	cam.look_at(Vector3(0, 2, 0), Vector3.UP)
	cam.fov = 68.0

func _setup_sunset() -> void:
	if not main_scene:
		return
	var gm = main_scene.get_node_or_null("GameManager")
	if gm:
		gm.cycle_elapsed = gm.day_duration * 0.92 # ~18:45 entardecer dourado/magenta
		gm._update_cycle_state(true)
		gm._apply_lighting_and_atmosphere(1.0)
		gm._notify_time_tick()
	if cam:
		cam.make_current()
		cam.global_position = Vector3(25, 8, -25)
		cam.look_at(Vector3(-10, 3, 10), Vector3.UP)
		cam.fov = 70.0

func _setup_night_invasion() -> void:
	if not main_scene:
		return
	var gm = main_scene.get_node_or_null("GameManager")
	if gm:
		gm.cycle_elapsed = gm.day_duration + gm.night_duration * 0.45 # ~00:00 meia-noite
		gm._update_cycle_state(true)
		gm._apply_lighting_and_atmosphere(1.0)
		gm._notify_time_tick()
			
	# Força spawn de monstros perto da câmera para a foto
	var goblin_scn = load("res://scenes/enemies/goblin.tscn")
	var golem_scn = load("res://scenes/enemies/golem.tscn")
	if goblin_scn:
		for i in range(3):
			var g = goblin_scn.instantiate()
			main_scene.add_child(g)
			g.global_position = Vector3(-4 + i * 4.0, 2.0, -6 + randf_range(-1, 1))
	if golem_scn:
		var colossus = golem_scn.instantiate()
		main_scene.add_child(colossus)
		colossus.global_position = Vector3(5, 2.0, -12)
		colossus.scale = Vector3(1.4, 1.4, 1.4)
		
	if cam:
		cam.make_current()
		cam.global_position = Vector3(0, 3.8, 2)
		cam.look_at(Vector3(1, 2.2, -8), Vector3.UP)
		cam.fov = 72.0

func _setup_resource_closeup() -> void:
	if not cam or not main_scene:
		return
	var gm = main_scene.get_node_or_null("GameManager")
	if gm:
		gm.cycle_elapsed = gm.day_duration * 0.30 # ~10:45 manha ensolarada com luz obliqua
		gm._update_cycle_state(true)
		gm._apply_lighting_and_atmosphere(1.0)
		gm._notify_time_tick()
	var hud = main_scene.get_node_or_null("Player/HUD")
	if hud and "alert_banner_label" in hud and hud.alert_banner_label:
		hud.alert_banner_label.visible = false
	cam.make_current()
	cam.global_position = Vector3(-10, 3.2, -5)
	cam.look_at(Vector3(-12, 2.8, -8), Vector3.UP)
	cam.fov = 60.0

func _save_screenshot(path: String) -> void:
	var vp = root.get_viewport()
	if not vp:
		return
	var tex = vp.get_texture()
	if not tex:
		return
	var img = tex.get_image()
	if img:
		img.save_png(path)
		print("[VisualInspector] Salvo: " + path)
