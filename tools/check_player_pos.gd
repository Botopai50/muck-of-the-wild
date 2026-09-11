extends SceneTree

func _init() -> void:
	var scn = load("res://scenes/main.tscn").instantiate()
	root.add_child(scn)
	var ply = scn.get_node("Player")
	print("Player initial pos: ", ply.global_position)
	for i in range(30):
		await process_frame
	print("Player pos after 30 frames: ", ply.global_position)
	print("Is on floor: ", ply.is_on_floor())
	quit(0)
