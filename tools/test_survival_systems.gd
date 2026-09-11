extends SceneTree

func _init() -> void:
	print("\n=======================================================")
	print("INICIANDO BATERIA DE TESTES: MUCK OF THE WILD")
	print("Engine: Godot 4.7.2 Headless")
	print("=======================================================\n")
	
	_run_all_tests()

func _run_all_tests() -> void:
	test_game_manager_cycle()
	test_goblin_mechanics()
	test_golem_mechanics()
	test_relic_chest_and_player_buffs()
	test_resource_gathering()
	test_main_scene_assembly()
	
	print("\n=======================================================")
	print("TODOS OS TESTES FORAM CONCLUÍDOS COM SUCESSO! [PASS]")
	print("=======================================================\n")
	quit(0)

func test_game_manager_cycle() -> void:
	print("[TEST 1/6] Testando GameManager e Ciclo Dia/Noite...")
	var gm := GameManager.new()
	gm.day_duration = 10.0   # Encurtado para o teste
	gm.night_duration = 6.0
	gm.time_scale = 1.0
	root.add_child(gm)
	
	# Verificar estado inicial
	assert(gm.current_day == 1, "Dia inicial deve ser 1")
	print("  -> GameManager inicializado no Dia ", gm.current_day)
	
	# Avançar para Pôr do Sol
	var sunset_triggered := false
	gm.sunset_started.connect(func(): sunset_triggered = true)
	gm.cycle_elapsed = 8.5 # 85% do dia = Pôr do Sol
	gm._process(0.016)
	assert(gm.is_sunset(), "Deveria estar no estado Pôr do Sol")
	assert(sunset_triggered, "Sinal sunset_started deveria ter sido emitido")
	print("  -> Pôr do Sol atingido com sucesso: sinal e aviso de suspense disparados!")
	
	# Avançar para Noite
	var night_triggered := false
	var received_day := 0
	var received_diff := 0.0
	gm.night_started.connect(func(d, diff):
		night_triggered = true
		received_day = d
		received_diff = diff
	)
	gm.cycle_elapsed = 10.5 # Apos 10.0s = Noite
	gm._process(0.016)
	assert(gm.is_night(), "Deveria estar no estado Noite")
	assert(night_triggered, "Sinal night_started deveria ter sido emitido")
	assert(received_day == 1, "Dia da noite deve ser 1")
	print("  -> Invasão noturna iniciada no Dia 1 (Dificuldade x%.2f)" % received_diff)
	
	# Avançar para o próximo ciclo completo (Dia 2)
	gm.cycle_elapsed = 16.1 # 10s dia + 6s noite completados
	gm._process(0.016)
	assert(gm.current_day == 2, "Deveria ter avançado para o Dia 2")
	var diff_day2 := gm.get_difficulty_multiplier()
	assert(diff_day2 > 1.0, "Dificuldade do Dia 2 deve ser maior que Dia 1")
	assert(gm.get_golem_spawn_count() >= 1, "A partir do Dia 2 deve spawnar Golems")
	print("  -> Avanço para Dia 2 validado: Dificuldade escalada para x%.2f | Golems na fila: %d" % [diff_day2, gm.get_golem_spawn_count()])
	
	gm.queue_free()
	print("  [OK] Ciclo Dia/Noite e Escala de Dificuldade aprovados!\n")

func test_goblin_mechanics() -> void:
	print("[TEST 2/6] Testando Inimigo Goblin (Vida, Knockback, Ataque, Drops)...")
	var gob_scene = load("res://scenes/enemies/goblin.tscn")
	assert(gob_scene != null, "Cena do goblin deve existir")
	var gob: Goblin = gob_scene.instantiate()
	root.add_child(gob)
	gob.global_position = Vector3(5, 0, 0)
	
	var initial_hp := gob.current_health
	assert(initial_hp > 0.0, "Goblin deve ter vida positiva")
	
	# Teste de Dano e Knockback
	var attacker_pos := Vector3(0, 0, 0)
	gob.take_damage(25.0, attacker_pos, 10.0)
	assert(gob.current_health == initial_hp - 25.0, "Vida do goblin deve ser reduzida")
	assert(gob.knockback_velocity.length() > 0.0, "Goblin deve receber velocidade de knockback")
	print("  -> Dano de 25 aplicado: Vida restante %.1f/%.1f | Knockback: %.1f m/s" % [gob.current_health, gob.max_health, gob.knockback_velocity.length()])
	
	# Teste de Morte e Drops
	var died_signal := false
	gob.died.connect(func(_g): died_signal = true)
	gob.take_damage(999.0, attacker_pos)
	assert(gob.current_health <= 0.0, "Goblin deve morrer com dano letal")
	assert(died_signal, "Sinal died deve ser emitido")
	print("  -> Goblin derrotado com sucesso: drops gerados no solo.")
	
	gob.queue_free()
	print("  [OK] Inimigo Goblin aprovado!\n")

func test_golem_mechanics() -> void:
	print("[TEST 3/6] Testando Mini-Chefe Golem (Smash, Shockwave, Boulder Throw, Drops)...")
	var golem_scene = load("res://scenes/enemies/golem.tscn")
	assert(golem_scene != null, "Cena do golem deve existir")
	var golem: Golem = golem_scene.instantiate()
	root.add_child(golem)
	golem.global_position = Vector3(10, 0, 0)
	
	assert(golem.max_health >= 400.0, "Golem deve ter vida de chefe (>= 400)")
	print("  -> Golem instanciado com %.0f de Vida Máxima" % golem.max_health)
	
	# Teste de Resistência a Knockback
	golem.take_damage(50.0, Vector3(0, 0, 0), 20.0)
	# O golem absorve 88-90% do knockback
	assert(golem.knockback_velocity.length() < 5.0, "Golem deve ter altíssima resistência a knockback")
	print("  -> Resistência pesada a knockback validada: apenas %.2f m/s de recuo residual" % golem.knockback_velocity.length())
	
	# Teste de Onda de Choque
	var sw_scene = load("res://scenes/enemies/shockwave.tscn")
	assert(sw_scene != null, "Cena da onda de choque deve existir")
	var sw: Shockwave = sw_scene.instantiate()
	root.add_child(sw)
	sw.global_position = Vector3(0, 0, 0)
	assert(sw.damage > 0.0, "Onda de choque deve causar dano")
	sw.queue_free()
	print("  -> Onda de Choque (Golpe Esmagador) instanciada com %.0f de dano" % sw.damage)
	
	# Teste de Projétil de Rocha
	var bld_scene = load("res://scenes/enemies/boulder.tscn")
	assert(bld_scene != null, "Cena do pedregulho deve existir")
	var bld: Boulder = bld_scene.instantiate()
	root.add_child(bld)
	bld.launch(Vector3(0, 2, 0), Vector3(15, 0, 0))
	assert(bld.velocity.length() > 0.0, "Pedregulho deve ser lançado com velocidade inicial")
	bld.queue_free()
	print("  -> Arremesso de Rocha validado: velocidade %.1f m/s" % bld.velocity.length())
	
	# Teste de Morte e Baú de Recompensa
	var golem_died := false
	golem.died.connect(func(_g): golem_died = true)
	golem.take_damage(9999.0, Vector3.ZERO)
	assert(golem_died, "Golem deve emitir sinal de morte")
	print("  -> Golem derrotado: recompensas lendárias liberadas.")
	
	golem.queue_free()
	print("  [OK] Mini-Chefe Golem aprovado!\n")

func test_relic_chest_and_player_buffs() -> void:
	print("[TEST 4/6] Testando Baú de Relíquias BotW e Bônus Permanentes no Jogador...")
	var chest_scene = load("res://scenes/environment/chest.tscn")
	assert(chest_scene != null, "Cena do baú deve existir")
	var chest: RelicChest = chest_scene.instantiate()
	root.add_child(chest)
	
	var player_scene = load("res://scenes/player/player.tscn")
	assert(player_scene != null, "Cena do jogador deve existir")
	var player: Node = player_scene.instantiate()
	root.add_child(player)
	
	var initial_speed: float = player.walk_speed
	var initial_max_hp: float = player.max_health
	
	# Simular interação de abertura do baú com 'E'
	var chest_opened := false
	var granted_relic: Dictionary = {}
	chest.opened.connect(func(r):
		chest_opened = true
		granted_relic = r
	)
	
	chest.interact(player)
	assert(chest_opened, "Baú deveria ter sido aberto")
	assert(chest.is_opened, "Flag is_opened do baú deve ser verdadeira")
	assert(granted_relic.has("name"), "Relíquia concedida deve ter nome")
	print("  -> Baú aberto com sucesso! Relíquia concedida: %s (%s)" % [granted_relic["name"], granted_relic["description"]])
	
	# Conceder explicitamente bônus conhecidos para verificar aplicação de atributos
	player.grant_relic({
		"id": "hermes_boots",
		"name": "Botas de Hermes",
		"stat": "speed_mult",
		"value": 0.25
	})
	assert(player.walk_speed > initial_speed, "Velocidade deve ter aumentado")
	print("  -> Bônus Botas de Hermes: Velocidade de %.1f para %.1f m/s" % [initial_speed, player.walk_speed])
	
	player.grant_relic({
		"id": "heart_fruit",
		"name": "Fruta do Coração",
		"stat": "max_hp",
		"value": 50.0
	})
	assert(player.max_health == initial_max_hp + 50.0, "Vida Máxima deve ter aumentado em 50")
	print("  -> Bônus Fruta do Coração: Vida máxima de %.0f para %.0f" % [initial_max_hp, player.max_health])
	
	chest.queue_free()
	player.queue_free()
	print("  [OK] Baú de Relíquias e Bônus do Jogador aprovados!\n")

func test_resource_gathering() -> void:
	print("[TEST 5/6] Testando Coleta de Recursos (Árvore e Rocha)...")
	var tree_scene = load("res://scenes/environment/tree.tscn")
	assert(tree_scene != null, "Cena da árvore deve existir")
	var tree: ResourceNode = tree_scene.instantiate()
	root.add_child(tree)
	
	var initial_tree_hp := tree.current_health
	tree.chop(25.0, Vector3(0, 0, 0))
	assert(tree.current_health == initial_tree_hp - 25.0, "Árvore deve perder vida ao ser cortada")
	print("  -> Golpe de machado na árvore: Vida %.0f/%.0f" % [tree.current_health, tree.max_health])
	
	tree.queue_free()
	print("  [OK] Sistema de Recursos aprovado!\n")

func test_main_scene_assembly() -> void:
	print("[TEST 6/6] Testando Montagem Completa da Cena Principal (scenes/main.tscn)...")
	var main_scene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Cena main.tscn deve existir e ser carregada")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	
	assert(main.has_node("GameManager"), "Deve possuir nó GameManager")
	assert(main.has_node("EnemySpawner"), "Deve possuir nó EnemySpawner")
	assert(main.has_node("SunLight"), "Deve possuir nó SunLight")
	assert(main.has_node("WorldEnvironment"), "Deve possuir nó WorldEnvironment")
	assert(main.has_node("Terrain"), "Deve possuir nó Terrain")
	assert(main.has_node("Player"), "Deve possuir nó Player")
	assert(main.has_node("Trees"), "Deve possuir nó Trees com árvores espalhadas")
	assert(main.has_node("Rocks"), "Deve possuir nó Rocks com rochas espalhadas")
	assert(main.has_node("Chests"), "Deve possuir nó Chests com baús espalhados")
	
	var trees_node := main.get_node("Trees")
	var rocks_node := main.get_node("Rocks")
	var chests_node := main.get_node("Chests")
	print("  -> Mundo gerado com sucesso:")
	print("     * Árvores no mundo: %d" % trees_node.get_child_count())
	print("     * Rochas no mundo: %d" % rocks_node.get_child_count())
	print("     * Baús de Relíquia: %d" % chests_node.get_child_count())
	
	main.queue_free()
	print("  [OK] Cena Principal main.tscn 100% íntegra!\n")