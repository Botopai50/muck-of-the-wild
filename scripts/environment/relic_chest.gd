class_name RelicChest
extends StaticBody3D

## Baú de Relíquias Ancestral Sheikah (Zelda BotW x Muck)
## Design Sheikah com gema ciano resplandecente no topo da tampa.
## Ao interagir, projeta um feixe de luz vertical celestial, libera partículas,
## abre a tampa em animação épica e notifica o jogador com fanfarra musical.

signal opened(relic_info)

const RELIC_POOL := [
	{
		"id": "hermes_boots",
		"name": "Botas de Hermes",
		"icon": "👢",
		"description": "+25% Velocidade de Corrida permanente",
		"stat": "speed_mult",
		"value": 0.25,
		"color": Color(0.2, 0.95, 0.65)
	},
	{
		"id": "heart_fruit",
		"name": "Fruta do Coração Ancestral",
		"icon": "❤️",
		"description": "+50 Vida Máxima permanente e Cura Total",
		"stat": "max_hp",
		"value": 50.0,
		"color": Color(1.0, 0.25, 0.35)
	},
	{
		"id": "crimson_dagger",
		"name": "Adaga Carmesim Sheikah",
		"icon": "🗡️",
		"description": "+15 Dano de Ataque permanente",
		"stat": "damage_bonus",
		"value": 15.0,
		"color": Color(1.0, 0.35, 0.15)
	},
	{
		"id": "zephyr_wings",
		"name": "Asas de Zéfiro",
		"icon": "🪽",
		"description": "Desbloqueia Pulo Duplo permanente no ar",
		"stat": "double_jump",
		"value": 1.0,
		"color": Color(0.35, 0.85, 1.0)
	},
	{
		"id": "fury_gloves",
		"name": "Manoplas do Guardião",
		"icon": "🥊",
		"description": "+35% Velocidade de Ataque permanente",
		"stat": "attack_speed",
		"value": 0.35,
		"color": Color(1.0, 0.65, 0.1)
	},
	{
		"id": "stone_shield",
		"name": "Escudo de Rocha Sheikah",
		"icon": "🛡️",
		"description": "+25% Redução de Dano recebido",
		"stat": "defense_mult",
		"value": 0.25,
		"color": Color(0.65, 0.75, 0.95)
	},
	{
		"id": "lucky_clover",
		"name": "Trevo Sagrado de Ouro",
		"icon": "🍀",
		"description": "+100% Moedas coletadas e +15% Chance de Crítico",
		"stat": "luck_mult",
		"value": 1.0,
		"color": Color(1.0, 0.90, 0.2)
	}
]

@onready var lid_pivot: Node3D = $LidPivot
@onready var prompt_label: Label3D = $PromptLabel
@onready var chest_light: OmniLight3D = $ChestLight
@onready var gem_light: OmniLight3D = $LidPivot/Lid/GemLight
@onready var vertical_beam: MeshInstance3D = $VerticalLightBeam
@onready var beam_particles: CPUParticles3D = $BeamParticles
@onready var relic_visual: Node3D = $RelicVisual
@onready var relic_name_label: Label3D = $RelicVisual/RelicNameLabel
@onready var interact_area: Area3D = $InteractArea

var is_opened: bool = false
var player_in_range: Node3D = null

func _ready() -> void:
	add_to_group("interactables")
	add_to_group("chest")
	
	if prompt_label:
		prompt_label.visible = false
	if chest_light:
		chest_light.light_energy = 0.0
	if vertical_beam:
		vertical_beam.visible = false
		vertical_beam.scale = Vector3(1.0, 0.0, 1.0)
	if beam_particles:
		beam_particles.emitting = false
	if relic_visual:
		relic_visual.visible = false

	if interact_area:
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if is_opened:
		return
	if body.is_in_group("player"):
		player_in_range = body
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body == player_in_range:
		player_in_range = null
		if prompt_label:
			prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if is_opened or not player_in_range:
		return
		
	if event.is_action_pressed("interact"):
		interact(player_in_range)
		get_viewport().set_input_as_handled()

func open(player: Node3D = null) -> void:
	interact(player)

func open_chest(player: Node3D = null) -> void:
	interact(player)

func interact(player: Node3D = null) -> void:
	if is_opened:
		return
	is_opened = true
	
	if prompt_label:
		prompt_label.visible = false
		
	var target_p = player if player else player_in_range
	if not target_p:
		var tree := get_tree()
		if tree:
			var players := tree.get_nodes_in_group("player")
			if players.size() > 0:
				target_p = players[0]
			
	var relic: Dictionary = RELIC_POOL.pick_random()
	
	# Fanfarra mágica refinada
	AudioSynth.play_sound(self, "chest_open", 2.0)
	
	if not lid_pivot: lid_pivot = get_node_or_null("LidPivot")
	if not vertical_beam: vertical_beam = get_node_or_null("VerticalLightBeam")
	if not beam_particles: beam_particles = get_node_or_null("BeamParticles")
	if not chest_light: chest_light = get_node_or_null("ChestLight")
	if not gem_light and lid_pivot: gem_light = lid_pivot.get_node_or_null("Lid/GemLight")
	if not relic_visual: relic_visual = get_node_or_null("RelicVisual")
	if not relic_name_label and relic_visual: relic_name_label = relic_visual.get_node_or_null("RelicNameLabel")

	# Sequência cinematográfica de abertura Sheikah
	var tween := create_tween().set_parallel(true)
	
	# 1. Feixe de luz vertical disparando aos céus
	if vertical_beam:
		vertical_beam.visible = true
		vertical_beam.scale = Vector3(0.2, 0.0, 0.2)
		tween.tween_property(vertical_beam, "scale", Vector3(1.2, 1.0, 1.2), 0.45).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		var mat := vertical_beam.get_active_material(0)
		if mat and mat is StandardMaterial3D:
			var dup_mat = mat.duplicate()
			vertical_beam.material_override = dup_mat
			tween.tween_property(dup_mat, "albedo_color:a", 0.0, 2.5).set_delay(0.6)
			
	if beam_particles:
		beam_particles.emitting = true
		beam_particles.restart()
		
	# 2. Abertura suave da tampa Sheikah
	if lid_pivot:
		tween.tween_property(lid_pivot, "rotation_degrees:x", -125.0, 0.85).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if chest_light:
		tween.tween_property(chest_light, "light_energy", 3.2, 0.5)
	if gem_light:
		tween.tween_property(gem_light, "light_energy", 4.0, 0.4)
		
	# 3. Relíquia emergindo no centro do feixe de luz
	if relic_visual:
		relic_visual.visible = true
		relic_visual.position = Vector3(0, 0.4, 0)
		relic_visual.scale = Vector3.ZERO
		tween.tween_property(relic_visual, "position:y", 1.4, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(relic_visual, "scale", Vector3(1.3, 1.3, 1.3), 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(relic_visual, "rotation_degrees:y", 720.0, 2.2)
		
		if relic_name_label:
			relic_name_label.text = "%s %s\n%s" % [relic.get("icon", "✦"), relic.get("name", ""), relic.get("description", "")]
			relic_name_label.modulate = relic.get("color", Color(0.2, 0.95, 1.0))
			relic_name_label.visible = true
			relic_name_label.modulate.a = 0.0
			tween.tween_property(relic_name_label, "modulate:a", 1.0, 0.5).set_delay(0.4)
			
	# 4. Conceder relíquia ao jogador (aciona banner no HUD)
	if target_p and target_p.has_method("grant_relic"):
		target_p.grant_relic(relic)
		
	emit_signal("opened", relic)
	print("[Baú Sheikah] Relíquia obtida com fanfarra: ", relic["name"])
	
	# Desvanecer feixe e relíquia após o momento triunfal
	tween.chain().tween_interval(2.2)
	if relic_visual:
		tween.chain().tween_property(relic_visual, "scale", Vector3.ZERO, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if chest_light:
		tween.parallel().tween_property(chest_light, "light_energy", 0.5, 0.5)
	if vertical_beam:
		tween.chain().tween_callback(_hide_vertical_beam)

func _hide_vertical_beam() -> void:
	if vertical_beam:
		vertical_beam.visible = false