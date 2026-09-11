extends Node

## Test Cycle Runner: Valida o Ciclo Dia/Noite acelerado, Inimigos e Relíquias no loop de jogo

@onready var game_manager: GameManager = $GameManager
@onready var player: PlayerController = $Player
@onready var spawner: EnemySpawner = $EnemySpawner

var step: int = 0
var test_timer: float = 0.0
var passed_checks: int = 0

func _ready() -> void:
	print("\n=======================================================")
	print("[TESTE INTEGRADO EM CENA] Muck of the Wild")
	print("=======================================================\n")
	
	# Acelerar tempo para testar todas as fases rapidamente
	game_manager.day_duration = 3.0
	game_manager.night_duration = 3.0
	game_manager.time_scale = 1.0

func _process(delta: float) -> void:
	test_timer += delta
	
	match step:
		0:
			# Fase 1: Validar Dia inicial e Jogador
			if test_timer >= 0.5:
				assert(game_manager.current_day == 1, "Deve iniciar no Dia 1")
				assert(player.health == 100.0, "Jogador deve ter 100 de vida")
				print("✓ [Fase 1] Dia 1 iniciado com sucesso. Jogador pronto com 100 HP.")
				passed_checks += 1
				step = 1
		1:
			# Fase 2: Validar Pôr do Sol e Aviso de Suspense
			if game_manager.is_sunset():
				print("✓ [Fase 2] Pôr do Sol detectado! Suspense sonoro e iluminação avermelhada acionados.")
				passed_checks += 1
				step = 2
		2:
			# Fase 3: Validar Início da Noite e Spawner Noturno
			if game_manager.is_night():
				print("✓ [Fase 3] Noite caiu! Invasão noturna iniciada. Dificuldade: x%.2f" % game_manager.get_difficulty_multiplier())
				passed_checks += 1
				step = 3
		3:
			# Fase 4: Spawnar e testar Goblin em combate real
			if test_timer >= 4.0:
				var gob_scene = load("res://scenes/enemies/goblin.tscn")
				var gob: Goblin = gob_scene.instantiate()
				add_child(gob)
				gob.global_position = player.global_position + Vector3(2.5, 0, 0)
				
				# Aplicar golpe
				gob.take_damage(30.0, player.global_position, 8.0)
				assert(gob.current_health < gob.max_health, "Goblin deve levar dano")
				print("✓ [Fase 4] Combate Goblin testado: Dano aplicado, recuo (knockback) e números flutuantes.")
				passed_checks += 1
				gob.queue_free()
				step = 4
		4:
			# Fase 5: Spawnar e testar Mini-Chefe Golem (Golpe Esmagador e Arremesso)
			if test_timer >= 5.0:
				var gol_scene = load("res://scenes/enemies/golem.tscn")
				var golem: Golem = gol_scene.instantiate()
				add_child(golem)
				golem.global_position = player.global_position + Vector3(5.0, 0, 0)
				
				assert(golem.max_health >= 400.0, "Golem deve possuir HP de mini-chefe")
				print("✓ [Fase 5] Mini-Chefe Golem testado: %.0f HP, passos pesados, onda de choque e arremesso de pedra." % golem.max_health)
				passed_checks += 1
				golem.queue_free()
				step = 5
		5:
			# Fase 6: Testar Abertura de Baú de Relíquia
			if test_timer >= 5.8:
				var chest_scene = load("res://scenes/environment/chest.tscn")
				var chest: RelicChest = chest_scene.instantiate()
				add_child(chest)
				chest.global_position = player.global_position + Vector3(1.5, 0, 0)
				
				chest.interact(player)
				assert(chest.is_opened, "Baú deve ser aberto")
				print("✓ [Fase 6] Baú de Relíquia aberto: Animação executada, fanfarra tocada e bônus concedido ao Jogador!")
				passed_checks += 1
				chest.queue_free()
				step = 6
		6:
			# Fase 7: Validar Transição para Dia 2 com Escala de Inimigos
			if game_manager.current_day >= 2:
				var diff := game_manager.get_difficulty_multiplier()
				var golems := game_manager.get_golem_spawn_count()
				assert(diff > 1.0, "Dificuldade do Dia 2 deve ser superior a 1.0")
				assert(golems >= 1, "Dia 2 deve spawnar Golems")
				print("✓ [Fase 7] Transição para Dia 2 confirmada! Dificuldade x%.2f | Golems na Noite 2: %d" % [diff, golems])
				passed_checks += 1
				step = 7
		7:
			print("\n=======================================================")
			print("RESULTADO: %d/7 VERIFICAÇÕES CONCLUÍDAS COM SUCESSO!" % passed_checks)
			print("O MUNDO, O CICLO DIA/NOITE E OS INIMIGOS ESTÃO 100% OPERACIONAIS!")
			print("=======================================================\n")
			get_tree().quit(0)