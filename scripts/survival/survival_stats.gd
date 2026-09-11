class_name SurvivalStats
extends Node

## Gerenciador de Atributos Vitais do Jogador (Vida, Fome, Estamina)
## Inspirado no estilo de sobrevivência Muck + Breath of the Wild

signal health_changed(current: float, max_val: float)
signal hunger_changed(current: float, max_val: float)
signal stamina_changed(current: float, max_val: float)
signal died
signal damaged(amount: float)
signal healed(amount: float)

@export var max_health: float = 100.0
@export var current_health: float = 100.0

@export var max_hunger: float = 100.0
@export var current_hunger: float = 100.0
@export var hunger_depletion_rate: float = 0.5 # Por segundo

@export var max_stamina: float = 100.0
@export var current_stamina: float = 100.0
@export var stamina_recovery_rate: float = 25.0 # Por segundo

var is_dead: bool = false

func _ready() -> void:
	current_health = max_health
	current_hunger = max_hunger
	current_stamina = max_stamina

func _process(delta: float) -> void:
	if is_dead:
		return
	
	# Drenagem lenta de fome
	if current_hunger > 0.0:
		current_hunger = maxf(0.0, current_hunger - hunger_depletion_rate * delta)
		hunger_changed.emit(current_hunger, max_hunger)
	else:
		# Sem comida: perde vida gradualmente por inanição
		take_damage(2.0 * delta, false)
	
	# Regeneração passiva se estiver bem alimentado
	if current_hunger > 80.0 and current_health < max_health:
		heal(1.5 * delta)
	
	# Regeneração de estamina
	if current_stamina < max_stamina:
		current_stamina = minf(max_stamina, current_stamina + stamina_recovery_rate * delta)
		stamina_changed.emit(current_stamina, max_stamina)

func take_damage(amount: float, emit_damaged_event: bool = true) -> void:
	if is_dead or amount <= 0.0:
		return
	
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if emit_damaged_event:
		damaged.emit(amount)
	
	if current_health <= 0.0:
		is_dead = true
		died.emit()

func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	
	var old = current_health
	current_health = minf(max_health, current_health + amount)
	var diff = current_health - old
	if diff > 0.0:
		health_changed.emit(current_health, max_health)
		healed.emit(diff)

func feed(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current_hunger = minf(max_hunger, current_hunger + amount)
	hunger_changed.emit(current_hunger, max_hunger)

func use_stamina(amount: float) -> bool:
	if current_stamina >= amount:
		current_stamina -= amount
		stamina_changed.emit(current_stamina, max_stamina)
		return true
	return false

func restore_stamina(amount: float) -> void:
	current_stamina = minf(max_stamina, current_stamina + amount)
	stamina_changed.emit(current_stamina, max_stamina)
