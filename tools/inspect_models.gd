extends SceneTree

func _init():
	var tree_sc = load("res://assets/models/nature/BirchTree_1.fbx")
	var t = tree_sc.instantiate()
	print("TREE NODES:")
	_print_nodes(t, "  ")
	var rock_sc = load("res://assets/models/nature/Rock_1.fbx")
	var r = rock_sc.instantiate()
	print("ROCK NODES:")
	_print_nodes(r, "  ")
	quit(0)

func _print_nodes(n: Node, indent: String):
	var info = n.name + " (" + n.get_class() + ")"
	if n is MeshInstance3D:
		info += " mesh=" + str(n.mesh) + " surfaces=" + str(n.mesh.get_surface_count() if n.mesh else 0)
		for i in range(n.mesh.get_surface_count() if n.mesh else 0):
			var mat = n.get_surface_override_material(i)
			if not mat and n.mesh: mat = n.mesh.surface_get_material(i)
			var m_name = mat.resource_name if mat and mat.resource_name != "" else (mat.get_class() if mat else "null")
			info += " [surf" + str(i) + "=" + m_name + "]"
	print(indent + info)
	for c in n.get_children():
		_print_nodes(c, indent + "  ")
