class_name FloatingText
extends Node3D

@onready var label: Label3D = $Label3D

func setup(text: String, color: Color = Color(1.0, 0.9, 0.2), is_critical: bool = false) -> void:
	if not label:
		label = $Label3D
	label.text = text
	label.modulate = color
	
	if is_critical:
		label.font_size = 48
		label.outline_modulate = Color(0.8, 0.1, 0.1)
		label.outline_size = 12
	else:
		label.font_size = 36
		label.outline_modulate = Color(0.1, 0.1, 0.1)
		label.outline_size = 8

func _ready() -> void:
	# Efeito de flutuar e sumir suavemente
	var rand_x := randf_range(-0.4, 0.4)
	var rand_z := randf_range(-0.4, 0.4)
	
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position", position + Vector3(rand_x, 1.8, rand_z), 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.85).set_delay(0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
