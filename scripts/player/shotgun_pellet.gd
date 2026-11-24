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
var _is_destroyed: bool = false
var _hit_targets: Dictionary = {}

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

func setup(dir: Vector2, start_pos: Vector2, tracer_color: Color = Color(1.0, 0.92, 0.45)) -> void:
	direction = dir.normalized()
	global_position = start_pos
	rotation = direction.angle()
	if _trail_line and _trail_line.gradient:
		var tail_col := Color(tracer_color.r, tracer_color.g, tracer_color.b, 0.0)
		var head_col := Color(tracer_color.r, tracer_color.g, tracer_color.b, 0.95)
		_trail_line.gradient.set_color(0, tail_col)
		_trail_line.gradient.set_color(1, head_col)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	_handle_hit(body, true)

func _on_area_entered(area: Area2D) -> void:
	_handle_hit(area, false)

func _handle_hit(collider: Node, is_solid_body: bool) -> void:
	if _is_destroyed or collider == null:
		return

	var target: Node = null
	if collider.has_method("take_damage"):
		target = collider
	elif collider.get_parent() and collider.get_parent().has_method("take_damage"):
		target = collider.get_parent()

	if target != null:
		var target_id: int = target.get_instance_id()
		if _hit_targets.has(target_id):
			return
		_hit_targets[target_id] = true
		target.take_damage(damage, direction)
	elif not is_solid_body:
		return

	_is_destroyed = true
	set_deferred("monitoring", false)
	_spawn_impact()
	queue_free()

func _spawn_impact() -> void:
	if SPARK_SCENE:
		var spark = SPARK_SCENE.instantiate()
		spark.global_position = global_position
		var current = get_tree().current_scene if get_tree() else null
		if current:
			current.add_child(spark)
		elif get_parent():
			get_parent().add_child(spark)
	if AudioManager:
		AudioManager.play_sfx("impact_concrete", 0.08)
