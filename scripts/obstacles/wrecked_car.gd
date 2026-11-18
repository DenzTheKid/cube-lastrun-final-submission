extends StaticBody2D
class_name WreckedCar

# Stationary abandoned wrecked vehicle obstacle on the highway road.
# Supports four visual/collider variants cleanly: ambulance, sedan, police, and bus.

const TEX_AMBULANCE: Texture2D = preload("res://assets/obstacles/px_wrecked_car.png")
const TEX_SEDAN: Texture2D = preload("res://assets/obstacles/px_wrecked_sedan.png")
const TEX_POLICE: Texture2D = preload("res://assets/obstacles/px_wrecked_police.png")
const TEX_BUS: Texture2D = preload("res://assets/obstacles/px_wrecked_bus.png")

const VARIANT_SPECS: Dictionary = {
	"ambulance": {
		"tex": TEX_AMBULANCE,
		"sprite_y": -16.0,
		"chassis_size": Vector2(66, 16),
		"chassis_pos": Vector2(0, -8),
		"cabin_size": Vector2(46, 15),
		"cabin_pos": Vector2(10, -23.5),
		"smoke_pos": Vector2(-24, -18),
	},
	"sedan": {
		"tex": TEX_SEDAN,
		"sprite_y": -14.0,
		"chassis_size": Vector2(60, 15),
		"chassis_pos": Vector2(0, -7.5),
		"cabin_size": Vector2(30, 11),
		"cabin_pos": Vector2(3, -20.5),
		"smoke_pos": Vector2(-22, -16),
	},
	"police": {
		"tex": TEX_POLICE,
		"sprite_y": -14.5,
		"chassis_size": Vector2(60, 15),
		"chassis_pos": Vector2(0, -7.5),
		"cabin_size": Vector2(30, 12),
		"cabin_pos": Vector2(3, -21.0),
		"smoke_pos": Vector2(-22, -16),
	},
	"bus": {
		"tex": TEX_BUS,
		"sprite_y": -17.0,
		"chassis_size": Vector2(88, 17),
		"chassis_pos": Vector2(0, -8.5),
		"cabin_size": Vector2(80, 15),
		"cabin_pos": Vector2(2, -24.5),
		"smoke_pos": Vector2(38, -18),
	},
}

@export_enum("ambulance", "sedan", "police", "bus") var vehicle_variant: String = "ambulance"

@onready var sprite: Sprite2D = $Sprite2D
@onready var chassis_col: CollisionShape2D = $ChassisCollision
@onready var cabin_col: CollisionShape2D = $CabinCollision
@onready var smoke_particles: CPUParticles2D = get_node_or_null("SmokeParticles")

func _ready() -> void:
	collision_layer = 1 # Layer 1: World
	collision_mask = 6  # Layer 2: Player + Layer 3: Enemies
	_apply_variant(vehicle_variant)
	if smoke_particles:
		var root: Node = get_tree().current_scene
		smoke_particles.emitting = not (root and root.name == "TestRunner")

func set_variant(variant_name: String) -> void:
	vehicle_variant = variant_name if VARIANT_SPECS.has(variant_name) else "ambulance"
	if is_inside_tree():
		_apply_variant(vehicle_variant)

func _apply_variant(variant_name: String) -> void:
	var key: String = variant_name if VARIANT_SPECS.has(variant_name) else "ambulance"
	var spec: Dictionary = VARIANT_SPECS[key]

	if sprite:
		sprite.texture = spec["tex"]
		sprite.position = Vector2(0.0, spec["sprite_y"])
	if chassis_col:
		var r1 := RectangleShape2D.new()
		r1.size = spec["chassis_size"]
		chassis_col.shape = r1
		chassis_col.position = spec["chassis_pos"]
	if cabin_col:
		var r2 := RectangleShape2D.new()
		r2.size = spec["cabin_size"]
		cabin_col.shape = r2
		cabin_col.position = spec["cabin_pos"]
	if smoke_particles:
		smoke_particles.position = spec["smoke_pos"]
