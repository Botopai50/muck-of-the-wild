class_name PlayerHUD
extends CanvasLayer

## PlayerHUD: Visual UI for Muck of the Wild (BotW Stylized)
## Exibe mira, vitais (vida/stamina/fome), hotbar, relógio do ciclo Dia/Noite,
## avisos de suspense ao pôr do sol, alerta de invasão noturna e fanfarra de relíquia.

@export var player: PlayerController
@export var interaction_ray: InteractionRay

@onready var health_bar: ProgressBar = $MarginContainer/Vitals/HealthBar
@onready var stamina_bar: ProgressBar = $MarginContainer/Vitals/StaminaBar
@onready var hunger_bar: ProgressBar = $MarginContainer/Vitals/HungerBar
@onready var prompt_label: Label = $CenterContainer/PromptLabel
@onready var hotbar_container: HBoxContainer = $BottomContainer/Hotbar

# Nós criados dinamicamente para o Ciclo Dia/Noite e Notificações de Relíquias
var day_label: Label
var time_label: Label
var coins_label: Label
var relic_banner_panel: PanelContainer
var relic_banner_title: Label
var relic_banner_desc: Label
var alert_banner_label: Label

func _ready() -> void:
	if player:
		player.health_changed.connect(_on_health_changed)
		player.stamina_changed.connect(_on_stamina_changed)
		player.hunger_changed.connect(_on_hunger_changed)
		player.hotbar_slot_changed.connect(_on_hotbar_slot_changed)
		if player.has_signal("relic_obtained"):
			player.relic_obtained.connect(_show_relic_banner)

	if interaction_ray:
		interaction_ray.prompt_changed.connect(_on_prompt_changed)

	_setup_dynamic_ui_elements()
	_connect_to_game_manager()

func _setup_dynamic_ui_elements() -> void:
	# 1. Widget de Ciclo Dia e Noite no topo direito
	var top_right := MarginContainer.new()
	top_right.name = "TopRightClock"
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.offset_left = -260.0
	top_right.offset_bottom = 90.0
	top_right.add_theme_constant_override("margin_right", 24)
	top_right.add_theme_constant_override("margin_top", 18)
	add_child(top_right)

	var clock_vbox := VBoxContainer.new()
	top_right.add_child(clock_vbox)

	day_label = Label.new()
	day_label.text = "☀️ DIA 1"
	day_label.add_theme_font_size_override("font_size", 22)
	day_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	day_label.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.1))
	day_label.add_theme_constant_override("outline_size", 6)
	clock_vbox.add_child(day_label)

	time_label = Label.new()
	time_label.text = "06:00 (Amanhecer)"
	time_label.add_theme_font_size_override("font_size", 16)
	time_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	time_label.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.1))
	time_label.add_theme_constant_override("outline_size", 4)
	clock_vbox.add_child(time_label)

	# 2. Contador de Moedas e Relíquias no topo esquerdo
	var top_left := MarginContainer.new()
	top_left.name = "TopLeftStats"
	top_left.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top_left.offset_right = 260.0
	top_left.offset_bottom = 60.0
	top_left.add_theme_constant_override("margin_left", 24)
	top_left.add_theme_constant_override("margin_top", 18)
	add_child(top_left)

	coins_label = Label.new()
	coins_label.text = "🪙 0 Moedas"
	coins_label.add_theme_font_size_override("font_size", 18)
	coins_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	coins_label.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.1))
	coins_label.add_theme_constant_override("outline_size", 5)
	top_left.add_child(coins_label)

	# 3. Alerta de Suspense do Pôr do Sol e Invasão Noturna no topo centro
	var alert_center := MarginContainer.new()
	alert_center.set_anchors_preset(Control.PRESET_CENTER_TOP)
	alert_center.offset_left = -300.0
	alert_center.offset_right = 300.0
	alert_center.offset_top = 80.0
	alert_center.offset_bottom = 150.0
	add_child(alert_center)

	alert_banner_label = Label.new()
	alert_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert_banner_label.visible = false
	alert_center.add_child(alert_banner_label)

	# 4. Banner Fanfarra de Relíquia estilo Zelda BotW
	relic_banner_panel = PanelContainer.new()
	relic_banner_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	relic_banner_panel.offset_left = -280.0
	relic_banner_panel.offset_right = 280.0
	relic_banner_panel.offset_top = 130.0
	relic_banner_panel.offset_bottom = 240.0
	relic_banner_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.15, 0.92)
	style.border_color = Color(1.0, 0.8, 0.2, 0.9)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	relic_banner_panel.add_theme_stylebox_override("panel", style)
	add_child(relic_banner_panel)

	var banner_vbox := VBoxContainer.new()
	banner_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	relic_banner_panel.add_child(banner_vbox)

	var sub_title := Label.new()
	sub_title.text = "✦ RELÍQUIA OBTIDA ✦"
	sub_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_title.add_theme_font_size_override("font_size", 14)
	sub_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	banner_vbox.add_child(sub_title)

	relic_banner_title = Label.new()
	relic_banner_title.text = "Botas de Hermes"
	relic_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relic_banner_title.add_theme_font_size_override("font_size", 24)
	relic_banner_title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	banner_vbox.add_child(relic_banner_title)

	relic_banner_desc = Label.new()
	relic_banner_desc.text = "+25% Velocidade de Movimento permanente"
	relic_banner_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relic_banner_desc.add_theme_font_size_override("font_size", 15)
	relic_banner_desc.add_theme_color_override("font_color", Color(0.4, 0.9, 0.6))
	banner_vbox.add_child(relic_banner_desc)

func _process(_delta: float) -> void:
	if player and coins_label:
		var c = player.get("coins")
		if c != null:
			coins_label.text = "🪙 %d Moedas" % int(c)

func _connect_to_game_manager() -> void:
	var gm := get_tree().get_first_node_in_group("game_manager") as GameManager
	if not gm:
		# Tentar após 1 frame
		get_tree().create_timer(0.2).timeout.connect(_connect_to_game_manager)
		return
		
	gm.time_updated.connect(_on_time_updated)
	gm.sunset_started.connect(_on_sunset_started)
	gm.night_started.connect(_on_night_started)
	gm.day_started.connect(_on_day_started)

func _on_time_updated(hour: int, minute: int, state_name: String, _progress: float) -> void:
	var gm := get_tree().get_first_node_in_group("game_manager") as GameManager
	var day_num := gm.current_day if gm else 1
	var icon := "☀️" if hour >= 6 and hour < 18 else "🌙"
	if state_name == "Pôr do Sol":
		icon = "🌅"
	elif state_name == "Amanhecer":
		icon = "🌄"
		
	if day_label:
		day_label.text = "%s DIA %d" % [icon, day_num]
		if state_name == "Noite":
			day_label.add_theme_color_override("font_color", Color(0.6, 0.75, 1.0))
		elif state_name == "Pôr do Sol":
			day_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.2))
		else:
			day_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
			
	if time_label:
		time_label.text = "%02d:%02d (%s)" % [hour, minute, state_name]

func _on_sunset_started() -> void:
	_show_alert_banner("⚠️ O SOL ESTÁ SE PONDO... PREPARE-SE! ⚠️", Color(1.0, 0.5, 0.15))

func _on_night_started(day_num: int, diff: float) -> void:
	_show_alert_banner("☠️ A NOITE CAIU! SOBREVIVA (Dia %d - Dificuldade x%.1f) ☠️" % [day_num, diff], Color(1.0, 0.2, 0.2))

func _on_day_started(day_num: int) -> void:
	_show_alert_banner("☀️ VOCÊ SOBREVIVEU! DIA %d ☀️" % day_num, Color(0.4, 1.0, 0.5))

func _show_alert_banner(text: String, col: Color) -> void:
	if not alert_banner_label:
		return
	alert_banner_label.text = text
	alert_banner_label.add_theme_font_size_override("font_size", 22)
	alert_banner_label.add_theme_color_override("font_color", col)
	alert_banner_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	alert_banner_label.add_theme_constant_override("outline_size", 8)
	alert_banner_label.visible = true
	alert_banner_label.modulate.a = 0.0
	
	var tween := create_tween()
	tween.tween_property(alert_banner_label, "modulate:a", 1.0, 0.4)
	tween.tween_interval(3.5)
	tween.tween_property(alert_banner_label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(func(): alert_banner_label.visible = false)

func _show_relic_banner(relic: Dictionary) -> void:
	if not relic_banner_panel:
		return
		
	relic_banner_title.text = "%s %s" % [relic.get("icon", "✦"), relic.get("name", "Relíquia")]
	relic_banner_desc.text = relic.get("description", "")
	var col: Color = relic.get("color", Color(1.0, 0.85, 0.2))
	relic_banner_desc.add_theme_color_override("font_color", col)
	
	relic_banner_panel.visible = true
	relic_banner_panel.scale = Vector2(0.6, 0.6)
	relic_banner_panel.pivot_offset = relic_banner_panel.size * 0.5
	relic_banner_panel.modulate.a = 0.0
	
	var tween := create_tween()
	tween.tween_property(relic_banner_panel, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(relic_banner_panel, "modulate:a", 1.0, 0.4)
	tween.tween_interval(4.0)
	tween.tween_property(relic_banner_panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): relic_banner_panel.visible = false)

func _on_health_changed(current: float, max_val: float) -> void:
	if health_bar:
		health_bar.max_value = max_val
		health_bar.value = current

func _on_stamina_changed(current: float, max_val: float) -> void:
	if stamina_bar:
		stamina_bar.max_value = max_val
		stamina_bar.value = current

func _on_hunger_changed(current: float, max_val: float) -> void:
	if hunger_bar:
		hunger_bar.max_value = max_val
		hunger_bar.value = current

func _on_prompt_changed(text: String) -> void:
	if prompt_label:
		prompt_label.text = text
		prompt_label.visible = not text.is_empty()

func _on_hotbar_slot_changed(slot_index: int, _item_name: String) -> void:
	if not hotbar_container:
		return
	for i in range(hotbar_container.get_child_count()):
		var slot_panel = hotbar_container.get_child(i)
		var is_active: bool = (i == slot_index)
		slot_panel.modulate = Color(1.2, 1.2, 0.6) if is_active else Color(0.8, 0.8, 0.8, 0.7)