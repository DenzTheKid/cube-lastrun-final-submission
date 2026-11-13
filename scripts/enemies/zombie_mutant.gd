extends ZombieBase
class_name ZombieMutant

# Mutant zombie with unpredictable hopping / twitching behavior.

var _hop_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_hop_timer += delta
	# Hop every 1.2 seconds if on floor
	if _hop_timer >= 1.2:
		_hop_timer = 0.0
		if is_on_floor():
			velocity.y = -220.0 # Small jump
			velocity.x = -move_speed * 1.8

	super._physics_process(delta)
