extends SceneTree

func _init() -> void:
	print("\n====================================================================")
	print("  MUCK OF THE WILD - ENEMIES, RELICS & AUDIO SYNTH VALIDATION SUITE  ")
	print("====================================================================\n")
	
	var passed: int = 0
	var failed: int = 0
	
	# ---------------------------------------------------------
	# TEST 1: SÍNTESE PROCEDURAL DE ÁUDIO REFINADA (8 EFEITOS)
	# ---------------------------------------------------------
	print("--- [TEST 1] Procedural Audio Synthesis (8 Refined SFX) ---")
	var sfx_list := [
		"footstep_grass",
		"jump",
		"weapon_swing",
		"impact_wood",
		"impact_stone",
		"chest_open",
		"hit",
		"golem_slam"
	]
	
	var audio_ok := true
	for sfx in sfx_list:
		var stream := AudioSynth.create_sound(sfx)
		if stream == null or stream.data.size() == 0:
			print("  [FAIL] Missing audio stream for: ", sfx)
			audio_ok = false
		else:
			print("  ✓ SFX '%s': dur=%.2fs, rate=%dHz, bytes=%d" % [
				sfx, stream.get_length(), stream.mix_rate, stream.data.size()
			])
			
	if audio_ok:
		passed += 1
		print("PASSED: All 8 refined audio effects synthesized successfully!\n")
	else:
		failed += 1

	# ---------------------------------------------------------
	# TEST 2: GOLEM (MINI-CHEFE COLOSSAL DE PEDRA SHEIKAH)
	# ---------------------------------------------------------
	print("--- [TEST 2] Colossal Golem Scene & Sheikah Runes ---")
	var golem_scene = load("res://scenes/enemies/golem.tscn")
	if golem_scene:
		var golem = golem_scene.instantiate() as Golem
		root.add_child(golem)
		
		var has_torso: bool = golem.get_node_or_null("Visuals/Torso") != null
		var has_eye: bool = golem.get_node_or_null("Visuals/Torso/Head/Eye") != null
		var has_eye_light: bool = golem.get_node_or_null("Visuals/Torso/Head/EyeLight") != null
		var has_chest_rune: bool = golem.get_node_or_null("Visuals/Torso/ChestRune") != null
		var is_boss: bool = golem.is_in_group("bosses") and golem.is_in_group("enemies")
		
		print("  ✓ Golem instantiated: Max HP=%.1f, Slam Dmg=%.1f" % [golem.max_health, golem.slam_damage])
		print("  ✓ Visuals check: Torso=%s, Eye=%s, EyeLight=%s, ChestRune=%s, IsBoss=%s" % [
			has_torso, has_eye, has_eye_light, has_chest_rune, is_boss
		])
		
		# Test Damage & Damage Numbers
		var initial_hp = golem.current_health
		golem.take_damage(50.0, Vector3.ZERO, 5.0)
		if golem.current_health == (initial_hp - 50.0):
			print("  ✓ Golem take_damage() working correctly: %.1f HP remaining" % golem.current_health)
			passed += 1
			print("PASSED: Golem scene and behavior validated!\n")
		else:
			print("  [FAIL] Golem HP mismatch after damage")
			failed += 1
			
		golem.queue_free()
	else:
		print("  [FAIL] Could not load golem.tscn")
		failed += 1

	# ---------------------------------------------------------
	# TEST 3: ONDA DE CHOQUE & ANEL DE POEIRA EXPANSIVO
	# ---------------------------------------------------------
	print("--- [TEST 3] Shockwave & Expanding Dust Ring ---")
	var sw_scene = load("res://scenes/enemies/shockwave.tscn")
	if sw_scene:
		var sw = sw_scene.instantiate() as Shockwave
		root.add_child(sw)
		
		var has_mesh: bool = sw.get_node_or_null("MeshInstance3D") != null
		var has_particles: bool = sw.get_node_or_null("DustRingParticles") != null
		var has_col: bool = sw.get_node_or_null("CollisionShape3D") != null
		
		print("  ✓ Shockwave: Mesh=%s, DustRingParticles=%s, Collision=%s" % [
			has_mesh, has_particles, has_col
		])
		if has_mesh and has_particles and has_col:
			passed += 1
			print("PASSED: Shockwave scene & dust ring validated!\n")
		else:
			failed += 1
		sw.queue_free()
	else:
		print("  [FAIL] Could not load shockwave.tscn")
		failed += 1

	# ---------------------------------------------------------
	# TEST 4: PEDREGULHO GIGANTE & RASTRO DE POEIRA
	# ---------------------------------------------------------
	print("--- [TEST 4] Boulder Projectile & Dust Trail ---")
	var bld_scene = load("res://scenes/enemies/boulder.tscn")
	if bld_scene:
		var bld = bld_scene.instantiate() as Boulder
		root.add_child(bld)
		
		var has_trail: bool = bld.get_node_or_null("DustTrailParticles") != null
		var has_impact: bool = bld.get_node_or_null("ImpactParticles") != null
		bld.launch(Vector3(0, 2, 0), Vector3(10, 1, 10))
		
		print("  ✓ Boulder launched: velocity=%s, DustTrail=%s, ImpactParticles=%s" % [
			bld.velocity, has_trail, has_impact
		])
		if has_trail and has_impact and bld.velocity.length() > 0.0:
			passed += 1
			print("PASSED: Boulder launch and particle systems validated!\n")
		else:
			failed += 1
		bld.queue_free()
	else:
		print("  [FAIL] Could not load boulder.tscn")
		failed += 1

	# ---------------------------------------------------------
	# TEST 5: GOBLINS NOTURNOS ÁGEIS & CEL-SHADING TERRICOTA
	# ---------------------------------------------------------
	print("--- [TEST 5] Agile Night Goblin ---")
	var gob_scene = load("res://scenes/enemies/goblin.tscn")
	if gob_scene:
		var gob = gob_scene.instantiate() as Goblin
		root.add_child(gob)
		
		var has_club: bool = gob.get_node_or_null("Visuals/Torso/ArmR/ClubPivot") != null
		var has_eye_glow: bool = gob.get_node_or_null("Visuals/Torso/Head/EyeGlow") != null
		print("  ✓ Goblin: Speed=%.1f, Jump=%.1f, ClubPivot=%s, EyeGlow=%s" % [
			gob.sprint_speed, gob.jump_velocity, has_club, has_eye_glow
		])
		
		# Test Damage & Knockback
		var initial_hp = gob.current_health
		gob.take_damage(20.0, Vector3(0, 0, -2), 8.0)
		if gob.current_health == (initial_hp - 20.0) and gob.is_in_knockback:
			print("  ✓ Goblin knockback and damage registered correctly: HP=%.1f" % gob.current_health)
			passed += 1
			print("PASSED: Goblin mechanics & visuals validated!\n")
		else:
			print("  [FAIL] Goblin knockback/damage failed")
			failed += 1
		gob.queue_free()
	else:
		print("  [FAIL] Could not load goblin.tscn")
		failed += 1

	# ---------------------------------------------------------
	# TEST 6: BAÚ DE RELÍQUIAS SHEIKAH & FEIXE DE LUZ VERTICAL
	# ---------------------------------------------------------
	print("--- [TEST 6] Sheikah Relic Chest & Vertical Beam ---")
	var chest_scene = load("res://scenes/environment/chest.tscn")
	if chest_scene:
		var chest = chest_scene.instantiate() as RelicChest
		root.add_child(chest)
		
		var has_gem: bool = chest.get_node_or_null("LidPivot/Lid/CyanGem") != null
		var has_gem_light: bool = chest.get_node_or_null("LidPivot/Lid/GemLight") != null
		var has_beam: bool = chest.get_node_or_null("VerticalLightBeam") != null
		var has_particles: bool = chest.get_node_or_null("BeamParticles") != null
		var has_relic_vis: bool = chest.get_node_or_null("RelicVisual") != null
		
		print("  ✓ Sheikah Chest: CyanGem=%s, GemLight=%s, Beam=%s, Particles=%s, RelicVisual=%s" % [
			has_gem, has_gem_light, has_beam, has_particles, has_relic_vis
		])
		
		# Manually trigger interact with dummy player
		var dummy_p = CharacterBody3D.new()
		dummy_p.add_to_group("player")
		root.add_child(dummy_p)
		
		chest.interact(dummy_p)
		var beam_node = chest.get_node_or_null("VerticalLightBeam") as MeshInstance3D
		if chest.is_opened and beam_node != null and beam_node.visible:
			print("  ✓ Chest interact() triggered: beam active, lid opening")
			passed += 1
			print("PASSED: Sheikah Relic Chest sequence validated!\n")
		else:
			print("  [FAIL] Chest opening failed")
			failed += 1
		dummy_p.queue_free()
		chest.queue_free()
	else:
		print("  [FAIL] Could not load chest.tscn")
		failed += 1

	# ---------------------------------------------------------
	# TEST 7: FLOATING TEXT (POP COMIC STYLE)
	# ---------------------------------------------------------
	print("--- [TEST 7] Pop Comic Floating Text ---")
	var ft_scene = load("res://scenes/ui/floating_text.tscn")
	if ft_scene:
		var ft = ft_scene.instantiate() as FloatingText
		root.add_child(ft)
		ft.setup("45", Color(1.0, 0.85, 0.2), false)
		var label1 = ft.get_node_or_null("Label3D") as Label3D
		print("  ✓ FloatingText setup normal: text='%s', font_size=%d" % [label1.text, label1.font_size])
		
		var ft_crit = ft_scene.instantiate() as FloatingText
		root.add_child(ft_crit)
		ft_crit.setup("90", Color(1.0, 0.2, 0.2), true)
		var label2 = ft_crit.get_node_or_null("Label3D") as Label3D
		print("  ✓ FloatingText setup critical: text='%s', font_size=%d" % [label2.text, label2.font_size])
		
		if "💥" in label2.text:
			passed += 1
			print("PASSED: Pop comic floating text validated!\n")
		else:
			failed += 1
		ft.queue_free()
		ft_crit.queue_free()
	else:
		print("  [FAIL] Could not load floating_text.tscn")
		failed += 1

	print("====================================================================")
	print("  TEST SUMMARY: %d PASSED, %d FAILED" % [passed, failed])
	print("====================================================================\n")
	
	quit(0 if failed == 0 else 1)