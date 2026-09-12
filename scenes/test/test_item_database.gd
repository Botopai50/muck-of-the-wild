extends SceneTree

func _init():
	var db = load("res://scripts/core/item_database.gd")
	var items = db.get_all_items()
	print("ItemDatabase loaded successfully with %d items." % items.size())
	for id in ["wood", "rock", "iron_ore", "iron_bar", "coal", "stick", "apple", "mushroom", "raw_meat", "cooked_meat", "wood_axe", "wood_pickaxe", "stone_axe", "stone_pickaxe", "iron_sword", "iron_pickaxe", "iron_axe", "workbench", "furnace", "campfire", "chest", "sneakers", "orange_juice", "adrenaline", "vampirism", "sacred_feather"]:
		if not db.has_item(id):
			push_error("Missing required item: " + id)
			quit(1)
			return
	print("All 26 required items verified successfully!")
	quit(0)
