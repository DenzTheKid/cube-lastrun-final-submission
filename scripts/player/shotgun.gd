extends Node2D
class_name Shotgun

# Double-barrel shotgun weapon system for CUBE: LAST RUN V1.2.
# Features:
# - Full, unrestricted 360-degree continuous directional aiming.
# - Responsive zero-latency mouse cursor world tracking.
# - Gamepad analog stick and keyboard continuous steering.
# - Vertical flip handling on WeaponVisuals container (no upside-down weapon).
# - Pixel-accurate grip pivot and muzzle projectile alignment.
# - Continuous recoil-jump vector physics across all angles.
# - Atomic reload state machine with dry-fire click feedback.

signal ammo_changed(current_ammo: int, max_ammo: int)
signal reload_started(duration: float)
signal reload_finished
signal recoil_impulse(force: Vector2)
signal aim_changed(aim_angle: float, aim_vector: Vector2)

@export var max_ammo: int = 2
@export var reload_time: float = 0.80
@export var pellet_count: int = 6
@export var spread_angle_deg: float = 16.0
@export var recoil_jump_strength: float = 480.0
@export var horizontal_vault_boost: float = 140.0
@export var standard_horizontal_kick: float = 75.0

var current_ammo: int = 2
var is_reloading: bool = false
var reload_timer: float = 0.0

var aim_direction: Vector2 = Vector2.RIGHT
var target_rotation: float = 0.0
var _using_gamepad_or_keys: bool = false

@onready var weapon_visuals: Node2D = $WeaponVisuals
@onready var gun_sprite: Sprite2D = $WeaponVisuals/GunSprite
@onready var muzzle: Marker2D = $WeaponVisuals/Muzzle
@onready var muzzle_flash: Sprite2D = $WeaponVisuals/MuzzleFlash
@onready var ejection_port: Marker2D = $WeaponVisuals/EjectionPort
@onready var flash_timer: Timer = $FlashTimer

const PELLET_SCENE: PackedScene = preload("res://scenes/player/shotgun_pellet.tscn")
const RECOIL_DUST_SCENE: PackedScene = preload("res://scenes/effects/recoil_dust.tscn")


func _ready() -> void:
	current_ammo = max_ammo
	muzzle_flash.visible = false
	flash_timer.timeout.connect(func(): muzzle_flash.visible = false)
	set_aim_direction(Vector2.RIGHT)
	ammo_changed.emit(current_ammo, max_ammo)

func _process(delta: float) -> void:
	_handle_aiming(delta)
	_handle_reloading(delta)

func _handle_aiming(delta: float) -> void:
	# 1. Check Gamepad right stick analog input
	var gp_aim: Vector2 = Vector2.ZERO
	gp_aim.x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	gp_aim.y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)

	# 2. Check Keyboard directional keys
	var kb_x: float = Input.get_axis("ui_left", "ui_right")
	var kb_y: float = Input.get_axis("ui_up", "ui_down")
	var kb_vec: Vector2 = Vector2(kb_x, kb_y)

	if gp_aim.length_squared() > 0.06:
		_using_gamepad_or_keys = true
		aim_direction = gp_aim.normalized()
		target_rotation = aim_direction.angle()
		rotation = lerp_angle(rotation, target_rotation, 1.0 - exp(-30.0 * delta))
	elif kb_vec.length_squared() > 0.06:
		_using_gamepad_or_keys = true
		aim_direction = kb_vec.normalized()
		target_rotation = aim_direction.angle()
		rotation = lerp_angle(rotation, target_rotation, 1.0 - exp(-25.0 * delta))
	else:
		_using_gamepad_or_keys = false
		# 3. Direct mouse cursor world tracking (zero input lag, crisp 1:1 precision)
		var mouse_world: Vector2 = get_global_mouse_position()
		var to_mouse: Vector2 = mouse_world - global_position
		if to_mouse.length_squared() > 1.0:
			aim_direction = to_mouse.normalized()
			target_rotation = aim_direction.angle()
			rotation = target_rotation

	# 4. Clean vertical flipping on WeaponVisuals when aiming backward/left
	var is_aiming_left: bool = aim_direction.x < -0.01
	if is_aiming_left:
		weapon_visuals.scale.y = -1.0
	else:
		weapon_visuals.scale.y = 1.0

	aim_changed.emit(rotation, aim_direction)

func set_aim_direction(dir: Vector2) -> void:
	if dir.length_squared() > 0.001:
		aim_direction = dir.normalized()
		target_rotation = aim_direction.angle()
		rotation = target_rotation
		var is_aiming_left: bool = aim_direction.x < -0.01
		if weapon_visuals:
			weapon_visuals.scale.y = -1.0 if is_aiming_left else 1.0
		aim_changed.emit(rotation, aim_direction)

func _handle_reloading(delta: float) -> void:
	if not is_reloading:
		return
	reload_timer += delta

	# Subtle break-action chamber tilt during reload
	if reload_timer < reload_time * 0.65:
		gun_sprite.rotation = deg_to_rad(12.0)
	else:
		gun_sprite.rotation = 0.0

	if reload_timer >= reload_time:
		is_reloading = false
		current_ammo = max_ammo
		reload_timer = 0.0
		gun_sprite.rotation = 0.0
		ammo_changed.emit(current_ammo, max_ammo)
		reload_finished.emit()
		if AudioManager:
			AudioManager.play_sfx("reload")

func can_shoot() -> bool:
	return current_ammo > 0 and not is_reloading

func shoot() -> bool:
	if is_reloading:
		if AudioManager:
			AudioManager.play_sfx("empty", 0.05)
		return false

	if current_ammo <= 0:
		if AudioManager:
			AudioManager.play_sfx("empty", 0.05)
		start_reload()
		return false

	current_ammo -= 1
	ammo_changed.emit(current_ammo, max_ammo)

	# Sound & Muzzle flash
	muzzle_flash.visible = true
	flash_timer.start(0.06)

	# CONTINUOUS 360-DEGREE RECOIL CALCULATION
	var recoil_force: Vector2 = Vector2.ZERO

	# 1. Vertical recoil: downward shooting (aim_direction.y > 0) launches player UPWARD
	if aim_direction.y > 0.15:
		# Continuous upward impulse proportional to downward angle component
		recoil_force.y = -aim_direction.y * recoil_jump_strength
		if AudioManager:
			AudioManager.play_sfx("recoil")
			AudioManager.play_sfx("shotgun_acoustic", 0.04)
		# Spawn recoil dust puff at muzzle
		var dust = RECOIL_DUST_SCENE.instantiate()
		dust.global_position = muzzle.global_position
		get_tree().current_scene.add_child(dust)
	else:
		recoil_force.y = -aim_direction.y * 50.0
		if AudioManager:
			AudioManager.play_sfx("shotgun")
			AudioManager.play_sfx("shotgun_acoustic", 0.04)

	# 2. Horizontal recoil:
	# If shooting diagonally downward and forward, provide forward vault momentum
	if aim_direction.y > 0.25 and aim_direction.x > 0.15:
		recoil_force.x = horizontal_vault_boost * aim_direction.x
	else:
		# Standard reactive kick opposite to firing direction
		recoil_force.x = -aim_direction.x * standard_horizontal_kick

	recoil_impulse.emit(recoil_force)

	# Spawn buckshot pellets along continuous aim direction
	_spawn_pellets()

	# Visual kick tween
	var tw: Tween = create_tween()
	gun_sprite.position.x = -5.0
	tw.tween_property(gun_sprite, "position:x", 0.0, 0.10)

	# Eject shell casing sound
	if AudioManager:
		AudioManager.play_sfx("shell_eject", 0.1)

	# Auto-reload if empty
	if current_ammo == 0:
		start_reload()

	return true

func start_reload() -> void:
	if is_reloading or current_ammo == max_ammo:
		return
	is_reloading = true
	reload_timer = 0.0
	reload_started.emit(reload_time)

func _spawn_pellets() -> void:
	var root: Node = get_tree().current_scene
	var spawn_pos: Vector2 = muzzle.global_position
	var base_angle: float = aim_direction.angle()
	var half_spread: float = deg_to_rad(spread_angle_deg * 0.5)

	for i in range(pellet_count):
		var pellet: ShotgunPellet = PELLET_SCENE.instantiate() as ShotgunPellet
		var spread_offset: float = randf_range(-half_spread, half_spread)
		var pellet_dir: Vector2 = Vector2.from_angle(base_angle + spread_offset)
		root.add_child(pellet)
		pellet.setup(pellet_dir, spawn_pos)
