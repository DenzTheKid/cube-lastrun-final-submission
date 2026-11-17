extends CanvasLayer
class_name PauseMenu

# Pause menu overlay with Resume, Restart, Audio Settings, and Main Menu buttons.

@onready var panel: PanelContainer = %PausePanel
@onready var resume_btn: Button = %ResumeButton
@onready var restart_btn: Button = %RestartButton
@onready var menu_btn: Button = %MenuButton
@onready var sfx_check: CheckButton = %PauseSfxCheck
@onready var music_check: CheckButton = %PauseMusicCheck

const UI_ANIMATOR = preload("res://scripts/ui/ui_animator.gd")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	UI_ANIMATOR.style_button(resume_btn, true)
	UI_ANIMATOR.style_button(restart_btn, false)
	UI_ANIMATOR.style_button(menu_btn, false)
	if sfx_check:
		UI_ANIMATOR.style_toggle_button(sfx_check, "SFX")
	if music_check:
		UI_ANIMATOR.style_toggle_button(music_check, "BGM")
	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)

	if sfx_check:
		sfx_check.toggled.connect(_on_sfx_toggled)
	if music_check:
		music_check.toggled.connect(_on_music_toggled)

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

func _on_sfx_toggled(toggled_on: bool) -> void:
	if AudioManager:
		AudioManager.set_sfx_volume(1.0 if toggled_on else 0.0)

func _on_music_toggled(toggled_on: bool) -> void:
	if AudioManager:
		AudioManager.set_music_volume(1.0 if toggled_on else 0.0)

func _on_menu_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	get_tree().paused = false
	if GameManager:
		GameManager.go_to_menu()
