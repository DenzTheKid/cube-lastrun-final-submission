extends StaticBody2D
class_name WreckedCar

# Stationary abandoned wrecked car obstacle sitting on the highway road.
# Solid multi-tier collider lets the player vault over it or traverse hood -> roof
# and blocks pellets with metal sparks while trailing faint busted-engine smoke.

@onready var smoke_particles: CPUParticles2D = get_node_or_null("SmokeParticles")

func _ready() -> void:
	collision_layer = 1 # Layer 1: World
	collision_mask = 6  # Layer 2: Player + Layer 3: Enemies
	if smoke_particles:
		var root: Node = get_tree().current_scene
		if root and root.name == "TestRunner":
			smoke_particles.emitting = false
		else:
			smoke_particles.emitting = true
