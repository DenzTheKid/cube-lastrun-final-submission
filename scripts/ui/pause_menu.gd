extends CanvasLayer
class_name PauseMenu

# Pause menu overlay with Resume, Restart, and Main Menu buttons.

@onready var panel: PanelContainer = %PausePanel
@onready var resume_btn: Button = %ResumeButton
@onready var restart_btn: Button = %RestartButton
@onready var menu_btn: Button = %MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		if GameManager and GameManager.current_state == GameManager.State.PLAYING:
			toggle_pause()

func toggle_pause() -> void:
	var paused: bool = not get_tree().paused
	get_tree().paused = paused
	panel.visible = paused
	if paused:
		resume_btn.grab_focus()
		if AudioManager:
			AudioManager.play_sfx("ui_click")

func _on_resume_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	toggle_pause()

func _on_restart_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	get_tree().paused = false
	if GameManager:
		GameManager.restart_game()

func _on_menu_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	get_tree().paused = false
	if GameManager:
		GameManager.go_to_menu()
