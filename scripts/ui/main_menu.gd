extends Control
class_name MainMenu

# Main Menu controller with start game, controls overlay, volume settings,
# and high score record display.

@onready var play_btn: Button = %PlayButton
@onready var controls_btn: Button = %ControlsButton
@onready var exit_btn: Button = %ExitButton
@onready var controls_panel: PanelContainer = %ControlsPanel
@onready var close_controls_btn: Button = %CloseControlsButton
@onready var highscore_label: Label = %HighScoreLabel
@onready var sfx_btn: CheckButton = %SfxCheckButton
@onready var music_btn: CheckButton = %MusicCheckButton

var _sfx_enabled: bool = true
var _music_enabled: bool = true

func _ready() -> void:
	if AudioManager:
		AudioManager.play_music("menu")

	play_btn.pressed.connect(_on_play_pressed)
	controls_btn.pressed.connect(_on_controls_pressed)
	close_controls_btn.pressed.connect(func(): controls_panel.visible = false)
	exit_btn.pressed.connect(_on_exit_pressed)

	sfx_btn.toggled.connect(_on_sfx_toggled)
	music_btn.toggled.connect(_on_music_toggled)

	controls_panel.visible = false
	_update_high_score()
	play_btn.grab_focus()

func _update_high_score() -> void:
	if GameManager:
		highscore_label.text = "HIGH SCORE: %d  |  RECORD: %dm" % [GameManager.high_score, int(GameManager.max_distance)]

func _on_play_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	if GameManager:
		GameManager.restart_game()

func _on_controls_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	controls_panel.visible = true
	close_controls_btn.grab_focus()

func _on_sfx_toggled(toggled_on: bool) -> void:
	_sfx_enabled = toggled_on
	if AudioManager:
		AudioManager.set_sfx_volume(1.0 if _sfx_enabled else 0.0)

func _on_music_toggled(toggled_on: bool) -> void:
	_music_enabled = toggled_on
	if AudioManager:
		AudioManager.set_music_volume(1.0 if _music_enabled else 0.0)

func _on_exit_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	get_tree().quit()
