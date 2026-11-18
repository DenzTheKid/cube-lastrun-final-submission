extends Node2D
class_name Shotgun

# Double-barrel shotgun weapon system for CUBE: LAST RUN (AAA Indie Overhaul).
# Features:
# - Full, unrestricted 360-degree continuous directional aiming
# - Responsive zero-latency mouse cursor world tracking + gamepad/keyboard support
# - Vertical flip handling on WeaponVisuals container (no upside-down weapon)
# - Dynamic PointLight2D muzzle flash lighting spike
# - Spinning brass shell casing ejection & recoil kickback animation
# - Continuous 360-degree recoil-jump vector physics

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
@export var gamepad_deadzone: float = 0.18

var current_ammo: int = 2
var is_reloading: bool = false
var reload_timer: float = 0.0

var aim_direction: Vector2 = Vector2.RIGHT
var target_rotation: float = 0.0
var _using_gamepad_or_keys: bool = false
var _mouse_active: bool = true
var _muzzle_light: PointLight2D = null

@onready var weapon_visuals: Node2D = $WeaponVisuals
@onready var gun_sprite: Sprite2D = $WeaponVisuals/GunSprite
@onready var muzzle: Marker2D = $WeaponVisuals/Muzzle
@onready var muzzle_flash: Sprite2D = $WeaponVisuals/MuzzleFlash
@onready var ejection_port: Marker2D = $WeaponVisuals/EjectionPort
@onready var flash_timer: Timer = $FlashTimer

const PELLET_SCENE: PackedScene = preload("res://scenes/player/shotgun_pellet.tscn")
const RECOIL_DUST_SCENE: PackedScene = preload("res://scenes/effects/recoil_dust.tscn")
const LIGHT_TEXTURE: Texture2D = preload("res://assets/environment/point_light_radial.png")
const WEAPON_SKIN_TEXTURES: Dictionary = {
	"classic": preload("res://assets/weapons/shotgun.png"),
	"crimson": preload("res://assets/weapons/shotgun_crimson.png"),
	"toxic": preload("res://assets/weapons/shotgun_toxic.png"),
	"gold": preload("res://assets/weapons/shotgun_gold.png"),
	"plasma": preload("res://assets/weapons/shotgun_plasma.png")
}

var _tracer_color: Color = Color(1.0, 0.85, 0.42)

func _ready() -> void:
	current_ammo = max_ammo
	muzzle_flash.visible = false

	# Dynamic PointLight2D for instantaneous muzzle flash illumination
	_muzzle_light = PointLight2D.new()
	_muzzle_light.name = "MuzzleLight"
	_muzzle_light.texture = LIGHT_TEXTURE
	_muzzle_light.texture_scale = 2.2
	_muzzle_light.color = Color(1.0, 0.72, 0.28, 1.0)
	_muzzle_light.energy = 0.0
	_muzzle_light.enabled = false
	muzzle.add_child(_muzzle_light)

	if GameManager:
		if not GameManager.weapon_skin_changed.is_connected(apply_equipped_weapon_skin):
			GameManager.weapon_skin_changed.connect(apply_equipped_weapon_skin)
		apply_equipped_weapon_skin()

	flash_timer.timeout.connect(func():
		muzzle_flash.visible = false
		if _muzzle_light:
			_muzzle_light.enabled = false
			_muzzle_light.energy = 0.0
	)
	set_aim_direction(Vector2.RIGHT)
	ammo_changed.emit(current_ammo, max_ammo)

func apply_equipped_weapon_skin(_weapon_id: String = "") -> void:
	if not GameManager:
		return
	var data: Dictionary = GameManager.get_weapon_skin_data(_weapon_id)
	var skin_id: String = str(data.get("id", "classic"))
	if gun_sprite and WEAPON_SKIN_TEXTURES.has(skin_id):
		gun_sprite.texture = WEAPON_SKIN_TEXTURES[skin_id]
	_tracer_color = data.get("tracer", Color(1.0, 0.85, 0.42))
	if _muzzle_light:
		_muzzle_light.color = data.get("light", Color(1.0, 0.72, 0.28))

func _process(delta: float) -> void:
	_handle_aiming(delta)
	_handle_reloading(delta)
	if _muzzle_light and _muzzle_light.enabled:
		_muzzle_light.energy = maxf(0.0, _muzzle_light.energy - delta * 38.0)
		if flash_timer.time_left < 0.03:
			muzzle_flash.frame = 1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_mouse_active = true

func _handle_aiming(delta: float) -> void:
	# 1. Gamepad Right Stick Aiming (Audit all connected joypads, no hardcoded device 0 only)
	var gp_aim: Vector2 = Vector2.ZERO
	var joypads: Array[int] = Input.get_connected_joypads()
	for dev_id in joypads:
		var rx: float = Input.get_joy_axis(dev_id, JOY_AXIS_RIGHT_X)
		var ry: float = Input.get_joy_axis(dev_id, JOY_AXIS_RIGHT_Y)
		var stick := Vector2(rx, ry)
		if stick.length_squared() > gp_aim.length_squared():
			gp_aim = stick

	var has_gp_input: bool = false
	if gp_aim.length() > gamepad_deadzone:
		has_gp_input = true
		var mag: float = gp_aim.length()
		var scaled_mag: float = clampf((mag - gamepad_deadzone) / (1.0 - gamepad_deadzone), 0.0, 1.0)
		gp_aim = gp_aim.normalized() * scaled_mag

	# 2. Keyboard Aiming (Dedicated aim actions for 360-degree aiming, zero jump/fall conflicts)
	var kb_x: float = Input.get_axis("aim_left", "aim_right")
	var kb_y: float = Input.get_axis("aim_up", "aim_down")
	var kb_aim := Vector2(kb_x, kb_y)
	var has_kb_input: bool = kb_aim.length_squared() > 0.04

	# 3. Seamless Multi-Input Routing
	if has_gp_input:
		_mouse_active = false
		_using_gamepad_or_keys = true
		aim_direction = gp_aim.normalized()
		target_rotation = aim_direction.angle()
		rotation = lerp_angle(rotation, target_rotation, 1.0 - exp(-30.0 * delta))
	elif has_kb_input:
		_mouse_active = false
		_using_gamepad_or_keys = true
		aim_direction = kb_aim.normalized()
		target_rotation = aim_direction.angle()
		rotation = lerp_angle(rotation, target_rotation, 1.0 - exp(-25.0 * delta))
	elif _mouse_active:
		_using_gamepad_or_keys = false
		var mouse_world: Vector2 = get_global_mouse_position()
		var to_mouse: Vector2 = mouse_world - global_position
		if to_mouse.length_squared() > 1.0:
			aim_direction = to_mouse.normalized()
			target_rotation = aim_direction.angle()
			rotation = target_rotation
	else:
		# Retain active aim direction when analog stick / keys return to neutral
		rotation = lerp_angle(rotation, target_rotation, 1.0 - exp(-25.0 * delta))

	var is_aiming_left: bool = aim_direction.x < -0.01
	if is_aiming_left:
		weapon_visuals.scale.y = -1.0
	else:
		weapon_visuals.scale.y = 1.0

	aim_changed.emit(rotation, aim_direction)

func set_aim_direction(dir: Vector2) -> void:
	if dir.length_squared() > 0.001:
		_mouse_active = false
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

	# Break-action chamber tilt during reload
	if reload_timer < reload_time * 0.65:
		gun_sprite.rotation = deg_to_rad(14.0)
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

	# Multi-frame star muzzle flash + instantaneous PointLight2D spike
	muzzle_flash.visible = true
	muzzle_flash.frame = 0
	muzzle_flash.scale = Vector2(1.25, 1.25)
	var ftw: Tween = create_tween()
	ftw.tween_property(muzzle_flash, "scale", Vector2.ONE, 0.06)
	if _muzzle_light:
		_muzzle_light.enabled = true
		_muzzle_light.energy = 2.4
	flash_timer.start(0.06)

	# CONTINUOUS 360-DEGREE RECOIL CALCULATION
	var recoil_force: Vector2 = Vector2.ZERO

	if aim_direction.y > 0.15:
		recoil_force.y = -aim_direction.y * recoil_jump_strength
		if AudioManager:
			AudioManager.play_sfx("recoil")
			AudioManager.play_sfx("shotgun_acoustic", 0.04)
		var dust = RECOIL_DUST_SCENE.instantiate()
		dust.global_position = muzzle.global_position
		get_tree().current_scene.add_child(dust)
	else:
		recoil_force.y = -aim_direction.y * 50.0
		if AudioManager:
			AudioManager.play_sfx("shotgun")
			AudioManager.play_sfx("shotgun_acoustic", 0.04)

	# Horizontal recoil / vault calculation:
	# Diagonal-downward produces a noticeable forward vault impulse
	if aim_direction.y > 0.25:
		if absf(aim_direction.x) > 0.15:
			recoil_force.x = horizontal_vault_boost * absf(aim_direction.x)
		else:
			recoil_force.x = 0.0
	else:
		# Forward shot produces backward recoil deceleration; backward shot gives forward kick
		recoil_force.x = -aim_direction.x * standard_horizontal_kick

	recoil_impulse.emit(recoil_force)

	# Spawn high-velocity tracer buckshot pellets
	_spawn_pellets()

	# Eject spinning brass shell casing from breech
	if GameFeel and ejection_port:
		var eject_vec := Vector2(-aim_direction.x if absf(aim_direction.x) > 0.2 else -1.0, -1.0).normalized()
		GameFeel.spawn_shell_casing(ejection_port.global_position, eject_vec)

	# Crisp weapon recoil kickback snap
	var tw: Tween = create_tween()
	gun_sprite.position.x = -6.5
	gun_sprite.scale = Vector2(0.85, 1.18)
	tw.set_parallel(true)
	tw.tween_property(gun_sprite, "position:x", 0.0, 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(gun_sprite, "scale", Vector2.ONE, 0.11)

	if AudioManager:
		AudioManager.play_sfx("shell_eject", 0.1)

	if current_ammo == 0:
		start_reload()

	return true

func start_reload() -> void:
	if is_reloading or current_ammo == max_ammo:
		return
	is_reloading = true
	reload_timer = 0.0
	# Eject spent shells on break-action open
	if GameFeel and ejection_port:
		GameFeel.spawn_shell_casing(ejection_port.global_position, Vector2(-0.8, -1.0))
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
		pellet.setup(pellet_dir, spawn_pos, _tracer_color)
