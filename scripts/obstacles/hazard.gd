extends Area2D
class_name Hazard

# Obstacle hazard: Spikes, Pits, or Barricades that damage the player on touch.

@export var damage: int = 1
@export var is_lethal: bool = false # Pits are instantly lethal

func _ready() -> void:
	collision_layer = 16 # Layer 5: Hazards
	collision_mask = 2   # Layer 2: Player
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if is_lethal:
			body.die()
		else:
			body.take_damage(damage, Vector2(-1.0, -0.5))
