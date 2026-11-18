extends CanvasLayer
class_name PauseMenu

# Pause menu overlay with Resume, Restart, Audio Settings, and Main Menu buttons.

@onready var panel: PanelContainer = %PausePanel
@onready var dimmer: ColorRect = %Dimmer
@onready var resume_btn: Button = %ResumeButton
@onready var restart_btn: Button = %RestartButton
@onready var menu_btn: Button = %MenuButton
@onready var sfx_check: CheckButton = %PauseSfxCheck
@onready var music_check: CheckButton = %PauseMusicCheck

const UI_ANIMATOR = preload("res://scripts/ui/ui_animator.gd")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	if dimmer:
		dimmer.visible = false
	UI_ANIMATOR.style_button(resume_btn, true)
	UI_ANIMATOR.style_button(restart_btn, false)
	UI_ANIMATOR.style_button(menu_btn, false)
	if sfx_check:
		UI_ANIMATOR.style_toggle_button(sfx_check, "SFX")
	if music_check:
		UI_ANIMATOR.style_toggle_button(music_check, "BGM")
	if AudioManager:
		if sfx_check:
			var sfx_on: bool = AudioManager.sfx_volume_db > -40.0
			sfx_check.set_pressed_no_signal(sfx_on)
			UI_ANIMATOR._update_toggle_visual(sfx_check, sfx_on, false)
		if music_check:
			var bgm_on: bool = AudioManager.music_volume_db > -40.0
			music_check.set_pressed_no_signal(bgm_on)
			UI_ANIMATOR._update_toggle_visual(music_check, bgm_on, false)

	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)

	_setup_focus_neighbors()

	if sfx_check:
		sfx_check.toggled.connect(_on_sfx_toggled)
	if music_check:
		music_check.toggled.connect(_on_music_toggled)

func _setup_focus_neighbors() -> void:
	resume_btn.focus_neighbor_top = menu_btn.get_path()
	resume_btn.focus_neighbor_bottom = restart_btn.get_path()
	restart_btn.focus_neighbor_top = resume_btn.get_path()
	if sfx_check:
		restart_btn.focus_neighbor_bottom = sfx_check.get_path()
		sfx_check.focus_neighbor_top = restart_btn.get_path()
		sfx_check.focus_neighbor_bottom = menu_btn.get_path()
		if music_check:
			sfx_check.focus_neighbor_right = music_check.get_path()
			music_check.focus_neighbor_left = sfx_check.get_path()
			music_check.focus_neighbor_top = restart_btn.get_path()
			music_check.focus_neighbor_bottom = menu_btn.get_path()
		menu_btn.focus_neighbor_top = sfx_check.get_path()
	else:
		restart_btn.focus_neighbor_bottom = menu_btn.get_path()
		menu_btn.focus_neighbor_top = restart_btn.get_path()
	menu_btn.focus_neighbor_bottom = resume_btn.get_path()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		if GameManager and GameManager.current_state == GameManager.State.PLAYING:
			toggle_pause()

func toggle_pause() -> void:
	var paused: bool = not get_tree().paused
	get_tree().paused = paused
	panel.visible = paused
	if dimmer:
		dimmer.visible = paused
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
