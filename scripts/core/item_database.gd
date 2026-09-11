class_name ItemDatabase
extends RefCounted

## Base de Dados de Itens para Muck of the Wild
## Gerencia definições estruturadas de recursos, ferramentas, armas, estruturas e relíquias.

enum ItemType {
	RESOURCE,
	CONSUMABLE,
	TOOL,
	WEAPON,
	STRUCTURE,
	RELIC
}

enum ToolType {
	NONE,
	AXE,
	PICKAXE,
	SWORD
}

const ITEMS: Dictionary = {
	# =========================================================================
	# RECURSOS BÁSICOS
	# =========================================================================
	"wood": {
		"id": "wood",
		"name": "Madeira",
		"type": ItemType.RESOURCE,
		"description": "Tronco robusto coletado de árvores. Material essencial para construção e ferramentas.",
		"max_stack": 64,
		"rarity": "common",
		"color": Color(0.55, 0.35, 0.17),
		"icon_symbol": "WOOD"
	},
	"rock": {
		"id": "rock",
		"name": "Pedra",
		"type": ItemType.RESOURCE,
		"description": "Fragmento rochoso resistente. Usado em ferramentas de pedra, fornalhas e fogueiras.",
		"max_stack": 64,
		"rarity": "common",
		"color": Color(0.6, 0.6, 0.65),
		"icon_symbol": "ROCK"
	},
	"iron_ore": {
		"id": "iron_ore",
		"name": "Minério de Ferro",
		"type": ItemType.RESOURCE,
		"description": "Minério bruto rico em ferro. Precisa ser fundido na fornalha para virar barra.",
		"max_stack": 64,
		"rarity": "uncommon",
		"color": Color(0.78, 0.55, 0.45),
		"icon_symbol": "IRON_ORE"
	},
	"iron_bar": {
		"id": "iron_bar",
		"name": "Barra de Ferro",
		"type": ItemType.RESOURCE,
		"description": "Lingote refinado de ferro. Matéria-prima para armamentos e ferramentas de alto nível.",
		"max_stack": 64,
		"rarity": "rare",
		"color": Color(0.85, 0.88, 0.92),
		"icon_symbol": "IRON_BAR"
	},
	"coal": {
		"id": "coal",
		"name": "Carvão",
		"type": ItemType.RESOURCE,
		"description": "Combustível mineral fóssil. Alimenta fornalhas e fogueiras por longo período.",
		"max_stack": 64,
		"rarity": "common",
		"color": Color(0.2, 0.2, 0.23),
		"icon_symbol": "COAL"
	},
	"stick": {
		"id": "stick",
		"name": "Galho",
		"type": ItemType.RESOURCE,
		"description": "Galho flexível de madeira. Usado como cabo para machados, picaretas e espadas.",
		"max_stack": 64,
		"rarity": "common",
		"color": Color(0.65, 0.48, 0.28),
		"icon_symbol": "STICK"
	},

	# =========================================================================
	# CONSUMÍVEIS (COMIDAS)
	# =========================================================================
	"apple": {
		"id": "apple",
		"name": "Maçã",
		"type": ItemType.CONSUMABLE,
		"description": "Maçã silvestre crocante colhida nas árvores. Restaura um pouco de fome e vida.",
		"max_stack": 32,
		"rarity": "common",
		"color": Color(0.9, 0.15, 0.18),
		"icon_symbol": "APPLE",
		"hunger_restore": 15.0,
		"health_restore": 8.0,
		"stamina_restore": 10.0
	},
	"mushroom": {
		"id": "mushroom",
		"name": "Cogumelo",
		"type": ItemType.CONSUMABLE,
		"description": "Cogumelo da floresta com propriedades revigorantes de cura e stamina.",
		"max_stack": 32,
		"rarity": "common",
		"color": Color(0.8, 0.3, 0.6),
		"icon_symbol": "MUSHROOM",
		"hunger_restore": 10.0,
		"health_restore": 12.0,
		"stamina_restore": 25.0
	},
	"raw_meat": {
		"id": "raw_meat",
		"name": "Carne Crua",
		"type": ItemType.CONSUMABLE,
		"description": "Pedaço de carne fresca. Sacía a fome rapidamente, mas pode causar leve indisposição.",
		"max_stack": 32,
		"rarity": "common",
		"color": Color(0.75, 0.2, 0.25),
		"icon_symbol": "RAW_MEAT",
		"hunger_restore": 20.0,
		"health_restore": -4.0,
		"stamina_restore": 5.0
	},
	"cooked_meat": {
		"id": "cooked_meat",
		"name": "Carne Cozida",
		"type": ItemType.CONSUMABLE,
		"description": "Carne suculenta assada no fogo. Banquete digno de campeão que restaura muita vida e energia.",
		"max_stack": 32,
		"rarity": "uncommon",
		"color": Color(0.58, 0.26, 0.12),
		"icon_symbol": "COOKED_MEAT",
		"hunger_restore": 45.0,
		"health_restore": 30.0,
		"stamina_restore": 35.0
	},

	# =========================================================================
	# FERRAMENTAS E ARMAS
	# =========================================================================
	"wood_axe": {
		"id": "wood_axe",
		"name": "Machado de Madeira",
		"type": ItemType.TOOL,
		"tool_type": ToolType.AXE,
		"tier": 1,
		"description": "Machado rudimentar feito de madeira. Capaz de cortar árvores pequenas e médias.",
		"max_stack": 1,
		"rarity": "common",
		"color": Color(0.68, 0.45, 0.22),
		"icon_symbol": "WOOD_AXE",
		"chop_power": 18.0,
		"mine_power": 4.0,
		"attack_damage": 7.0,
		"attack_speed": 1.0,
		"durability": 100.0,
		"max_durability": 100.0
	},
	"wood_pickaxe": {
		"id": "wood_pickaxe",
		"name": "Picareta de Madeira",
		"type": ItemType.TOOL,
		"tool_type": ToolType.PICKAXE,
		"tier": 1,
		"description": "Picareta leve de madeira talhada. Utilizada para quebrar rochas básicas.",
		"max_stack": 1,
		"rarity": "common",
		"color": Color(0.68, 0.45, 0.22),
		"icon_symbol": "WOOD_PICKAXE",
		"chop_power": 4.0,
		"mine_power": 18.0,
		"attack_damage": 6.0,
		"attack_speed": 1.0,
		"durability": 100.0,
		"max_durability": 100.0
	},
	"stone_axe": {
		"id": "stone_axe",
		"name": "Machado de Pedra",
		"type": ItemType.TOOL,
		"tool_type": ToolType.AXE,
		"tier": 2,
		"description": "Lâmina de sílex amarrada a galho firme. Corta madeira com mais rapidez e eficácia.",
		"max_stack": 1,
		"rarity": "uncommon",
		"color": Color(0.5, 0.55, 0.6),
		"icon_symbol": "STONE_AXE",
		"chop_power": 32.0,
		"mine_power": 8.0,
		"attack_damage": 14.0,
		"attack_speed": 1.05,
		"durability": 220.0,
		"max_durability": 220.0
	},
	"stone_pickaxe": {
		"id": "stone_pickaxe",
		"name": "Picareta de Pedra",
		"type": ItemType.TOOL,
		"tool_type": ToolType.PICKAXE,
		"tier": 2,
		"description": "Ponta de pedra afiada. Permite quebrar rochas duras e extrair minérios de ferro.",
		"max_stack": 1,
		"rarity": "uncommon",
		"color": Color(0.5, 0.55, 0.6),
		"icon_symbol": "STONE_PICKAXE",
		"chop_power": 8.0,
		"mine_power": 32.0,
		"attack_damage": 12.0,
		"attack_speed": 1.05,
		"durability": 220.0,
		"max_durability": 220.0
	},
	"iron_sword": {
		"id": "iron_sword",
		"name": "Espada de Ferro",
		"type": ItemType.WEAPON,
		"tool_type": ToolType.SWORD,
		"tier": 3,
		"description": "Lâmina forjada em aço brilhante. Desfere cortes rápidos e devastadores contra feras e monstros.",
		"max_stack": 1,
		"rarity": "rare",
		"color": Color(0.8, 0.88, 0.96),
		"icon_symbol": "IRON_SWORD",
		"chop_power": 12.0,
		"mine_power": 8.0,
		"attack_damage": 38.0,
		"attack_speed": 1.25,
		"durability": 360.0,
		"max_durability": 360.0
	},
	"iron_pickaxe": {
		"id": "iron_pickaxe",
		"name": "Picareta de Ferro",
		"type": ItemType.TOOL,
		"tool_type": ToolType.PICKAXE,
		"tier": 3,
		"description": "Picareta reforçada de ferro forjado. Pulveriza qualquer rocha ou jazida num instante.",
		"max_stack": 1,
		"rarity": "rare",
		"color": Color(0.8, 0.88, 0.96),
		"icon_symbol": "IRON_PICKAXE",
		"chop_power": 14.0,
		"mine_power": 55.0,
		"attack_damage": 18.0,
		"attack_speed": 1.15,
		"durability": 360.0,
		"max_durability": 360.0
	},
	"iron_axe": {
		"id": "iron_axe",
		"name": "Machado de Ferro",
		"type": ItemType.TOOL,
		"tool_type": ToolType.AXE,
		"tier": 3,
		"description": "Machado pesado de ferro temperado. Corta troncos maciços com poucos golpes.",
		"max_stack": 1,
		"rarity": "rare",
		"color": Color(0.8, 0.88, 0.96),
		"icon_symbol": "IRON_AXE",
		"chop_power": 55.0,
		"mine_power": 14.0,
		"attack_damage": 22.0,
		"attack_speed": 1.1,
		"durability": 360.0,
		"max_durability": 360.0
	},

	# =========================================================================
	# ESTRUTURAS
	# =========================================================================
	"workbench": {
		"id": "workbench",
		"name": "Bancada de Trabalho",
		"type": ItemType.STRUCTURE,
		"description": "Mesa de artesão equipada com morsa e ferramentas. Desbloqueia criação avançada de itens.",
		"max_stack": 8,
		"rarity": "common",
		"color": Color(0.7, 0.45, 0.25),
		"icon_symbol": "WORKBENCH",
		"placeable": true
	},
	"furnace": {
		"id": "furnace",
		"name": "Fornalha",
		"type": ItemType.STRUCTURE,
		"description": "Forno de pedra refratária para fundição de minérios em barras metálicas.",
		"max_stack": 8,
		"rarity": "uncommon",
		"color": Color(0.4, 0.42, 0.45),
		"icon_symbol": "FURNACE",
		"placeable": true
	},
	"campfire": {
		"id": "campfire",
		"name": "Fogueira",
		"type": ItemType.STRUCTURE,
		"description": "Fogueira acolhedora. Ilumina a noite, espanta o frio e serve para assar carnes.",
		"max_stack": 8,
		"rarity": "common",
		"color": Color(0.9, 0.5, 0.1),
		"icon_symbol": "CAMPFIRE",
		"placeable": true
	},
	"chest": {
		"id": "chest",
		"name": "Baú",
		"type": ItemType.STRUCTURE,
		"description": "Baú de madeira reforçada para armazenar até 24 pilhas de tesouros e suprimentos.",
		"max_stack": 8,
		"rarity": "uncommon",
		"color": Color(0.65, 0.42, 0.22),
		"icon_symbol": "CHEST",
		"placeable": true
	},

	# =========================================================================
	# RELÍQUIAS DE MUCK (POWERUPS PASSIVOS)
	# =========================================================================
	"sneakers": {
		"id": "sneakers",
		"name": "Tênis de Corrida",
		"type": ItemType.RELIC,
		"description": "Relíquia lendária de velocidade estilo Muck. Aumenta a velocidade de movimento em +15% por unidade acumulada.",
		"max_stack": 16,
		"rarity": "legendary",
		"color": Color(0.2, 0.8, 1.0),
		"icon_symbol": "SNEAKERS",
		"speed_multiplier_bonus": 0.15
	},
	"orange_juice": {
		"id": "orange_juice",
		"name": "Suco de Laranja",
		"type": ItemType.RELIC,
		"description": "Bebida cítrica transbordando adrenalina. Aumenta a velocidade de ataque em +20% por unidade acumulada.",
		"max_stack": 16,
		"rarity": "legendary",
		"color": Color(1.0, 0.55, 0.0),
		"icon_symbol": "ORANGE_JUICE",
		"attack_speed_multiplier_bonus": 0.20
	},
	"adrenaline": {
		"id": "adrenaline",
		"name": "Adrenalina",
		"type": ItemType.RELIC,
		"description": "Soro de pura fúria combatente. Concede +10% de chance crítica e +30% de dano crítico acumulável.",
		"max_stack": 16,
		"rarity": "legendary",
		"color": Color(0.95, 0.2, 0.35),
		"icon_symbol": "ADRENALINE",
		"crit_chance_bonus": 0.10,
		"crit_damage_bonus": 0.30
	},
	"vampirism": {
		"id": "vampirism",
		"name": "Vampirismo",
		"type": ItemType.RELIC,
		"description": "Dente de morcego ancestral. Converte 10% do dano causado a inimigos em cura vital para o jogador.",
		"max_stack": 16,
		"rarity": "legendary",
		"color": Color(0.7, 0.05, 0.15),
		"icon_symbol": "VAMPIRISM",
		"lifesteal_percent": 0.10
	},
	"sacred_feather": {
		"id": "sacred_feather",
		"name": "Pena Sagrada",
		"type": ItemType.RELIC,
		"description": "Pena mística imbuída com o poder dos ventos celestiais. Garante a habilidade de pulo duplo no ar.",
		"max_stack": 16,
		"rarity": "legendary",
		"color": Color(0.9, 0.95, 1.0),
		"icon_symbol": "SACRED_FEATHER",
		"extra_jumps": 1
	}
}

# =============================================================================
# MÉTODOS ESTÁTICOS DE CONSULTA
# =============================================================================

static func get_item(item_id: String) -> Dictionary:
	if ITEMS.has(item_id):
		return ITEMS[item_id].duplicate(true)
	return {}

static func has_item(item_id: String) -> bool:
	return ITEMS.has(item_id)

static func get_all_items() -> Dictionary:
	return ITEMS.duplicate(true)

static func get_items_by_type(type: ItemType) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in ITEMS:
		var item: Dictionary = ITEMS[item_id]
		if item.get("type", -1) == type:
			result.append(item.duplicate(true))
	return result

static func create_item_instance(item_id: String, count: int = 1, custom_data: Dictionary = {}) -> Dictionary:
	if not ITEMS.has(item_id):
		push_warning("ItemDatabase: Item '%s' nao encontrado!" % item_id)
		return {}
	
	var def: Dictionary = ITEMS[item_id]
	var max_stack: int = def.get("max_stack", 64)
	var actual_count: int = clampi(count, 1, max_stack)
	
	var instance: Dictionary = {
		"id": item_id,
		"count": actual_count,
		"durability": def.get("durability", 100.0),
		"max_durability": def.get("max_durability", 100.0),
		"custom_data": custom_data.duplicate(true)
	}
	return instance

static func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common":
			return Color(0.85, 0.85, 0.85)
		"uncommon":
			return Color(0.3, 0.85, 0.35)
		"rare":
			return Color(0.25, 0.65, 1.0)
		"epic":
			return Color(0.75, 0.35, 0.95)
		"legendary":
			return Color(1.0, 0.78, 0.15)
		_:
			return Color.WHITE
