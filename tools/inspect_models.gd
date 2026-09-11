extends SceneTree

func _init():
	var packed = load("res://scenes/main.tscn")
	var s = packed.instantiate()
	root.add_child(s)
	var gm = s.get_node("GameManager")
	if not gm.world_environment:
		gm.world_environment = gm.get_node_or_null("../WorldEnvironment")
	print("gm.world_environment after get_node: ", gm.world_environment)
	gm.cycle_elapsed = gm.day_duration + gm.night_duration * 0.45
	gm._apply_lighting_and_atmosphere(1.0)
	var we = s.get_node("WorldEnvironment")
	print("sky_mat time_of_day: ", we.environment.sky.sky_material.get_shader_parameter("time_of_day"))
	quit(0)
