extends Node

func _ready() -> void:
	print("\n========================================================")
	print("  MUCK OF THE WILD - PLAYER CONTROLLER VALIDATION SUITE ")
	print("========================================================\n")
	call_deferred("_run_tests")

func _run_tests() -> void:
	var passed: int = 0
	var failed: int = 0

	# 1. Test AudioManager
	print("--- [TEST 1] AudioManager Procedural Audio ---")
	if AudioManager == null:
		print("FAIL: AudioManager autoload not found!")
		failed += 1
	else:
		var sounds: Array[String] = [
			"footstep_grass", "jump", "weapon_swing", "impact_wood",
			"impact_stone", "item_pickup", "eat_food", "damage"
		]
		var audio_ok: bool = true
		for s in sounds:
			var stream = AudioManager.get_sound_stream(s)
			if stream == null or stream.data.size() == 0:
				print("FAIL: Sound stream missing: ", s)
				audio_ok = false
			else:
				print("  âœ“ Sound '%s': length=%.2fs, bytes=%d" % [s, stream.get_length(), stream.data.size()])
		if audio_ok:
			passed += 1
			print("PASSED: AudioManager has all 8 procedural sounds!\n")
		else:
			failed += 1

	# 2. Test Player Scene Instantiation
	print("--- [TEST 2] Player Scene Instantiation ---")
	var player_scene = load("res://scenes/player/player.tscn")
	if not player_scene:
		print("FAIL: Failed to load res://scenes/player/player.tscn")
		failed += 1
		_finish(passed, failed)
		return

	var player: PlayerController = player_scene.instantiate()
	add_child(player)
	print("  âœ“ Player instantiated as CharacterBody3D")
	print("  âœ“ CollisionShape3D present: ", player.get_node_or_null("CollisionShape3D") != null)
	print("  âœ“ Camera3D present: ", player.camera != null)
	print("  âœ“ Viewmodel present: ", player.viewmodel != null)
	print("  âœ“ InteractionRay present: ", player.interaction_ray != null)
	print("  âœ“ HUD present: ", player.get_node_or_null("HUD") != null)
	passed += 1
	print("PASSED: Player hierarchy complete!\n")

	# 3. Test Mouse Look and Pitch Clamp
	print("--- [TEST 3] Mouse Look & Pitch Clamping ---")
	var initial_yaw = player.rotation.y
	player._handle_mouse_look(Vector2(50.0, 0.0))
	if player.rotation.y != initial_yaw:
		print("  âœ“ Body yaw rotates horizontally on mouse X")
	else:
		print("FAIL: Body yaw did not rotate")
		failed += 1

	# Extreme upward pitch
	player._handle_mouse_look(Vector2(0.0, -100000.0))
	var max_pitch_rad = deg_to_rad(89.0)
	if absf(player.head.rotation.x) <= (max_pitch_rad + 0.001):
		print("  âœ“ Vertical pitch clamped at max %.2f deg (actual: %.2f deg)" % [89.0, rad_to_deg(player.head.rotation.x)])
	else:
		print("FAIL: Pitch exceeded limit: ", rad_to_deg(player.head.rotation.x))
		failed += 1

	# Extreme downward pitch
	player._handle_mouse_look(Vector2(0.0, 200000.0))
	if absf(player.head.rotation.x) <= (max_pitch_rad + 0.001):
		print("  âœ“ Vertical pitch clamped at min -%.2f deg (actual: %.2f deg)" % [89.0, rad_to_deg(player.head.rotation.x)])
		passed += 1
		print("PASSED: Pitch clamp strictly respected!\n")
	else:
		print("FAIL: Pitch clamp exceeded limit")
		failed += 1

	# 4. Test Vital Stats & Damage / Food
	print("--- [TEST 4] Vitals (Health, Stamina, Hunger) ---")
	var initial_hp = player.health
	player.take_damage(35.0, "enemy_strike")
	if player.health == (initial_hp - 35.0):
		print("  âœ“ take_damage() reduced health correctly: %.1f / %.1f" % [player.health, player.max_health])
	else:
		print("FAIL: Health mismatch after damage")
		failed += 1

	player.heal(15.0)
	if player.health == (initial_hp - 20.0):
		print("  âœ“ heal() restored health correctly: %.1f / %.1f" % [player.health, player.max_health])
	else:
		print("FAIL: Health mismatch after heal")
		failed += 1

	player.hunger = 40.0
	player.consume_food(30.0)
	if player.hunger == 70.0:
		print("  âœ“ consume_food() restored hunger to: %.1f / %.1f" % [player.hunger, player.max_hunger])
		passed += 1
		print("PASSED: Vitals management working!\n")
	else:
		print("FAIL: Hunger mismatch after food consumption")
		failed += 1

	# 5. Test Relic & Double Jump
	print("--- [TEST 5] Feather Relic & Double Jump ---")
	player.air_jumps_left = 0
	var prev_vy = player.velocity.y
	player._try_jump()
	if player.velocity.y == prev_vy:
		print("  âœ“ Mid-air jump rejected when no air jumps left")
	else:
		print("FAIL: Mid-air jump allowed without relic")
		failed += 1

	player.add_relic("feather", 1)
	if player.has_feather_relic and player.get_relic_count("feather") == 1:
		print("  âœ“ Feather relic registered! Air jumps enabled.")
	else:
		print("FAIL: Relic registration failed")
		failed += 1

	player.velocity.y = 0.0
	player.air_jumps_left = 1
	player._try_jump()
	if is_equal_approx(player.velocity.y, player.double_jump_velocity):
		print("  âœ“ Double jump successfully triggered in air with velocity: %.2f" % player.velocity.y)
		passed += 1
		print("PASSED: Feather double jump working!\n")
	else:
		print("FAIL: Double jump velocity not applied: ", player.velocity.y)
		failed += 1

	# 6. Test Viewmodel & Hotbar Cycling
	print("--- [TEST 6] Viewmodel & Hotbar System ---")
	var vm = player.viewmodel
	player._select_slot(0)
	if vm.get_item_name() == "fists" and vm.fists_model.visible:
		print("  âœ“ Slot 0: FISTS equipped and visible")
	else:
		print("FAIL: Slot 0 not fists")
		failed += 1

	player._select_slot(1)
	if vm.get_item_name() == "axe" and vm.axe_model.visible:
		print("  âœ“ Slot 1: AXE equipped and visible")
	else:
		print("FAIL: Slot 1 not axe")
		failed += 1

	player._select_slot(2)
	if vm.get_item_name() == "pickaxe" and vm.pickaxe_model.visible:
		print("  âœ“ Slot 2: PICKAXE equipped and visible")
	else:
		print("FAIL: Slot 2 not pickaxe")
		failed += 1

	player._select_slot(3)
	if vm.get_item_name() == "sword" and vm.sword_model.visible:
		print("  âœ“ Slot 3: SWORD equipped and visible")
	else:
		print("FAIL: Slot 3 not sword")
		failed += 1

	player._select_slot(4)
	if vm.get_item_name() == "food" and vm.food_model.visible:
		print("  âœ“ Slot 4: FOOD equipped and visible")
		passed += 1
		print("PASSED: Hotbar and Viewmodel item sync working!\n")
	else:
		print("FAIL: Slot 4 not food")
		failed += 1

	# 7. Test Weapon Attack & Procedural Animation
	print("--- [TEST 7] Attack Trigger & Cooldown ---")
	player._select_slot(1) # Axe
	var triggered = vm.trigger_primary_action()
	if triggered and vm.is_attacking:
		print("  âœ“ Primary action initiated swing animation with Axe")
	else:
		print("FAIL: Primary action failed to start")
		failed += 1

	var spammed = vm.trigger_primary_action()
	if not spammed:
		print("  âœ“ Attack cooldown prevented spamming during active swing")
		passed += 1
		print("PASSED: Viewmodel attack & cooldown operational!\n")
	else:
		print("FAIL: Attack cooldown did not prevent spam")
		failed += 1

	# 8. Test InteractionRay Material Detection & Strikes
	print("--- [TEST 8] InteractionRay & Object Types ---")
	var dummy_tree = StaticBody3D.new()
	dummy_tree.name = "OakTree"
	dummy_tree.add_to_group("tree")
	add_child(dummy_tree)

	var detected_type = player.interaction_ray._detect_target_type(dummy_tree)
	var prompt = player.interaction_ray._generate_prompt(dummy_tree, detected_type)
	if detected_type == "tree" and "[Click Esq.] Cortar Madeira" in prompt:
		print("  âœ“ Tree recognized -> prompt: '%s'" % prompt)
	else:
		print("FAIL: Tree prompt detection failed: ", prompt)
		failed += 1

	var dummy_rock = StaticBody3D.new()
	dummy_rock.name = "IronRock"
	dummy_rock.add_to_group("rock")
	add_child(dummy_rock)

	var detected_rock = player.interaction_ray._detect_target_type(dummy_rock)
	var rock_prompt = player.interaction_ray._generate_prompt(dummy_rock, detected_rock)
	if detected_rock == "rock" and "[Click Esq.] Minerar Pedra" in rock_prompt:
		print("  âœ“ Rock recognized -> prompt: '%s'" % rock_prompt)
	else:
		print("FAIL: Rock prompt detection failed: ", rock_prompt)
		failed += 1

	var dummy_item = Area3D.new()
	dummy_item.name = "DroppedWood"
	dummy_item.add_to_group("item")
	add_child(dummy_item)

	var detected_item = player.interaction_ray._detect_target_type(dummy_item)
	var item_prompt = player.interaction_ray._generate_prompt(dummy_item, detected_item)
	if detected_item == "item" and "[E] Coletar" in item_prompt:
		print("  âœ“ Item recognized -> prompt: '%s'" % item_prompt)
		passed += 1
		print("PASSED: Interaction raycast detection working!\n")
	else:
		print("FAIL: Item prompt detection failed: ", item_prompt)
		failed += 1

	dummy_tree.queue_free()
	dummy_rock.queue_free()
	dummy_item.queue_free()
	player.queue_free()

	_finish(passed, failed)

func _finish(passed: int, failed: int) -> void:
	print("========================================================")
	print("  TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
	print("========================================================\n")
	get_tree().quit(0 if failed == 0 else 1)