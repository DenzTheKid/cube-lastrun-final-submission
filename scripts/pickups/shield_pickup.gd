extends Area2D
class_name ShieldPickup

# Collectible Tactical Energy Shield pickup.
# Grants +1 temporary cobalt armor layer on contact to absorb 1 hazard/zombie hit.

@export var shield_amount: int = 1
@export var bob_amplitude: float = 2.8
@export var bob_speed: float = 3.8

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
		glow_light.energy = 0.34 + 0.12 * sin(_bob_time * 5.0)

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body is Player:
		var player: Player = body as Player
		if player.is_dead or player.is_transforming:
			return
		_collected = true
		set_deferred("monitoring", false)
		player.grant_shield(shield_amount)
		queue_free()
