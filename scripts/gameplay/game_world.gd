extends Node2D
class_name GameWorld

# Core gameplay world for CUBE: LAST RUN (AAA Indie Overhaul).
# Coordinates the player, intelligent action camera (speed look-ahead, dynamic zoom,
# trauma-based Perlin/sinusoidal shake), multi-layer ParallaxManager, WorldEnvironment,
# rear horde pursuer, modular procedural level generator, and UI overlays.

@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var horde: RearHorde = $RearHorde
@onready var level_gen: LevelGenerator = $LevelGenerator
@onready var hud: HUD = $HUD
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var game_over_menu: GameOverMenu = $GameOverMenu

# Camera framing & speed-based look-ahead
const CAMERA_OFFSET_X: float = 100.0
const CAMERA_MAX_LOOKAHEAD_X: float = 126.0
const CAMERA_BASE_Y: float = 135.0

var _current_lookahead_x: float = 100.0
var _target_zoom: float = 1.0

# Trauma-based screen shake
var _trauma: float = 0.0
var _shake_time: float = 0.0
const TRAUMA_DECAY: float = 2.4
const MAX_SHAKE_OFFSET: float = 7.5

const PARALLAX_MANAGER_SCRIPT = preload("res://scripts/gameplay/parallax_manager.gd")

var _parallax_mgr: Node2D = null

func _ready() -> void:
	# Set custom pixel crosshair reticle for 360° mouse aiming
	var crosshair_tex = load("res://assets/ui/crosshair_reticle.png")
	if crosshair_tex:
		Input.set_custom_mouse_cursor(crosshair_tex, Input.CURSOR_ARROW, Vector2(16, 16))

	# Initialize multi-layer atmospheric ParallaxManager & WorldEnvironment
	_parallax_mgr = PARALLAX_MANAGER_SCRIPT.new()
	_parallax_mgr.name = "ParallaxManager"
	add_child(_parallax_mgr)
	_parallax_mgr.setup_environment(self, camera)

	if GameManager:
		GameManager.start_game()

	if hud and player:
		hud.setup_player(player)

	if horde and player:
		horde.set_player(player)

	if level_gen and player:
		level_gen.setup(player)

	if player:
		if player.shotgun:
			player.shotgun.recoil_impulse.connect(_on_shotgun_recoil)
		player.health_changed.connect(_on_player_health_changed)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	# Speed-based camera look-ahead & subtle dynamic zoom
	var diff: float = GameManager.difficulty_factor if GameManager else 1.0
	var speed_ratio: float = clampf((diff - 1.0) / 1.5, 0.0, 1.0)
	var desired_lookahead: float = lerpf(CAMERA_OFFSET_X, CAMERA_MAX_LOOKAHEAD_X, speed_ratio)
	if not player.is_on_floor() and player.velocity.y < -180.0:
		desired_lookahead += 10.0
		_target_zoom = 0.96
	else:
		_target_zoom = lerpf(1.0, 0.95, speed_ratio * 0.6)

	_current_lookahead_x = lerpf(_current_lookahead_x, desired_lookahead, 1.0 - exp(-6.0 * delta))
	camera.global_position.x = player.global_position.x + _current_lookahead_x
	camera.global_position.y = CAMERA_BASE_Y

	var z: float = lerpf(camera.zoom.x, _target_zoom, 1.0 - exp(-5.0 * delta))
	camera.zoom = Vector2(z, z)

	# Apply trauma-based screen shake
	if _trauma > 0.0:
		_shake_time += delta * 42.0
		_trauma = maxf(0.0, _trauma - TRAUMA_DECAY * delta)
		var shake_intensity: float = _trauma * _trauma
		var nx: float = sin(_shake_time * 1.7) * 0.6 + randf_range(-0.4, 0.4)
		var ny: float = cos(_shake_time * 2.3) * 0.6 + randf_range(-0.4, 0.4)
		camera.offset = Vector2(nx, ny) * MAX_SHAKE_OFFSET * shake_intensity
	else:
		camera.offset = Vector2.ZERO

func add_shake(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

func _on_shotgun_recoil(force: Vector2) -> void:
	if force.y < 0.0:
		add_shake(0.35) # Medium shake on recoil jump vault
	else:
		add_shake(0.14) # Micro-shake on standard gunfire

func _on_player_health_changed(hp: int, _max_hp: int) -> void:
	if hp < player.max_hp:
		add_shake(0.75) # Heavy impact shake on damage

func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null)
