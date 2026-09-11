class_name CraftingSystem
extends Node

## Sistema de Crafting estilo Muck
## Gerencia receitas manuais (Handcrafting) e de bancada (Workbench)

signal item_crafted(item_id: String, count: int)
signal crafting_failed(reason: String)

const RECIPES: Array[Dictionary] = [
	{
		"id": "stick",
		"result": "stick",
		"count": 2,
		"station": "hand",
		"requirements": {
			"wood": 1
		}
	},
	{
		"id": "workbench",
		"result": "workbench",
		"count": 1,
		"station": "hand",
		"requirements": {
			"wood": 10
		}
	},
	{
		"id": "wood_axe",
		"result": "wood_axe",
		"count": 1,
		"station": "hand",
		"requirements": {
			"wood": 5,
			"stick": 2
		}
	},
	{
		"id": "wood_pickaxe",
		"result": "wood_pickaxe",
		"count": 1,
		"station": "hand",
		"requirements": {
			"wood": 5,
			"stick": 2
		}
	},
	{
		"id": "campfire",
		"result": "campfire",
		"count": 1,
		"station": "hand",
		"requirements": {
			"wood": 6,
			"rock": 4
		}
	},
	{
		"id": "stone_axe",
		"result": "stone_axe",
		"count": 1,
		"station": "workbench",
		"requirements": {
			"wood": 5,
			"rock": 5,
			"stick": 2
		}
	},
	{
		"id": "stone_pickaxe",
		"result": "stone_pickaxe",
		"count": 1,
		"station": "workbench",
		"requirements": {
			"wood": 5,
			"rock": 5,
			"stick": 2
		}
	},
	{
		"id": "furnace",
		"result": "furnace",
		"count": 1,
		"station": "workbench",
		"requirements": {
			"rock": 15
		}
	},
	{
		"id": "chest",
		"result": "chest",
		"count": 1,
		"station": "workbench",
		"requirements": {
			"wood": 12,
			"rock": 4
		}
	},
	{
		"id": "iron_sword",
		"result": "iron_sword",
		"count": 1,
		"station": "workbench",
		"requirements": {
			"iron_bar": 6,
			"stick": 2,
			"wood": 2
		}
	},
	{
		"id": "iron_pickaxe",
		"result": "iron_pickaxe",
		"count": 1,
		"station": "workbench",
		"requirements": {
			"iron_bar": 5,
			"wood": 3,
			"stick": 2
		}
	},
	{
		"id": "iron_axe",
		"result": "iron_axe",
		"count": 1,
		"station": "workbench",
		"requirements": {
			"iron_bar": 5,
			"wood": 3,
			"stick": 2
		}
	}
]

static func get_recipes_for_station(station: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for r in RECIPES:
		if station == "all" or r["station"] == station or (station == "workbench" and r["station"] == "hand"):
			result.append(r)
	return result

static func can_craft(recipe: Dictionary, inventory: Node) -> bool:
	if not inventory:
		return false
	var reqs = recipe.get("requirements", {})
	for item_id in reqs.keys():
		var needed = reqs[item_id]
		var count = 0
		if inventory.has_method("get_item_count"):
			count = inventory.get_item_count(item_id)
		if count < needed:
			return false
	return true

func craft(recipe: Dictionary, inventory: Node) -> bool:
	if not can_craft(recipe, inventory):
		crafting_failed.emit("Recursos insuficientes.")
		return false
	
	var reqs = recipe.get("requirements", {})
	for item_id in reqs.keys():
		var needed = reqs[item_id]
		if inventory.has_method("remove_item"):
			inventory.remove_item(item_id, needed)
	
	var result_id = recipe["result"]
	var result_count = recipe.get("count", 1)
	if inventory.has_method("add_item"):
		inventory.add_item(result_id, result_count)
	
	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am.has_method("play_sound"):
			am.play_sound("craft")
	
	item_crafted.emit(result_id, result_count)
	return true
