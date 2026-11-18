extends Area2D
class_name ShotgunPellet

# High-velocity plasma/tracer buckshot pellet projectile with Line2D streak trail.

const SPARK_SCENE: PackedScene = preload("res://scenes/effects/bullet_spark.tscn")

@export var speed: float = 680.0
@export var damage: int = 1
@export var lifetime: float = 0.35

var direction: Vector2 = Vector2.RIGHT
var _time_alive: float = 0.0
var _trail_line: Line2D = null

func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 8  # Layer 4: PlayerAttacks
	collision_mask = 37  # Layer 1: World + Layer 3: Enemies + Layer 6: Horde
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Glowing golden-orange Line2D tracer streak behind each pellet
	_trail_line = Line2D.new()
	_trail_line.width = 2.0
	_trail_line.points = PackedVector2Array([Vector2(-14.0, 0.0), Vector2.ZERO])
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.45, 0.1, 0.0))
	grad.set_color(1, Color(1.0, 0.92, 0.45, 0.95))
	_trail_line.gradient = grad
	add_child(_trail_line)

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
	var spark = SPARK_SCENE.instantiate()
	spark.global_position = global_position
	get_tree().current_scene.add_child(spark)
	if AudioManager:
		AudioManager.play_sfx("impact_metal", 0.08)
