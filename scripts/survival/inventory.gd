class_name Inventory
extends Node

## Sistema de Inventário Completo estilo Muck + Zelda
## Gerencia 24 slots de mochila + 8 slots de Hotbar ativa, empilhamento, consumo e relíquias.

signal inventory_changed
signal slot_updated(slot_index: int, item_data: Variant)
signal active_hotbar_changed(slot_index: int, item_data: Variant)
signal item_added(item_id: String, count: int)
signal item_removed(item_id: String, count: int)
signal item_consumed(item_id: String, hunger_restored: float, health_restored: float)
signal relic_stats_changed

const HOTBAR_COUNT: int = 8
const BACKPACK_COUNT: int = 24
const TOTAL_SLOTS: int = HOTBAR_COUNT + BACKPACK_COUNT # 32 slots no total

var slots: Array = []
var active_hotbar_index: int = 0:
	set(value):
		var prev = active_hotbar_index
		active_hotbar_index = posmod(value, HOTBAR_COUNT)
		if active_hotbar_index != prev or not is_inside_tree():
			active_hotbar_changed.emit(active_hotbar_index, get_active_item())

func _init() -> void:
	slots.resize(TOTAL_SLOTS)
	for i in range(TOTAL_SLOTS):
		slots[i] = null

func _ready() -> void:
	active_hotbar_changed.emit(active_hotbar_index, get_active_item())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode >= KEY_1 and event.keycode <= KEY_8:
			var target_slot = event.keycode - KEY_1
			set_active_hotbar_slot(target_slot)
	elif event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			prev_hotbar_slot()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			next_hotbar_slot()

# =============================================================================
# OPERAÇÕES BÁSICAS DE ITENS
# =============================================================================

## Adiciona itens ao inventário, preenchendo pilhas existentes e depois novos slots.
## Retorna a quantidade de itens que NÃO couberam (0 = sucesso total).
func add_item(item_id: String, count: int = 1, custom_data: Dictionary = {}) -> int:
	var item_db = load("res://scripts/core/item_database.gd")
	if not item_db.has_item(item_id) or count <= 0:
		return count
	
	var def = item_db.get_item(item_id)
	var max_stack: int = def.get("max_stack", 64)
	var remaining: int = count
	var total_added: int = 0
	
	# 1. Tentar empilhar em slots existentes que possuam o mesmo item
	if max_stack > 1:
		for i in range(TOTAL_SLOTS):
			if slots[i] != null and slots[i]["id"] == item_id:
				var current_count: int = slots[i]["count"]
				var space: int = max_stack - current_count
				if space > 0:
					var to_add = mini(space, remaining)
					slots[i]["count"] += to_add
					remaining -= to_add
					total_added += to_add
					slot_updated.emit(i, slots[i])
					if i == active_hotbar_index:
						active_hotbar_changed.emit(active_hotbar_index, get_active_item())
					if remaining <= 0:
						break
	
	# 2. Se sobrou, preencher slots vazios (priorizando Hotbar 0..7 e depois Mochila)
	if remaining > 0:
		for i in range(TOTAL_SLOTS):
			if slots[i] == null:
				var to_add = mini(max_stack, remaining)
				slots[i] = item_db.create_item_instance(item_id, to_add, custom_data)
				remaining -= to_add
				total_added += to_add
				slot_updated.emit(i, slots[i])
				if i == active_hotbar_index:
					active_hotbar_changed.emit(active_hotbar_index, get_active_item())
				if remaining <= 0:
					break
	
	if total_added > 0:
		item_added.emit(item_id, total_added)
		inventory_changed.emit()
		if def.get("type") == item_db.ItemType.RELIC:
			relic_stats_changed.emit()
	
	return remaining

## Remove uma quantidade total de um item por ID do inventário.
## Retorna o total removido com sucesso.
func remove_item(item_id: String, count: int = 1) -> int:
	if count <= 0:
		return 0
	
	var remaining_to_remove: int = count
	var total_removed: int = 0
	
	# Percorre do final da mochila para o início
	for i in range(TOTAL_SLOTS - 1, -1, -1):
		if slots[i] != null and slots[i]["id"] == item_id:
			var slot_count: int = slots[i]["count"]
			if slot_count <= remaining_to_remove:
				total_removed += slot_count
				remaining_to_remove -= slot_count
				slots[i] = null
				slot_updated.emit(i, null)
			else:
				slots[i]["count"] -= remaining_to_remove
				total_removed += remaining_to_remove
				remaining_to_remove = 0
				slot_updated.emit(i, slots[i])
			
			if i == active_hotbar_index:
				active_hotbar_changed.emit(active_hotbar_index, get_active_item())
			
			if remaining_to_remove <= 0:
				break
	
	if total_removed > 0:
		item_removed.emit(item_id, total_removed)
		inventory_changed.emit()
		var item_db = load("res://scripts/core/item_database.gd")
		var def = item_db.get_item(item_id)
		if def.get("type") == item_db.ItemType.RELIC:
			relic_stats_changed.emit()
	
	return total_removed

## Remove itens de um slot específico. Retorna cópia do item removido.
func remove_at(slot_index: int, count: int = 1) -> Dictionary:
	if not is_valid_slot(slot_index) or slots[slot_index] == null or count <= 0:
		return {}
	
	var slot_data = slots[slot_index]
	var removed_count = mini(slot_data["count"], count)
	var removed_item = slot_data.duplicate(true)
	removed_item["count"] = removed_count
	
	slot_data["count"] -= removed_count
	if slot_data["count"] <= 0:
		slots[slot_index] = null
		slot_updated.emit(slot_index, null)
	else:
		slot_updated.emit(slot_index, slot_data)
	
	if slot_index == active_hotbar_index:
		active_hotbar_changed.emit(active_hotbar_index, get_active_item())
	
	item_removed.emit(removed_item["id"], removed_count)
	inventory_changed.emit()
	
	var item_db = load("res://scripts/core/item_database.gd")
	var def = item_db.get_item(removed_item["id"])
	if def.get("type") == item_db.ItemType.RELIC:
		relic_stats_changed.emit()
	
	return removed_item

## Retorna a contagem total de um determinado item no inventário.
func get_item_count(item_id: String) -> int:
	var total: int = 0
	for item in slots:
		if item != null and item["id"] == item_id:
			total += item["count"]
	return total

## Verifica se possui pelo menos 'count' unidades do item.
func has_item(item_id: String, count: int = 1) -> bool:
	return get_item_count(item_id) >= count

## Troca a posição de dois slots ou funde pilhas se forem do mesmo item.
func swap_slots(from_idx: int, to_idx: int) -> bool:
	if not is_valid_slot(from_idx) or not is_valid_slot(to_idx) or from_idx == to_idx:
		return false
	
	var a = slots[from_idx]
	var b = slots[to_idx]
	
	if a == null and b == null:
		return false
	
	# Fusão de itens iguais
	if a != null and b != null and a["id"] == b["id"]:
		var item_db = load("res://scripts/core/item_database.gd")
		var def = item_db.get_item(a["id"])
		var max_stack: int = def.get("max_stack", 64)
		var space = max_stack - b["count"]
		if space > 0:
			var transfer = mini(space, a["count"])
			b["count"] += transfer
			a["count"] -= transfer
			if a["count"] <= 0:
				slots[from_idx] = null
			slot_updated.emit(from_idx, slots[from_idx])
			slot_updated.emit(to_idx, slots[to_idx])
			_check_active_changed(from_idx, to_idx)
			inventory_changed.emit()
			return true
	
	# Troca simples
	slots[from_idx] = b
	slots[to_idx] = a
	slot_updated.emit(from_idx, slots[from_idx])
	slot_updated.emit(to_idx, slots[to_idx])
	_check_active_changed(from_idx, to_idx)
	inventory_changed.emit()
	return true

## Divide metade de uma pilha ou quantia específica para outro slot.
func split_slot(from_idx: int, to_idx: int, split_count: int = -1) -> bool:
	if not is_valid_slot(from_idx) or not is_valid_slot(to_idx) or from_idx == to_idx:
		return false
	if slots[from_idx] == null or slots[to_idx] != null:
		return false
	
	var total = slots[from_idx]["count"]
	if total <= 1:
		return swap_slots(from_idx, to_idx)
	
	var to_move = int(total / 2.0) if split_count <= 0 else clampi(split_count, 1, total - 1)
	var new_item = slots[from_idx].duplicate(true)
	new_item["count"] = to_move
	slots[from_idx]["count"] -= to_move
	slots[to_idx] = new_item
	
	slot_updated.emit(from_idx, slots[from_idx])
	slot_updated.emit(to_idx, slots[to_idx])
	_check_active_changed(from_idx, to_idx)
	inventory_changed.emit()
	return true

func is_valid_slot(index: int) -> bool:
	return index >= 0 and index < TOTAL_SLOTS

func get_slot(index: int) -> Variant:
	if is_valid_slot(index):
		return slots[index]
	return null

# =============================================================================
# CONTROLE DA HOTBAR
# =============================================================================

func set_active_hotbar_slot(slot_index: int) -> void:
	active_hotbar_index = clampi(slot_index, 0, HOTBAR_COUNT - 1)

func next_hotbar_slot() -> void:
	active_hotbar_index = posmod(active_hotbar_index + 1, HOTBAR_COUNT)

func prev_hotbar_slot() -> void:
	active_hotbar_index = posmod(active_hotbar_index - 1, HOTBAR_COUNT)

func get_active_item() -> Variant:
	return slots[active_hotbar_index]

func get_active_slot_index() -> int:
	return active_hotbar_index

func _check_active_changed(idx1: int, idx2: int) -> void:
	if idx1 == active_hotbar_index or idx2 == active_hotbar_index:
		active_hotbar_changed.emit(active_hotbar_index, get_active_item())

# =============================================================================
# CONSUMO DE ALIMENTOS
# =============================================================================

## Consome o alimento no slot especificado, restaurando fome e vida.
func consume_item(slot_index: int, target_entity: Node = null) -> bool:
	if not is_valid_slot(slot_index) or slots[slot_index] == null:
		return false
	
	var item_data = slots[slot_index]
	var item_db = load("res://scripts/core/item_database.gd")
	var def = item_db.get_item(item_data["id"])
	if def.get("type") != item_db.ItemType.CONSUMABLE:
		return false
	
	var hunger_restore: float = def.get("hunger_restore", 10.0)
	var health_restore: float = def.get("health_restore", 0.0)
	var stamina_restore: float = def.get("stamina_restore", 0.0)
	
	# Localizar o componente de sobrevivência se alvo foi passado ou se está em pai
	var stats: Node = null
	if target_entity != null:
		if target_entity.has_method("feed"):
			stats = target_entity
		else:
			stats = target_entity.find_child("SurvivalStats", true, false)
	if stats == null and get_parent() != null:
		stats = get_parent().find_child("SurvivalStats", true, false)
	
	if stats != null:
		if hunger_restore > 0 and stats.has_method("feed"):
			stats.feed(hunger_restore)
		if health_restore > 0 and stats.has_method("heal"):
			stats.heal(health_restore)
		elif health_restore < 0 and stats.has_method("take_damage"):
			stats.take_damage(absf(health_restore))
		if stamina_restore > 0 and stats.has_method("restore_stamina"):
			stats.restore_stamina(stamina_restore)
	
	# Som de mastigação/consumo
	var audio_mgr = load("res://scripts/core/audio_manager.gd")
	if audio_mgr:
		audio_mgr.play_sound(self, "eat", randf_range(0.95, 1.05))
	
	# Decrementar 1 unidade
	item_data["count"] -= 1
	var item_id = item_data["id"]
	if item_data["count"] <= 0:
		slots[slot_index] = null
		slot_updated.emit(slot_index, null)
	else:
		slot_updated.emit(slot_index, item_data)
	
	if slot_index == active_hotbar_index:
		active_hotbar_changed.emit(active_hotbar_index, get_active_item())
	
	item_consumed.emit(item_id, hunger_restore, health_restore)
	inventory_changed.emit()
	return true

## Consome o item ativo na Hotbar se for comestível
func consume_active_item(target_entity: Node = null) -> bool:
	return consume_item(active_hotbar_index, target_entity)

# =============================================================================
# SISTEMA DE RELÍQUIAS MUCK (POWERUPS PASSIVOS)
# =============================================================================

## Calcula o bônus acumulativo total de uma propriedade de relíquia no inventário.
## Exemplo: get_relic_bonus("speed_multiplier_bonus") para os Tênis de Corrida.
func get_relic_bonus(stat_name: String) -> float:
	var total_bonus: float = 0.0
	var item_db = load("res://scripts/core/item_database.gd")
	for item in slots:
		if item != null:
			var def = item_db.get_item(item["id"])
			if def.get("type") == item_db.ItemType.RELIC and def.has(stat_name):
				total_bonus += float(def[stat_name]) * float(item["count"])
	return total_bonus
