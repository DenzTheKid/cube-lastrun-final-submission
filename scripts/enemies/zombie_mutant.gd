extends ZombieBase
class_name ZombieMutant

# Mutant zombie with unpredictable hopping / twitching behavior.

@export var hop_interval: float = 1.2
@export var hop_jump_force: float = 220.0
@export var hop_speed_mult: float = 1.8

var _hop_timer: float = 0.0
var is_hopping: bool = false

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_hop_timer += delta
	# Hop every 1.2 seconds if on floor
	if _hop_timer >= hop_interval:
		_hop_timer = 0.0
		if is_on_floor():
			hop()

	super._physics_process(delta)

	if is_hopping and is_on_floor() and velocity.y >= 0.0:
		land()

func hop() -> void:
	velocity.y = -hop_jump_force # Small jump
	velocity.x = -move_speed * hop_speed_mult
	is_hopping = true

func land() -> void:
	is_hopping = false
	velocity.x = -move_speed

func _apply_movement(_delta: float) -> void:
	if is_hopping:
		# Retain horizontal leap velocity while airborne
		if is_on_floor() and velocity.y >= 0.0:
			land()
	elif not is_on_floor() and absf(velocity.x) > move_speed:
		# Retain leap velocity even if triggered externally without hop()
		pass
	else:
		velocity.x = -move_speed
