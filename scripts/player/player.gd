extends CharacterBody2D
class_name Player

# Cube Survivor player controller for CUBE: LAST RUN (AAA Indie Overhaul).
# Features:
# - Auto-running, coyote time, jump buffering, and variable jump height
# - Continuous 360-degree shotgun recoil vaulting
# - Procedural squash-and-stretch spring physics & forward speed lean
# - Multi-segment flowing tattered scarf / headband (Line2D physics trail)
# - Diegetic under-character reload progress bar
# - Hit-flash shader, hitstop, and glowing tactical visor PointLight2D

signal health_changed(current_hp: int, max_hp: int)
signal died

const HIT_FLASH_SHADER: Shader = preload("res://shaders/hit_flash.gdshader")
const LIGHT_TEXTURE: Texture2D = preload("res://assets/environment/point_light_radial.png")
const RECOIL_DUST_SCENE: PackedScene = preload("res://scenes/effects/recoil_dust.tscn")
const SPARK_SCENE: PackedScene = preload("res://scenes/effects/bullet_spark.tscn")

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
var _spawn_input_grace_frames: int = 6
var _wait_shoot_release: bool = false
var _wait_jump_release: bool = false
const COYOTE_TIME: float = 0.12
const JUMP_BUFFER_TIME: float = 0.12

# Footstep audio & particle timer
var _footstep_timer: float = 0.0

# Animation timing & aim pose
var _anim_timer: float = 0.0
var _anim_frame: int = 0
var _was_on_floor: bool = true
var current_aim_angle: float = 0.0
var current_aim_vector: Vector2 = Vector2.RIGHT

# Procedural Squash & Stretch + Forward Lean
var _visual_scale: Vector2 = Vector2.ONE
var _target_lean_rad: float = 0.0

# Flowing Tattered Scarf (Line2D Wind Physics Trail)
var _scarf_line: Line2D = null
var _scarf_points: Array[Vector2] = []
var _scarf_time: float = 0.0
const SCARF_SEGMENTS: int = 8
const SCARF_SEG_LEN: float = 2.4

# Shader Material & Visor Light
var _shader_mat: ShaderMaterial = null
var _visor_light: PointLight2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shotgun: Shotgun = $Shotgun
@onready var invuln_timer: Timer = $InvulnTimer

func _ready() -> void:
	velocity = Vector2.ZERO
	_wait_shoot_release = Input.is_action_pressed("shoot")
	_wait_jump_release = Input.is_action_pressed("jump")
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)

	_setup_visual_enhancements()

	if shotgun:
		shotgun.recoil_impulse.connect(_on_shotgun_recoil)
		shotgun.aim_changed.connect(_on_shotgun_aim_changed)
		shotgun.reload_started.connect(func(_d: float): queue_redraw())
		shotgun.reload_finished.connect(func():
			queue_redraw()
			if GameFeel:
				GameFeel.spawn_floating_text(global_position + Vector2(0, -14), "LOADED!", Color(0.4, 0.95, 1.0), 0.85)
		)
	invuln_timer.timeout.connect(func():
		is_invulnerable = false
		sprite.modulate = Color.WHITE
		if _shader_mat:
			_shader_mat.set_shader_parameter("flash_modifier", 0.0)
	)

func _setup_visual_enhancements() -> void:
	# 1. Hit-Flash + Rim Highlight Shader on Player Sprite
	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = HIT_FLASH_SHADER
	_shader_mat.set_shader_parameter("rim_strength", 0.35)
	_shader_mat.set_shader_parameter("rim_color", Color(0.45, 0.95, 1.0, 1.0))
	sprite.material = _shader_mat

	# 2. Flowing Crimson Headband / Scarf Trail (Line2D)
	_scarf_line = Line2D.new()
	_scarf_line.name = "ScarfTrail"
	_scarf_line.z_index = -1
	_scarf_line.width = 3.0
	var width_curve := Curve.new()
	width_curve.add_point(Vector2(0.0, 1.0))
	width_curve.add_point(Vector2(0.6, 0.85))
	width_curve.add_point(Vector2(1.0, 0.25))
	_scarf_line.width_curve = width_curve

	var grad := Gradient.new()
	grad.set_color(0, Color(0.92, 0.18, 0.25, 1.0))
	grad.set_color(1, Color(1.0, 0.42, 0.32, 0.85))
	_scarf_line.gradient = grad
	add_child(_scarf_line)

	_scarf_points.clear()
	for i in range(SCARF_SEGMENTS):
		_scarf_points.append(Vector2(-float(i) * SCARF_SEG_LEN, -3.0))

	# 3. Subtle Cyan Tactical Visor Glow (PointLight2D)
	_visor_light = PointLight2D.new()
	_visor_light.name = "VisorLight"
	_visor_light.texture = LIGHT_TEXTURE
	_visor_light.texture_scale = 0.85
	_visor_light.color = Color(0.25, 0.92, 1.0, 1.0)
	_visor_light.energy = 0.45
	_visor_light.position = Vector2(4.0, -2.0)
	add_child(_visor_light)

func _physics_process(delta: float) -> void:
	if is_dead or is_transforming:
		if not is_on_floor():
			velocity.y += gravity * delta
			move_and_slide()
		if _scarf_line:
			_scarf_line.visible = false
		queue_redraw()
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
		# Apex hang-time subtle horizontal poise
		if absf(velocity.y) < 42.0:
			_visual_scale = _visual_scale.lerp(Vector2(1.08, 0.92), 1.0 - exp(-12.0 * delta))
	else:
		coyote_timer = COYOTE_TIME
		if not _was_on_floor:
			# Landed impact squash + dust burst!
			_visual_scale = Vector2(1.34, 0.68)
			_spawn_footstep_dust(1.1)
			if AudioManager:
				AudioManager.play_sfx("land", 0.1)

		# Footsteps on pavement
		_footstep_timer += delta
		var step_interval: float = 0.28 / speed_mult
		if _footstep_timer >= step_interval:
			_footstep_timer = 0.0
			_visual_scale = Vector2(1.07, 0.93)
			_spawn_footstep_dust(0.55)
			if AudioManager:
				AudioManager.play_sfx("land", 0.2)

	_was_on_floor = is_on_floor()

	if _wait_shoot_release and not Input.is_action_pressed("shoot"):
		_wait_shoot_release = false
	if _wait_jump_release and not Input.is_action_pressed("jump"):
		_wait_jump_release = false

	if _spawn_input_grace_frames > 0:
		_spawn_input_grace_frames -= 1
		jump_buffer_timer = 0.0
		if Input.is_action_pressed("shoot"):
			_wait_shoot_release = true
		if Input.is_action_pressed("jump"):
			_wait_jump_release = true
	else:
		# Jump buffering
		if not _wait_jump_release and Input.is_action_just_pressed("jump"):
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
		if not _wait_shoot_release and Input.is_action_just_pressed("shoot"):
			shotgun.shoot()

		# Manual reload input
		if Input.is_action_just_pressed("reload"):
			shotgun.start_reload()

	move_and_slide()
	_update_animation(delta)
	_update_juice_visuals(delta, speed_mult)
	if shotgun and shotgun.is_reloading:
		queue_redraw()

func _perform_jump() -> void:
	velocity.y = jump_velocity
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	# Jump launch vertical stretch + shockwave air-ring
	_visual_scale = Vector2(0.74, 1.30)
	if GameFeel:
		GameFeel.spawn_shockwave_ring(global_position + Vector2(0.0, 11.0), Color(0.45, 0.95, 1.0, 0.85))
	if AudioManager:
		AudioManager.play_sfx("jump")

func _spawn_footstep_dust(scale_factor: float = 0.6) -> void:
	var root: Node = get_tree().current_scene
	if not root or root.name == "TestRunner":
		return
	var dust := RECOIL_DUST_SCENE.instantiate() as CPUParticles2D
	if dust:
		dust.global_position = global_position + Vector2(-4.0, 11.0)
		dust.scale_amount_min = 0.25 * scale_factor
		dust.scale_amount_max = 0.55 * scale_factor
		root.add_child(dust)

func _on_shotgun_aim_changed(aim_angle: float, aim_vec: Vector2) -> void:
	current_aim_angle = aim_angle
	current_aim_vector = aim_vec

func _on_shotgun_recoil(force: Vector2) -> void:
	# Downward shot -> Upward boost
	if force.y < 0.0:
		if velocity.y > 0.0:
			velocity.y = 0.0
		velocity.y += force.y
		velocity.y = maxf(velocity.y, max_upward_velocity)
		coyote_timer = COYOTE_TIME * 0.5
		# Dramatic vertical stretch + fiery orange shockwave ring on recoil jump!
		_visual_scale = Vector2(0.70, 1.36)
		if GameFeel:
			GameFeel.spawn_shockwave_ring(global_position + Vector2(0.0, 11.0), Color(1.0, 0.62, 0.2, 0.9))
	elif force.y > 0.0:
		velocity.y += force.y
		_visual_scale = Vector2(1.18, 0.84)
	else:
		_visual_scale = Vector2(0.88, 1.12)

	# Apply horizontal impulse
	velocity.x += force.x

func _update_animation(delta: float) -> void:
	_anim_timer += delta

	if not is_on_floor():
		if velocity.y < 0.0:
			sprite.frame = 13
		else:
			sprite.frame = 19
	else:
		var run_frame_duration: float = 0.10 / (GameManager.difficulty_factor if GameManager else 1.0)
		if _anim_timer >= run_frame_duration:
			_anim_timer = 0.0
			_anim_frame = (_anim_frame + 1) % 6
			sprite.frame = 6 + _anim_frame

func _update_juice_visuals(delta: float, speed_mult: float) -> void:
	# 1. Smoothly recover squash & stretch toward Vector2.ONE
	_visual_scale = _visual_scale.lerp(Vector2.ONE, 1.0 - exp(-18.0 * delta))
	sprite.scale = _visual_scale

	# 2. Forward Lean proportional to running speed & vertical velocity
	if is_on_floor():
		_target_lean_rad = deg_to_rad(clampf(8.0 * speed_mult, 7.5, 12.5))
	else:
		_target_lean_rad = deg_to_rad(clampf(velocity.y * 0.025, -10.0, 14.0))
	sprite.rotation = lerpf(sprite.rotation, _target_lean_rad, 1.0 - exp(-15.0 * delta))

	# 3. Invulnerability shimmer blink
	if is_invulnerable:
		var blink: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.045)
		sprite.modulate = Color(1.0, 0.45 + 0.55 * blink, 0.45 + 0.55 * blink, 0.75 + 0.25 * blink)

	# 4. Update Flowing Scarf Line2D Physics Trail
	if _scarf_line and _scarf_points.size() == SCARF_SEGMENTS:
		_scarf_time += delta * (14.0 * speed_mult)
		var anchor := Vector2(-5.0, -3.0 + (sprite.scale.y - 1.0) * -4.0)
		_scarf_points[0] = anchor
		for i in range(1, SCARF_SEGMENTS):
			var prev: Vector2 = _scarf_points[i - 1]
			var wave_y: float = sin(_scarf_time - float(i) * 0.85) * (1.2 + float(i) * 0.25)
			var air_drag_y: float = clampf(-velocity.y * 0.008, -2.5, 2.5)
			var target_pt := prev + Vector2(-SCARF_SEG_LEN, wave_y * 0.35 + air_drag_y * 0.3)
			_scarf_points[i] = _scarf_points[i].lerp(target_pt, 1.0 - exp(-24.0 * delta))
		_scarf_line.points = PackedVector2Array(_scarf_points)

func _draw() -> void:
	# Diegetic Reload Progress Bar directly under the Cube Survivor
	if shotgun and shotgun.is_reloading and not is_dead and not is_transforming:
		var pct: float = clampf(shotgun.reload_timer / maxf(shotgun.reload_time, 0.01), 0.0, 1.0)
		var bar_w: float = 20.0
		var bar_h: float = 3.0
		var bx: float = -bar_w * 0.5
		var by: float = 15.0
		draw_rect(Rect2(bx - 1.0, by - 1.0, bar_w + 2.0, bar_h + 2.0), Color(0.06, 0.06, 0.1, 0.9), true)
		var fill_col: Color = Color(1.0, 0.55, 0.2, 1.0).lerp(Color(0.3, 0.95, 1.0, 1.0), pct)
		draw_rect(Rect2(bx, by, bar_w * pct, bar_h), fill_col, true)

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_dead or is_transforming or is_invulnerable:
		return

	current_hp -= amount
	health_changed.emit(current_hp, max_hp)

	if GameManager:
		GameManager.reset_combo()

	if AudioManager:
		AudioManager.play_sfx("player_hurt")

	# Tactile Hitstop + White Hit-Flash Shader + Knockback Sparks
	if GameFeel:
		GameFeel.hitstop(0.05, 0.05)
		GameFeel.camera_shake(0.75)
		GameFeel.spawn_floating_text(global_position + Vector2(0, -14), "-1 HP!", Color(1.0, 0.25, 0.25), 1.15)

	var root: Node = get_tree().current_scene
	if root and SPARK_SCENE:
		var sp := SPARK_SCENE.instantiate() as Node2D
		if sp:
			sp.global_position = global_position
			root.add_child(sp)

	if _shader_mat:
		_shader_mat.set_shader_parameter("flash_modifier", 1.0)
		var tw: Tween = create_tween()
		tw.tween_method(func(v: float): _shader_mat.set_shader_parameter("flash_modifier", v), 1.0, 0.0, 0.16)

	_visual_scale = Vector2(1.35, 0.68)

	if current_hp <= 0:
		die()
	else:
		is_invulnerable = true
		invuln_timer.start(0.85)
		sprite.modulate = Color(1.0, 0.35, 0.35, 0.85)
		if knockback_dir != Vector2.ZERO:
			velocity += knockback_dir.normalized() * 140.0

func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	shotgun.visible = false
	if _scarf_line:
		_scarf_line.visible = false
	queue_redraw()
	sprite.rotation = 0.0
	sprite.scale = Vector2.ONE
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
	if _scarf_line:
		_scarf_line.visible = false
	queue_redraw()
	sprite.rotation = 0.0
	sprite.scale = Vector2.ONE

	sprite.frame = 42
	var tw: Tween = create_tween()
	tw.tween_property(sprite, "frame", 45, 0.9)
	tw.tween_callback(func():
		is_dead = true
		if GameManager:
			GameManager.trigger_game_over()
	)
	died.emit()
