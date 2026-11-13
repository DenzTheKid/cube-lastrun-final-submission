extends Area2D
class_name ShotgunPellet

# Double-barrel shotgun buckshot pellet projectile.

@export var speed: float = 650.0
@export var damage: int = 1
@export var lifetime: float = 0.35

var direction: Vector2 = Vector2.RIGHT
var _time_alive: float = 0.0

func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 8 # Layer 4: PlayerAttacks
	collision_mask = 5  # Layer 1: World + Layer 3: Enemies
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup(dir: Vector2, start_pos: Vector2) -> void:
	direction = dir.normalized()
	global_position = start_pos
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, direction)
	_spawn_impact()
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	var target: Node = area.get_parent()
	if target and target.has_method("take_damage"):
		target.take_damage(damage, direction)
	elif area.has_method("take_damage"):
		area.take_damage(damage, direction)
	_spawn_impact()
	queue_free()

func _spawn_impact() -> void:
	# Subtle spark effect at impact point
	pass
