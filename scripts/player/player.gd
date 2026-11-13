extends CharacterBody2D
class_name Player

# Cube Survivor player controller for CUBE: LAST RUN V1.1.
# Implements auto-running, responsive jumping, coyote time & jump buffering,
# directional aim visualization, capped recoil jump integration,
# hazard damage invulnerability, footstep audio, and stylized death sequences.

signal health_changed(current_hp: int, max_hp: int)
signal died

@export var base_run_speed: float = 175.0
@export var jump_velocity: float = -380.0
@export var gravity: float = 980.0
@export var max_fall_speed: float = 650.0
@export var max_upward_velocity: float = -540.0

@export var max_hp: int = 2
var current_hp: int = 2

var is_dead: bool = false
var is_transforming: bool = false
var is_invulnerable: bool = false

# Jump helpers
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
const COYOTE_TIME: float = 0.12
const JUMP_BUFFER_TIME: float = 0.12

# Footstep audio timer
var _footstep_timer: float = 0.0

# Animation timing & aim pose
var _anim_timer: float = 0.0
var _anim_frame: int = 0
var _was_on_floor: bool = true
var _current_aim_enum: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shotgun: Shotgun = $Shotgun
@onready var invuln_timer: Timer = $InvulnTimer

func _ready() -> void:
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)
	if shotgun:
		shotgun.recoil_impulse.connect(_on_shotgun_recoil)
		shotgun.aim_changed.connect(_on_shotgun_aim_changed)
	invuln_timer.timeout.connect(func(): is_invulnerable = false; sprite.modulate = Color.WHITE)

func _physics_process(delta: float) -> void:
	if is_dead or is_transforming:
		if not is_on_floor():
			velocity.y += gravity * delta
			move_and_slide()
		return

	# Auto-running speed scaled smoothly by difficulty
	var speed_mult: float = GameManager.difficulty_factor if GameManager else 1.0
	velocity.x = base_run_speed * speed_mult

	# Distance tracking
	if GameManager:
		GameManager.add_distance(velocity.x * delta * 0.05)

	# Gravity & Ground Contact
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
		coyote_timer -= delta
	else:
		coyote_timer = COYOTE_TIME
		if not _was_on_floor:
			# Landed!
			if AudioManager:
				AudioManager.play_sfx("land", 0.1)

		# Footsteps on pavement
		_footstep_timer += delta
		var step_interval: float = 0.28 / speed_mult
		if _footstep_timer >= step_interval:
			_footstep_timer = 0.0
			# Play subtle land/tap as footstep
			if AudioManager:
				AudioManager.play_sfx("land", 0.2)

	_was_on_floor = is_on_floor()

	# Jump buffering
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

	# Execute Jump
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		_perform_jump()

	# Variable jump height (releasing jump cuts upward velocity)
	if Input.is_action_just_released("jump") and velocity.y < (jump_velocity * 0.45):
		velocity.y = jump_velocity * 0.45

	# Shooting input
	if Input.is_action_just_pressed("shoot"):
		shotgun.shoot()

	# Manual reload input
	if Input.is_action_just_pressed("reload"):
		shotgun.start_reload()

	move_and_slide()
	_update_animation(delta)

func _perform_jump() -> void:
	velocity.y = jump_velocity
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	if AudioManager:
		AudioManager.play_sfx("jump")

func _on_shotgun_aim_changed(aim_enum: int, _vec: Vector2) -> void:
	_current_aim_enum = aim_enum

func _on_shotgun_recoil(force: Vector2) -> void:
	# Downward shot -> Upward boost
	if force.y < 0.0:
		# If falling downward, cancel fall momentum so boost is crisp and immediate
		if velocity.y > 0.0:
			velocity.y = 0.0
		velocity.y += force.y
		# Clamp to prevent launch beyond screen top
		velocity.y = maxf(velocity.y, max_upward_velocity)
		# Provide tactical half-coyote window
		coyote_timer = COYOTE_TIME * 0.5
	elif force.y > 0.0:
		velocity.y += force.y

	# Apply horizontal impulse
	velocity.x += force.x

func _update_animation(delta: float) -> void:
	_anim_timer += delta

	if not is_on_floor():
		if velocity.y < 0.0:
			# Jumping (Row 2, frame 12-13)
			sprite.frame = 13
		else:
			# Falling (Row 3, frame 18-19)
			sprite.frame = 19
	else:
		# Running (Row 1: frames 6 to 11)
		var run_frame_duration: float = 0.10 / (GameManager.difficulty_factor if GameManager else 1.0)
		if _anim_timer >= run_frame_duration:
			_anim_timer = 0.0
			_anim_frame = (_anim_frame + 1) % 6
			sprite.frame = 6 + _anim_frame

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_dead or is_transforming or is_invulnerable:
		return

	current_hp -= amount
	health_changed.emit(current_hp, max_hp)

	if AudioManager:
		AudioManager.play_sfx("player_hurt")

	if current_hp <= 0:
		die()
	else:
		# Invulnerability flash & knockback
		is_invulnerable = true
		invuln_timer.start(0.85)
		sprite.modulate = Color(1.0, 0.35, 0.35, 0.75)
		if knockback_dir != Vector2.ZERO:
			velocity += knockback_dir.normalized() * 140.0

func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	shotgun.visible = false
	# Death collapse animation (Row 6)
	sprite.frame = 36
	var tw: Tween = create_tween()
	tw.tween_property(sprite, "frame", 39, 0.5)
	tw.tween_callback(func():
		if GameManager:
			GameManager.trigger_game_over()
	)
	died.emit()

func trigger_horde_catch() -> void:
	if is_dead or is_transforming:
		return
	is_transforming = true
	velocity = Vector2.ZERO
	shotgun.visible = false

	# Stylized zombie transformation sequence (Row 7: frames 42-45)
	sprite.frame = 42
	var tw: Tween = create_tween()
	tw.tween_property(sprite, "frame", 45, 0.9)
	tw.tween_callback(func():
		is_dead = true
		if GameManager:
			GameManager.trigger_game_over()
	)
	died.emit()
