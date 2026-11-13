extends Node2D
class_name Shotgun

# Double-barrel shotgun weapon system.
# Handles directional aiming, 2-shell ammunition, firing, muzzle flash,
# shell ejection, and recoil jump impulses.

signal ammo_changed(current_ammo: int, max_ammo: int)
signal reload_started(duration: float)
signal reload_finished
signal recoil_impulse(force: Vector2)

@export var max_ammo: int = 2
@export var reload_time: float = 0.85
@export var pellet_count: int = 6
@export var spread_angle_deg: float = 20.0
@export var recoil_jump_strength: float = 460.0 # Upward impulse when shooting downward
@export var horizontal_recoil_strength: float = 80.0

var current_ammo: int = 2
var is_reloading: bool = false
var reload_timer: float = 0.0

var aim_direction: Vector2 = Vector2.RIGHT

@onready var gun_sprite: Sprite2D = $GunSprite
@onready var muzzle: Marker2D = $Muzzle
@onready var muzzle_flash: Sprite2D = $MuzzleFlash
@onready var flash_timer: Timer = $FlashTimer

const PELLET_SCENE: PackedScene = preload("res://scenes/player/shotgun_pellet.tscn")

func _ready() -> void:
	current_ammo = max_ammo
	muzzle_flash.visible = false
	flash_timer.timeout.connect(func(): muzzle_flash.visible = false)
	ammo_changed.emit(current_ammo, max_ammo)

func _process(delta: float) -> void:
	_handle_aiming()
	_handle_reloading(delta)

func _handle_aiming() -> void:
	# Prioritize mouse aiming in world coordinates
	var mouse_pos: Vector2 = get_global_mouse_position()
	var raw_dir: Vector2 = (mouse_pos - global_position)
	
	# Keyboard aiming fallback if keyboard keys are held
	var kb_x: float = Input.get_axis("ui_left", "ui_right")
	var kb_y: float = Input.get_axis("ui_up", "ui_down")
	if absf(kb_x) > 0.1 or absf(kb_y) > 0.1:
		raw_dir = Vector2(kb_x, kb_y)

	if raw_dir.length_squared() > 0.01:
		aim_direction = raw_dir.normalized()
		rotation = aim_direction.angle()

	# Flip sprite vertically so gun is not upside down when aiming left
	if cos(rotation) < 0.0:
		gun_sprite.flip_v = true
		muzzle.position.y = -absf(muzzle.position.y)
	else:
		gun_sprite.flip_v = false
		muzzle.position.y = absf(muzzle.position.y)

func _handle_reloading(delta: float) -> void:
	if not is_reloading:
		return
	reload_timer += delta
	if reload_timer >= reload_time:
		is_reloading = false
		current_ammo = max_ammo
		reload_timer = 0.0
		ammo_changed.emit(current_ammo, max_ammo)
		reload_finished.emit()
		if AudioManager:
			AudioManager.play_sfx("reload")

func can_shoot() -> bool:
	return current_ammo > 0 and not is_reloading

func shoot() -> bool:
	if is_reloading:
		return false
	if current_ammo <= 0:
		if AudioManager:
			AudioManager.play_sfx("empty")
		start_reload()
		return false

	current_ammo -= 1
	ammo_changed.emit(current_ammo, max_ammo)

	# Sound & Muzzle flash
	muzzle_flash.visible = true
	flash_timer.start(0.06)

	# Recoil calculation: opposite to aim direction
	var recoil_vec: Vector2 = -aim_direction
	var is_downward_shot: bool = aim_direction.y > 0.35

	if is_downward_shot:
		# RECOIL JUMP: Major vertical boost!
		var vertical_boost: float = -recoil_jump_strength * clampf(aim_direction.y, 0.5, 1.0)
		var horiz_boost: float = recoil_vec.x * horizontal_recoil_strength * 0.5
		recoil_impulse.emit(Vector2(horiz_boost, vertical_boost))
		if AudioManager:
			AudioManager.play_sfx("recoil")
	else:
		# Standard firing kick
		var horiz_kick: float = recoil_vec.x * horizontal_recoil_strength
		recoil_impulse.emit(Vector2(horiz_kick, 0.0))
		if AudioManager:
			AudioManager.play_sfx("shotgun")

	# Spawn buckshot pellets
	_spawn_pellets()

	# Gun visual kick tween
	var tw: Tween = create_tween()
	gun_sprite.position.x = -4.0
	tw.tween_property(gun_sprite, "position:x", 0.0, 0.12)

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
