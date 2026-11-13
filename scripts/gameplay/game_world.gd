extends Node2D
class_name GameWorld

# Core gameplay world for CUBE: LAST RUN.
# Coordinates the player, camera horizontal framing, rear horde pursuer,
# modular procedural level generator, and UI overlays.

@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var horde: RearHorde = $RearHorde
@onready var level_gen: LevelGenerator = $LevelGenerator
@onready var hud: HUD = $HUD
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var game_over_menu: GameOverMenu = $GameOverMenu

# Camera framing: keep player on left side (~140px from screen left)
const CAMERA_OFFSET_X: float = 100.0

func _ready() -> void:
	if GameManager:
		GameManager.start_game()

	# Wire up player to HUD and sub-systems
	if hud and player:
		hud.setup_player(player)

	if horde and player:
		horde.set_player(player)

	if level_gen and player:
		level_gen.setup(player)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		return

	# Camera follows player X with horizontal lead
	# Keeps Y fixed at center of screen (135.0) for stable 2D runner presentation
	camera.global_position.x = player.global_position.x + CAMERA_OFFSET_X
	camera.global_position.y = 135.0
