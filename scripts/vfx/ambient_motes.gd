class_name AmbientMotes
extends Node3D

## Sistema de Partículas de Ambiente Atmosférico BotW
## Segue o jogador pela ilha e alterna dinamicamente entre:
## - Pólen / esporos dourados cintilantes durante o Dia e Pôr do Sol
## - Vaga-lumes bioluminescentes (verde e ciano) durante a Noite

@export var follow_player: bool = true
@export var follow_smoothness: float = 4.0
@export var default_height: float = 3.2

@onready var day_pollen: GPUParticles3D = $DayPollen
@onready var night_fireflies: GPUParticles3D = $NightFireflies

var player_ref: Node3D = null
var game_manager_ref: Node = null

func _ready() -> void:
	_find_references()
	_connect_game_manager()
	_update_environment_state(false)

func _process(delta: float) -> void:
	if follow_player:
		if not player_ref or not is_instance_valid(player_ref):
			_find_references()
		
		if player_ref and is_instance_valid(player_ref):
			var target_pos = Vector3(player_ref.global_position.x, default_height, player_ref.global_position.z)
			global_position = global_position.lerp(target_pos, delta * follow_smoothness)
	
	# Verificar transição periódica caso GameManager não use sinais
	_update_environment_state(false)

func _find_references() -> void:
	if not is_inside_tree() or not get_tree():
		return
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
	else:
		player_ref = get_node_or_null("../Player")
		
	var gms = get_tree().get_nodes_in_group("game_manager")
	if gms.size() > 0:
		game_manager_ref = gms[0]
	else:
		game_manager_ref = get_node_or_null("../GameManager")

func _connect_game_manager() -> void:
	if game_manager_ref and game_manager_ref.has_signal("state_changed"):
		if not game_manager_ref.is_connected("state_changed", _on_state_changed):
			game_manager_ref.connect("state_changed", _on_state_changed)

func _on_state_changed(_state_name: String) -> void:
	_update_environment_state(true)

func _update_environment_state(_force: bool) -> void:
	if not day_pollen:
		day_pollen = get_node_or_null("DayPollen")
	if not night_fireflies:
		night_fireflies = get_node_or_null("NightFireflies")
		
	var is_night = false
	var is_sunset = false
	
	if game_manager_ref:
		var current_state = game_manager_ref.get("current_state")
		if current_state != null:
			# GameManager.CycleState: DAWN(0), DAY(1), SUNSET(2), NIGHT(3)
			is_night = (current_state == 3)
			is_sunset = (current_state == 2)
	
	if day_pollen:
		# Pólen visível durante o dia, amanhecer e entardecer
		day_pollen.emitting = not is_night
	
	if night_fireflies:
		# Vaga-lumes despertam no pôr do sol e brilham a noite inteira
		night_fireflies.emitting = is_night or is_sunset
