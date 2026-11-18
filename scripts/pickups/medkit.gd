extends Area2D
class_name MedkitPickup

# Collectible first-aid Medkit item.
# Restores +1 HP on player contact (clamped safely to max_hp) with crisp audio & popup feedback.

@export var heal_amount: int = 1
@export var bob_amplitude: float = 2.5
@export var bob_speed: float = 3.6

var _collected: bool = false
var _bob_time: float = 0.0
var _base_sprite_y: float = -10.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var glow_light: PointLight2D = get_node_or_null("GlowLight")

func _ready() -> void:
	collision_layer = 64 # Layer 7: Pickups
	collision_mask = 2   # Layer 2: Player
	monitoring = true
	monitorable = false
	if sprite:
		_base_sprite_y = sprite.position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _collected:
		return
	_bob_time += delta
	var offset_y: float = sin(_bob_time * bob_speed) * bob_amplitude
	if sprite:
		sprite.position.y = _base_sprite_y + offset_y
	if glow_light:
		glow_light.position.y = _base_sprite_y + offset_y
		glow_light.energy = 0.28 + 0.08 * sin(_bob_time * 4.5)

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body is Player:
		var player: Player = body as Player
		if player.is_dead or player.is_transforming:
			return
		_collected = true
		set_deferred("monitoring", false)
		player.heal(heal_amount)
		queue_free()
