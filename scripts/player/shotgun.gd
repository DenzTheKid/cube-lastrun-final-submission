extends Node2D
class_name Shotgun

# Double-barrel shotgun weapon system for CUBE: LAST RUN V1.1.
# Implements discrete 5-directional aiming, 2-shell break-action chambering,
# clean non-conflicting reload state, muzzle flash, shell ejection,
# and physics-tuned recoil jump impulses.

signal ammo_changed(current_ammo: int, max_ammo: int)
signal reload_started(duration: float)
signal reload_finished
signal recoil_impulse(force: Vector2)
signal aim_changed(aim_dir_enum: int, aim_vector: Vector2)

enum AimDir {
	FORWARD,           # 0: Horizontal forward (+X)
	DIAGONAL_UPWARD,   # 1: 45° Up-Right
	STRAIGHT_UPWARD,   # 2: 90° Up (-Y)
	DIAGONAL_DOWNWARD, # 3: 45° Down-Right
	STRAIGHT_DOWNWARD  # 4: 90° Down (+Y)
}

@export var max_ammo: int = 2
@export var reload_time: float = 0.80
@export var pellet_count: int = 6
@export var spread_angle_deg: float = 18.0
@export var recoil_jump_strength: float = 480.0
@export var horizontal_vault_boost: float = 140.0

var current_ammo: int = 2
var is_reloading: bool = false
var reload_timer: float = 0.0

var current_aim_enum: AimDir = AimDir.FORWARD
var aim_direction: Vector2 = Vector2.RIGHT

@onready var gun_sprite: Sprite2D = $GunSprite
@onready var muzzle: Marker2D = $Muzzle
@onready var muzzle_flash: Sprite2D = $MuzzleFlash
@onready var flash_timer: Timer = $FlashTimer

const PELLET_SCENE: PackedScene = preload("res://scenes/player/shotgun_pellet.tscn")

# Canonical discrete aiming vectors
const AIM_VECTORS: Dictionary = {
	AimDir.FORWARD: Vector2(1.0, 0.0),
	AimDir.DIAGONAL_UPWARD: Vector2(0.707107, -0.707107),
	AimDir.STRAIGHT_UPWARD: Vector2(0.0, -1.0),
	AimDir.DIAGONAL_DOWNWARD: Vector2(0.707107, 0.707107),
	AimDir.STRAIGHT_DOWNWARD: Vector2(0.0, 1.0),
}

func _ready() -> void:
	current_ammo = max_ammo
	muzzle_flash.visible = false
	flash_timer.timeout.connect(func(): muzzle_flash.visible = false)
	_apply_aim(AimDir.FORWARD)
	ammo_changed.emit(current_ammo, max_ammo)

func _process(delta: float) -> void:
	_handle_aiming()
	_handle_reloading(delta)

func _handle_aiming() -> void:
	var new_aim: AimDir = current_aim_enum

	# 1. Check keyboard / gamepad discrete inputs first
	var up: bool = Input.is_action_pressed("ui_up")
	var down: bool = Input.is_action_pressed("ui_down")
	var right: bool = Input.is_action_pressed("ui_right")
	var left: bool = Input.is_action_pressed("ui_left")

	if up and right:
		new_aim = AimDir.DIAGONAL_UPWARD
	elif down and right:
		new_aim = AimDir.DIAGONAL_DOWNWARD
	elif up and not down and not left:
		new_aim = AimDir.STRAIGHT_UPWARD
	elif down and not up and not left:
		new_aim = AimDir.STRAIGHT_DOWNWARD
	elif right and not up and not down:
		new_aim = AimDir.FORWARD
	else:
		# 2. Mouse cursor directional quantization
		var mouse_pos: Vector2 = get_global_mouse_position()
		var rel: Vector2 = mouse_pos - global_position
		if rel.length_squared() > 16.0:
			var angle_deg: float = rad_to_deg(rel.angle())
			if angle_deg >= -22.5 and angle_deg < 22.5:
				new_aim = AimDir.FORWARD
			elif angle_deg >= -67.5 and angle_deg < -22.5:
				new_aim = AimDir.DIAGONAL_UPWARD
			elif angle_deg >= -112.5 and angle_deg < -67.5:
				new_aim = AimDir.STRAIGHT_UPWARD
			elif angle_deg >= 22.5 and angle_deg < 67.5:
				new_aim = AimDir.DIAGONAL_DOWNWARD
			elif angle_deg >= 67.5 and angle_deg < 112.5:
				new_aim = AimDir.STRAIGHT_DOWNWARD
			else:
				# Mouse is behind player -> snap to nearest vertical or forward
				if rel.y < -20.0:
					new_aim = AimDir.STRAIGHT_UPWARD
				elif rel.y > 20.0:
					new_aim = AimDir.STRAIGHT_DOWNWARD
				else:
					new_aim = AimDir.FORWARD

	if new_aim != current_aim_enum:
		_apply_aim(new_aim)

func _apply_aim(aim: AimDir) -> void:
	current_aim_enum = aim
	aim_direction = AIM_VECTORS[aim]
	rotation = aim_direction.angle()
	gun_sprite.flip_v = false
	muzzle.position.y = 0.0
	aim_changed.emit(int(current_aim_enum), aim_direction)

func _handle_reloading(delta: float) -> void:
	if not is_reloading:
		return
	reload_timer += delta

	# Subtle break-action gun tilt during reload
	if reload_timer < reload_time * 0.7:
		gun_sprite.rotation = deg_to_rad(15.0)
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
		# Player attempted to fire during reload - play click feedback
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

	# Recoil calculation based on discrete aim direction
	match current_aim_enum:
		AimDir.STRAIGHT_DOWNWARD:
			# Pure vertical high jump
			recoil_impulse.emit(Vector2(0.0, -recoil_jump_strength))
			if AudioManager:
				AudioManager.play_sfx("recoil")
		AimDir.DIAGONAL_DOWNWARD:
			# Vault boost: High jump + forward velocity boost!
			recoil_impulse.emit(Vector2(horizontal_vault_boost, -recoil_jump_strength * 0.78))
			if AudioManager:
				AudioManager.play_sfx("recoil")
		AimDir.STRAIGHT_UPWARD:
			# Downward kick into ground (stabilizing)
			recoil_impulse.emit(Vector2(0.0, 60.0))
			if AudioManager:
				AudioManager.play_sfx("shotgun")
		AimDir.DIAGONAL_UPWARD:
			# Slight backward & downward kick
			recoil_impulse.emit(Vector2(-50.0, 40.0))
			if AudioManager:
				AudioManager.play_sfx("shotgun")
		AimDir.FORWARD:
			# Horizontal kick
			recoil_impulse.emit(Vector2(-70.0, 0.0))
			if AudioManager:
				AudioManager.play_sfx("shotgun")

	# Spawn buckshot pellets
	_spawn_pellets()

	# Visual kick tween
	var tw: Tween = create_tween()
	gun_sprite.position.x = -5.0
	tw.tween_property(gun_sprite, "position:x", 0.0, 0.10)

	# Shell casing sound
	if AudioManager:
		AudioManager.play_sfx("shell_eject", 0.1)

	# Auto-reload if both shells expended
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
