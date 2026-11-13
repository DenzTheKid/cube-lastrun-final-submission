extends CharacterBody2D
class_name ZombieBase

# Base class for front-facing zombie enemies.
# Handles movement towards the player, gravity, taking shotgun damage,
# hurt flash, death effects, and damaging the player.

@export var max_hp: int = 1
@export var move_speed: float = 30.0
@export var score_value: int = 100
@export var contact_damage: int = 1
@export var gravity: float = 980.0

var current_hp: int = 1
var is_dead: bool = false
var _anim_timer: float = 0.0
var _anim_frame: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	current_hp = max_hp
	collision_layer = 4 # Layer 3: Enemies
	collision_mask = 1  # Layer 1: World
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Move toward the player (to the left)
	velocity.x = -move_speed
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()
	_update_animation(delta)

	# Despawn if far behind player / horde
	var root: Node = get_tree().current_scene
	var player: Node2D = root.find_child("Player", true, false) as Node2D
	if player and global_position.x < player.global_position.x - 320.0:
		queue_free()

func _update_animation(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= 0.14:
		_anim_timer = 0.0
		_anim_frame = (_anim_frame + 1) % 4
		sprite.frame = _anim_frame

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	current_hp -= amount

	if AudioManager:
		AudioManager.play_sfx("zombie_hit", 0.1)

	# Flash white/red
	var tw: Tween = create_tween()
	sprite.modulate = Color(2.5, 0.4, 0.4, 1.0)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.12)

	# Knockback
	if knockback_dir != Vector2.ZERO:
		velocity.x += knockback_dir.x * 60.0

	if current_hp <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	collision_shape.set_deferred("disabled", true)
	if hitbox:
		hitbox.set_deferred("monitoring", false)

	if AudioManager:
		AudioManager.play_sfx("zombie_death", 0.15)

	if GameManager:
		GameManager.add_kill(score_value)

	# Death tween: squash, fade out, queue_free
	var tw: Tween = create_tween()
	tw.tween_property(sprite, "scale", Vector2(1.3, 0.2), 0.1)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.1)
	tw.tween_callback(queue_free)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is Player and not is_dead:
		body.take_damage(contact_damage, Vector2.LEFT)
