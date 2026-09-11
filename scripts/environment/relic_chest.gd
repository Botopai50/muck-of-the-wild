class_name RelicChest
extends StaticBody3D

## Baú de Relíquia estilizado Zelda BotW / Muck
## Ao interagir com "E", abre suavemente e concede uma relíquia permanente com fanfarra

signal opened(relic_info)

const RELIC_POOL := [
	{
		"id": "hermes_boots",
		"name": "Botas de Hermes",
		"icon": "👢",
		"description": "+25% Velocidade de Corrida permanente",
		"stat": "speed_mult",
		"value": 0.25,
		"color": Color(0.2, 0.9, 0.6)
	},
	{
		"id": "heart_fruit",
		"name": "Fruta do Coração Ancestral",
		"icon": "❤️",
		"description": "+50 Vida Máxima permanente e Cura Total",
		"stat": "max_hp",
		"value": 50.0,
		"color": Color(1.0, 0.2, 0.3)
	},
	{
		"id": "crimson_dagger",
		"name": "Adaga Carmesim",
		"icon": "🗡️",
		"description": "+14 Dano de Ataque permanente",
		"stat": "damage_bonus",
		"value": 14.0,
		"color": Color(1.0, 0.3, 0.1)
	},
	{
		"id": "zephyr_wings",
		"name": "Asas de Zéfiro",
		"icon": "🪽",
		"description": "Desbloqueia Pulo Duplo no ar permanente",
		"stat": "double_jump",
		"value": 1.0,
		"color": Color(0.4, 0.8, 1.0)
	},
	{
		"id": "fury_gloves",
		"name": "Luvas de Fúria",
		"icon": "🥊",
		"description": "+35% Velocidade de Golpe permanente",
		"stat": "attack_speed",
		"value": 0.35,
		"color": Color(1.0, 0.6, 0.1)
	},
	{
		"id": "stone_shield",
		"name": "Escudo de Rocha Viva",
		"icon": "🛡️",
		"description": "+25% Redução de Dano recebido",
		"stat": "defense_mult",
		"value": 0.25,
		"color": Color(0.7, 0.7, 0.85)
	},
	{
		"id": "lucky_clover",
		"name": "Trevo Dourado da Sorte",
		"icon": "🍀",
		"description": "+100% Moedas coletadas e +15% Chance de Crítico",
		"stat": "luck_mult",
		"value": 1.0,
		"color": Color(0.9, 0.85, 0.2)
	}
]

@onready var lid_pivot: Node3D = $LidPivot
@onready var prompt_label: Label3D = $PromptLabel
@onready var chest_light: OmniLight3D = $ChestLight
@onready var relic_visual: Node3D = $RelicVisual
@onready var interact_area: Area3D = $InteractArea

var is_opened: bool = false
var player_in_range: Node3D = null

func _ready() -> void:
	add_to_group("interactables")
	prompt_label.visible = false
	chest_light.light_energy = 0.0
	relic_visual.visible = false
	
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if is_opened:
		return
	if body.is_in_group("player"):
		player_in_range = body
		prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
		prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if is_opened or not player_in_range:
		return
		
	if event.is_action_pressed("interact"):
		interact(player_in_range)
		get_viewport().set_input_as_handled()

func interact(player: Node3D) -> void:
	if is_opened:
		return
	is_opened = true
	prompt_label.visible = false
	
	# Escolher relíquia aleatória
	var relic: Dictionary = RELIC_POOL.pick_random()
	
	# Tocar fanfarra e abertura
	AudioSynth.play_sound(self, "chest_open", 1.0)
	
	# Animação da tampa se abrindo com rotação suave
	var tween := create_tween().set_parallel(true)
	tween.tween_property(lid_pivot, "rotation_degrees:x", -115.0, 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(chest_light, "light_energy", 2.5, 0.5)
	
	# Relíquia emergindo e girando
	relic_visual.visible = true
	relic_visual.position = Vector3(0, 0.3, 0)
	relic_visual.scale = Vector3.ZERO
	tween.tween_property(relic_visual, "position:y", 1.2, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(relic_visual, "scale", Vector3(1.2, 1.2, 1.2), 0.85).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(relic_visual, "rotation_degrees:y", 720.0, 1.5)
	
	# Aplicar bônus ao jogador e mostrar notificação na tela
	if player and player.has_method("grant_relic"):
		player.grant_relic(relic)
		
	emit_signal("opened", relic)
	print("[Baú de Relíquia] Aberto! Relíquia concedida: ", relic["name"])
	
	# Apagar luz e relíquia flutuante após 3 segundos
	tween.chain().tween_interval(1.8)
	tween.chain().tween_property(relic_visual, "scale", Vector3.ZERO, 0.4)
	tween.parallel().tween_property(chest_light, "light_energy", 0.4, 0.4)
