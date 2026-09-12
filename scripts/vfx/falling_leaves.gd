class_name FallingLeaves
extends GPUParticles3D

## Efeito de Folhas de Bétula Caindo (Falling Leaves)
## Simula folhas douradas e verde-claras que se desprendem suavemente da copa
## das arvores de betula e flutuam com as rajadas de vento tipicas de Hyrule.

@export var wind_direction: Vector2 = Vector2(1.0, 0.3)
@export var wind_sway_speed: float = 1.8

var _time_accum: float = 0.0

func _ready() -> void:
	emitting = true
	_apply_wind_drift()

func _apply_wind_drift() -> void:
	if process_material is ParticleProcessMaterial:
		var pm := process_material as ParticleProcessMaterial
		var norm_wind = wind_direction.normalized()
		pm.direction = Vector3(norm_wind.x, -0.3, norm_wind.y)

func _process(delta: float) -> void:
	_time_accum += delta * wind_sway_speed
	# Pequena modulacao ritmica do vento
	if process_material is ParticleProcessMaterial:
		var pm := process_material as ParticleProcessMaterial
		var gust = sin(_time_accum) * 0.3 + cos(_time_accum * 1.7) * 0.15
		var norm_wind = wind_direction.normalized()
		pm.direction = Vector3(norm_wind.x, -0.3 + gust * 0.1, norm_wind.y)

## Dispara rajada de folhas quando a arvore e golpeada
func burst_flurry() -> void:
	var prev_amount = amount
	amount = int(amount * 1.5)
	restart()
	amount = prev_amount
