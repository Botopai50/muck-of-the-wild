class_name DropItem
extends CharacterBody3D

## Item físico deixado por inimigos ou baús (Moedas, Comida, Minérios, Gemas)
## Possui gravidade, salto inicial aleatório e atração magnética ao jogador

enum ItemType {
	COIN,
	MEAT,
	APPLE,
	WOOD,
	STONE,
	IRON_ORE,
	RUBY,
	DIAMOND
}

@export var item_type: ItemType = ItemType.COIN
@export var amount: int = 1

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var light: OmniLight3D = $OmniLight3D

var gravity: float = 14.0
var can_pickup: bool = false
var target_player: Node3D = null
var magnet_speed: float = 10.0

func _ready() -> void:
	collision_layer = 0 # Não bloqueia o jogador, detectado por área
	collision_mask = 1  # Colide com chão (mundo)
	
	# Impulso físico aleatório ao surgir
	var rand_angle := randf_range(0.0, TAU)
	var h_speed := randf_range(1.5, 3.5)
	velocity = Vector3(cos(rand_angle) * h_speed, randf_range(3.0, 5.5), sin(rand_angle) * h_speed)
	
	_apply_visuals()
	
	# Delay curto de 0.3s antes de poder ser coletado
	get_tree().create_timer(0.3).timeout.connect(func(): can_pickup = true)

func setup(type: ItemType, count: int = 1) -> void:
	item_type = type
	amount = count
	if is_inside_tree():
		_apply_visuals()

func _apply_visuals() -> void:
	if not mesh_instance:
		return
		
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.roughness = 0.3
	
	match item_type:
		ItemType.COIN:
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.2
			cyl.bottom_radius = 0.2
			cyl.height = 0.08
			mesh_instance.mesh = cyl
			mat.albedo_color = Color(1.0, 0.85, 0.1)
			mat.metallic = 0.8
			mat.emission_enabled = true
			mat.emission = Color(0.8, 0.6, 0.05)
			mat.emission_energy_multiplier = 0.5
		ItemType.MEAT:
			var cap := CapsuleMesh.new()
			cap.radius = 0.15
			cap.height = 0.35
			mesh_instance.mesh = cap
			mat.albedo_color = Color(0.85, 0.28, 0.22)
		ItemType.APPLE:
			var sph := SphereMesh.new()
			sph.radius = 0.18
			sph.height = 0.36
			mesh_instance.mesh = sph
			mat.albedo_color = Color(0.9, 0.12, 0.15)
		ItemType.WOOD:
			var box := BoxMesh.new()
			box.size = Vector3(0.25, 0.25, 0.5)
			mesh_instance.mesh = box
			mat.albedo_color = Color(0.55, 0.35, 0.18)
		ItemType.STONE:
			var box := BoxMesh.new()
			box.size = Vector3(0.3, 0.25, 0.3)
			mesh_instance.mesh = box
			mat.albedo_color = Color(0.55, 0.55, 0.58)
		ItemType.IRON_ORE:
			var box := BoxMesh.new()
			box.size = Vector3(0.32, 0.28, 0.32)
			mesh_instance.mesh = box
			mat.albedo_color = Color(0.7, 0.72, 0.78)
			mat.metallic = 0.7
		ItemType.RUBY:
			var sph := SphereMesh.new()
			sph.radius = 0.2
			sph.height = 0.35
			mesh_instance.mesh = sph
			mat.albedo_color = Color(1.0, 0.15, 0.35)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.1, 0.3)
			mat.emission_energy_multiplier = 1.0
		ItemType.DIAMOND:
			var sph := SphereMesh.new()
			sph.radius = 0.22
			sph.height = 0.38
			mesh_instance.mesh = sph
			mat.albedo_color = Color(0.25, 0.85, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.2, 0.8, 1.0)
			mat.emission_energy_multiplier = 1.2
			
	mesh_instance.material_override = mat

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.x = move_toward(velocity.x, 0.0, delta * 6.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 6.0)
		
	# Efeito de rotação contínua
	mesh_instance.rotate_y(delta * 2.5)
	
	# Atração pelo jogador quando perto
	if can_pickup and target_player:
		var dir := (target_player.global_position + Vector3(0, 1.0, 0) - global_position)
		var dist := dir.length()
		if dist < 0.8:
			_collect(target_player)
			return
		velocity = dir.normalized() * magnet_speed
		magnet_speed += delta * 15.0
	elif can_pickup:
		_check_nearby_player()
		
	move_and_slide()

func _check_nearby_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p: Node3D = players[0]
		if global_position.distance_to(p.global_position) < 4.5:
			target_player = p

func _collect(p: Node3D) -> void:
	AudioSynth.play_sound(p, "pickup", -4.0, randf_range(0.95, 1.15))
	
	if p.has_method("add_item_drop"):
		p.add_item_drop(item_type, amount)
		
	# Spawn pequeno texto de coleta
	var label_name := ""
	var col := Color(1.0, 1.0, 0.3)
	match item_type:
		ItemType.COIN:
			label_name = "+%d Moedas" % amount
			col = Color(1.0, 0.85, 0.1)
		ItemType.MEAT:
			label_name = "+%d Carne" % amount
			col = Color(1.0, 0.5, 0.4)
		ItemType.APPLE:
			label_name = "+%d Maca" % amount
			col = Color(0.9, 0.3, 0.3)
		ItemType.WOOD:
			label_name = "+%d Madeira" % amount
			col = Color(0.8, 0.6, 0.3)
		ItemType.STONE:
			label_name = "+%d Pedra" % amount
			col = Color(0.7, 0.7, 0.7)
		ItemType.IRON_ORE:
			label_name = "+%d Ferro" % amount
			col = Color(0.8, 0.85, 1.0)
		ItemType.RUBY:
			label_name = "+%d Rubi Raro!" % amount
			col = Color(1.0, 0.2, 0.4)
		ItemType.DIAMOND:
			label_name = "+%d Diamante Lendario!" % amount
			col = Color(0.3, 0.9, 1.0)
			
	var ft_scene = load("res://scenes/ui/floating_text.tscn")
	if ft_scene:
		var ft = ft_scene.instantiate()
		get_parent().add_child(ft)
		ft.global_position = global_position + Vector3(0, 0.5, 0)
		ft.setup(label_name, col)
		
	queue_free()
