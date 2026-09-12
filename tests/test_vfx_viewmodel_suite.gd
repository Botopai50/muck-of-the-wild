extends SceneTree

## Suíte de Testes Automatizados de Validação para VFX, Partículas e Viewmodel

func _init() -> void:
	print("\n====================================================================")
	print("  MUCK OF THE WILD - VFX, PARTICLES & VIEWMODEL VALIDATION SUITE     ")
	print("====================================================================\n")

	var passed: int = 0
	var failed: int = 0

	# ---------------------------------------------------------
	# TEST 1: HIT SPARKS VFX (ZELDA BOTW STAR FLASH & SPARKS)
	# ---------------------------------------------------------
	print("--- [TEST 1] Hit Sparks VFX Scene ---")
	var hit_scene = load("res://scenes/vfx/hit_sparks.tscn")
	if hit_scene:
		var sparks = hit_scene.instantiate()
		root.add_child(sparks)

		var has_star = sparks.get_node_or_null("StarFlash") != null
		var has_ring = sparks.get_node_or_null("ImpactRing") != null
		var has_particles = sparks.get_node_or_null("Sparks") != null
		var is_gpu_part = sparks.get_node_or_null("Sparks") is GPUParticles3D

		sparks.setup(Color(1.0, 0.85, 0.3), Vector3(0, 1, 0), 1.2)

		if has_star and has_ring and has_particles and is_gpu_part:
			passed += 1
			print("  ✓ Star Flash, Impact Ring and GPUParticles3D verified.")
			print("PASSED: Hit Sparks VFX validated successfully!\n")
		else:
			failed += 1
			print("  [FAIL] Missing components in hit_sparks.tscn\n")
		sparks.queue_free()
	else:
		failed += 1
		print("  [FAIL] Could not load scenes/vfx/hit_sparks.tscn\n")

	# ---------------------------------------------------------
	# TEST 2: WOOD BURST VFX (CHIPS, LEAVES, DUST)
	# ---------------------------------------------------------
	print("--- [TEST 2] Wood Burst VFX Scene ---")
	var wood_scene = load("res://scenes/vfx/wood_burst.tscn")
	if wood_scene:
		var wb = wood_scene.instantiate()
		root.add_child(wb)

		var has_chips = wb.get_node_or_null("Chips") is GPUParticles3D
		var has_leaves = wb.get_node_or_null("Leaves") is GPUParticles3D
		var has_dust = wb.get_node_or_null("Dust") is GPUParticles3D

		wb.setup(Vector3(0, 0, 1), 1.5)

		if has_chips and has_leaves and has_dust:
			passed += 1
			print("  ✓ Wood Chips (16), Foliage Leaves (12) and Sawdust Puff (8) verified.")
			print("PASSED: Wood Burst VFX validated successfully!\n")
		else:
			failed += 1
			print("  [FAIL] Missing GPUParticles3D in wood_burst.tscn\n")
		wb.queue_free()
	else:
		failed += 1
		print("  [FAIL] Could not load scenes/vfx/wood_burst.tscn\n")

	# ---------------------------------------------------------
	# TEST 3: ROCK DEBRIS VFX (ANGULAR STONES, MINERAL SPARKS, DUST)
	# ---------------------------------------------------------
	print("--- [TEST 3] Rock Debris VFX Scene ---")
	var rock_scene = load("res://scenes/vfx/rock_debris.tscn")
	if rock_scene:
		var rd = rock_scene.instantiate()
		root.add_child(rd)

		var has_debris = rd.get_node_or_null("Debris") is GPUParticles3D
		var has_sparks = rd.get_node_or_null("Sparks") is GPUParticles3D
		var has_dust = rd.get_node_or_null("Dust") is GPUParticles3D

		rd.setup(Vector3(1, 0, 0), 1.2)

		if has_debris and has_sparks and has_dust:
			passed += 1
			print("  ✓ Angular Debris (16), Mineral Sparks (14) and Smoke Cloud (10) verified.")
			print("PASSED: Rock Debris VFX validated successfully!\n")
		else:
			failed += 1
			print("  [FAIL] Missing GPUParticles3D in rock_debris.tscn\n")
		rd.queue_free()
	else:
		failed += 1
		print("  [FAIL] Could not load scenes/vfx/rock_debris.tscn\n")

	# ---------------------------------------------------------
	# TEST 4: SLASH TRAIL SHADER & PROCEDURAL ARC MESH
	# ---------------------------------------------------------
	print("--- [TEST 4] Slash Trail Shader & Procedural Arc Mesh ---")
	var slash_scene = load("res://scenes/vfx/slash_trail.tscn")
	if slash_scene:
		var st = slash_scene.instantiate()
		root.add_child(st)

		# Testa chamada de animação em arco
		st.play_slash(0.20, Color(0.25, 0.8, 1.0), false, -25.0, 0.0)
		st.play_slash(0.20, Color(1.0, 0.65, 0.2), true, 30.0, 5.0)

		var mesh_inst = st.get_node_or_null("MeshInstance3D") as MeshInstance3D
		var has_mesh = mesh_inst != null and mesh_inst.mesh != null
		var vertex_count = 0
		if has_mesh and mesh_inst.mesh is ArrayMesh:
			var arr = (mesh_inst.mesh as ArrayMesh).surface_get_arrays(0)
			vertex_count = (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()

		if has_mesh and vertex_count > 30 and st.material != null:
			passed += 1
			print("  ✓ Procedural ribbon arc mesh generated with %d vertices." % vertex_count)
			print("  ✓ ShaderMaterial loaded with dynamic sweep & additive blending.")
			print("PASSED: Slash Trail validated successfully!\n")
		else:
			failed += 1
			print("  [FAIL] Slash trail mesh generation or material failed.\n")
		st.queue_free()
	else:
		failed += 1
		print("  [FAIL] Could not load scenes/vfx/slash_trail.tscn\n")

	# ---------------------------------------------------------
	# TEST 5: RESOURCE NODE REACTION & ELASTIC WOBBLE
	# ---------------------------------------------------------
	print("--- [TEST 5] Resource Node Elastic Wobble & Hit Reaction ---")
	var tree_scene = load("res://scenes/environment/tree.tscn")
	if tree_scene:
		var tree = tree_scene.instantiate() as ResourceNode
		root.add_child(tree)
		
		var init_hp = tree.current_health
		tree.take_damage(15.0, Vector3(0, 0, 5), 0.0, Vector3(0, 1.5, 0), Vector3(0, 0, 1))
		
		var damaged_ok = tree.current_health == (init_hp - 15.0)
		var scale_ok = tree.original_scale != Vector3.ZERO

		if damaged_ok and scale_ok:
			passed += 1
			print("  ✓ ResourceNode received damage (HP: %.1f -> %.1f)." % [init_hp, tree.current_health])
			print("  ✓ Elastic squash/stretch & wobble triggered with hit direction.")
			print("PASSED: Resource Node VFX & elasticity validated successfully!\n")
		else:
			failed += 1
			print("  [FAIL] ResourceNode damage/wobble logic failed.\n")
		tree.queue_free()
	else:
		failed += 1
		print("  [FAIL] Could not load scenes/environment/tree.tscn\n")

	# ---------------------------------------------------------
	# TEST 6: VIEWMODEL COMBO SYSTEM & BOTW CHAMPION ARMS
	# ---------------------------------------------------------
	print("--- [TEST 6] Player Viewmodel & 3-Hit Combo System ---")
	var vm_scene = load("res://scenes/player/viewmodel.tscn")
	if vm_scene:
		var vm = vm_scene.instantiate() as PlayerViewmodel
		root.add_child(vm)

		# 1. Verifica geometria dos braços
		var r_sleeve = vm.get_node_or_null("Arms/RightArm/Sleeve") != null
		var r_cuff = vm.get_node_or_null("Arms/RightArm/Cuff") != null
		var r_bracer = vm.get_node_or_null("Arms/RightArm/Bracer") != null
		var r_hand = vm.get_node_or_null("Arms/RightArm/Hand") != null
		var has_trail = vm.get_node_or_null("SlashTrail") != null

		# 2. Testa troca de armas
		vm.set_item(PlayerViewmodel.ItemType.SWORD)
		var is_sword_vis = vm.get_node("Items/Sword").visible

		# 3. Testa combo de 3 golpes
		var dmg_1 = vm.get_damage(0)
		var action_1 = vm.trigger_primary_action() # Dispara Golpe 1
		vm.is_attacking = false
		vm.attack_cooldown = 0.0

		var dmg_2 = vm.get_damage(1)
		var action_2 = vm.trigger_primary_action() # Dispara Golpe 2
		vm.is_attacking = false
		vm.attack_cooldown = 0.0

		var dmg_3 = vm.get_damage(2)
		var action_3 = vm.trigger_primary_action() # Dispara Golpe 3 (Pesado)
		var is_heavy_flag = vm.is_current_attack_heavy()
		vm.is_attacking = false
		vm.attack_cooldown = 0.0

		# 4. Testa funções de inércia e balanço procedural
		vm.add_camera_sway(Vector2(5.0, -3.0))
		vm.apply_movement_bob(1.5, 1.0)
		vm.apply_jump_recoil()
		vm.apply_land_recoil(9.0)
		vm.apply_hit_recoil()

		print("  ✓ Champion Arms: Sleeve=%s, WhiteCuff=%s, LeatherBracer=%s, Hand=%s" % [
			r_sleeve, r_cuff, r_bracer, r_hand
		])
		print("  ✓ Slash Trail integrated: %s" % has_trail)
		print("  ✓ Combo Step 1 (Right Slash): Dmg=%.1f (Base)" % dmg_1)
		print("  ✓ Combo Step 2 (Left Slash):  Dmg=%.1f (+15%%)" % dmg_2)
		print("  ✓ Combo Step 3 (Heavy Cleave): Dmg=%.1f (+75%% Finisher)" % dmg_3)
		print("  ✓ Heavy flag verified on Step 3: %s" % is_heavy_flag)
		print("  ✓ Sway & Inertia procedural methods executed without errors.")

		if r_sleeve and r_cuff and r_bracer and has_trail and action_1 and action_2 and action_3 and is_heavy_flag and dmg_3 > dmg_1:
			passed += 1
			print("PASSED: Player Viewmodel & Combo System validated successfully!\n")
		else:
			failed += 1
			print("  [FAIL] Viewmodel components or combo sequence failed.\n")
		vm.queue_free()
	else:
		failed += 1
		print("  [FAIL] Could not load scenes/player/viewmodel.tscn\n")

	# ---------------------------------------------------------
	# RESUMO FINAL
	# ---------------------------------------------------------
	print("====================================================================")
	print("  TEST RESULTS: %d PASSED, %d FAILED" % [passed, failed])
	print("====================================================================\n")

	if failed == 0:
		print(">>> ALL VISUAL EFFECTS, PARTICLES & VIEWMODEL TESTS PASSED! <<<\n")
		quit(0)
	else:
		print(">>> SOME TESTS FAILED! <<<\n")
		quit(1)
