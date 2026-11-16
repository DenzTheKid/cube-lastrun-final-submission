extends Node2D
class_name GameWorld

# Core gameplay world for CUBE: LAST RUN V1.1.
# Coordinates the player, camera horizontal framing with trauma-based screen shake,
# rear horde pursuer, modular procedural level generator, and UI overlays.

@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var horde: RearHorde = $RearHorde
@onready var level_gen: LevelGenerator = $LevelGenerator
@onready var hud: HUD = $HUD
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var game_over_menu: GameOverMenu = $GameOverMenu

# Camera framing: player positioned around 100-140px from screen left
const CAMERA_OFFSET_X: float = 100.0
const CAMERA_BASE_Y: float = 135.0

# Trauma-based screen shake
var _trauma: float = 0.0
const TRAUMA_DECAY: float = 2.2
const MAX_SHAKE_OFFSET: float = 6.0

func _ready() -> void:
	# Set custom pixel crosshair reticle for 360° mouse aiming
	var crosshair_tex = load("res://assets/ui/crosshair_reticle.png")
	if crosshair_tex:
		Input.set_custom_mouse_cursor(crosshair_tex, Input.CURSOR_ARROW, Vector2(16, 16))

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

	# Smooth camera follow on X, fixed on Y
	camera.global_position.x = player.global_position.x + CAMERA_OFFSET_X
	camera.global_position.y = CAMERA_BASE_Y

	# Apply trauma-based screen shake
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - TRAUMA_DECAY * delta)
		var shake_intensity: float = _trauma * _trauma
		camera.offset = Vector2(
			randf_range(-1.0, 1.0) * MAX_SHAKE_OFFSET * shake_intensity,
			randf_range(-1.0, 1.0) * MAX_SHAKE_OFFSET * shake_intensity
		)
	else:
		camera.offset = Vector2.ZERO

func add_shake(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)

func _on_shotgun_recoil(force: Vector2) -> void:
	if force.y < 0.0:
		add_shake(0.28) # Heavier kick on recoil jump
	else:
		add_shake(0.18) # Standard shot shake

func _on_player_health_changed(hp: int, _max_hp: int) -> void:
	if hp < player.max_hp:
		add_shake(0.45) # Sharp impact shake on damage

func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null)

