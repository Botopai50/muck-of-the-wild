class_name FloatingText
extends Node3D

## Números de dano flutuantes estilo Pop Comic (Zelda BotW / Muck)
## Animação punchy com pop elástico de escala, inclinação cômica,
## contorno preto espesso e cores vibrantes.

@onready var label: Label3D = $Label3D

func setup(text: String, color: Color = Color(1.0, 0.9, 0.2), is_critical: bool = false) -> void:
	if not label:
		label = $Label3D
		
	if is_critical:
		label.text = "💥 %s!" % text
		label.modulate = Color(1.0, 0.25, 0.25)
		label.outline_modulate = Color(0.05, 0.05, 0.05, 1.0)
		label.outline_size = 16
		label.font_size = 52
	else:
		label.text = text
		label.modulate = color
		label.outline_modulate = Color(0.08, 0.08, 0.08, 1.0)
		label.outline_size = 12
		label.font_size = 40

func _ready() -> void:
	# Efeito Pop Comic com escala elástica e inclinação
	scale = Vector3(0.2, 0.2, 0.2)
	rotation_degrees.z = randf_range(-16.0, 16.0)
	
	var rand_x := randf_range(-0.5, 0.5)
	var rand_z := randf_range(-0.3, 0.3)
	var end_pos := position + Vector3(rand_x, 1.9, rand_z)
	
	var tween := create_tween()
	# Pop-in elástico explosivo (0.2 -> 1.35 -> 1.0)
	tween.tween_property(self, "scale", Vector3(1.35, 1.35, 1.35), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# Subida em arco e fade out suave
	var tween_move := create_tween().set_parallel(true)
	tween_move.tween_property(self, "position", end_pos, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween_move.tween_property(label, "modulate:a", 0.0, 0.45).set_delay(0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_move.tween_property(label, "outline_modulate:a", 0.0, 0.45).set_delay(0.45)
	
	tween_move.chain().tween_callback(queue_free)
