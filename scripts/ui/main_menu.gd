extends Control
class_name MainMenu

# Main Menu (Home Page) controller for CUBE: LAST RUN.
# Uses the shared res://assets/ui/game_theme.tres Theme resource, TimeOfDay
# background set to dusk with the sun low and setting, and a quick pixel fade transition.

const SKY_SHADER: Shader = preload("res://shaders/dusk_sky_gradient.gdshader")
const TIME_OF_DAY_SCRIPT = preload("res://scripts/gameplay/time_of_day.gd")
const UI_ANIMATOR = preload("res://scripts/ui/ui_animator.gd")

@onready var play_btn: Button = %PlayButton
@onready var controls_btn: Button = %ControlsButton
@onready var exit_btn: Button = %ExitButton
@onready var controls_panel: PanelContainer = %ControlsPanel
@onready var close_controls_btn: Button = %CloseControlsButton
@onready var highscore_label: Label = %HighScoreLabel
@onready var sfx_btn: CheckButton = %SfxCheckButton
@onready var music_btn: CheckButton = %MusicCheckButton
@onready var bg_sky: TextureRect = $BgSky
@onready var bg_skyline: TextureRect = $BgSkyline
@onready var bg_buildings: TextureRect = $BgBuildings
@onready var bg_overpass: TextureRect = $BgOverpass
@onready var center_container: CenterContainer = $CenterContainer

var _sfx_enabled: bool = true
var _music_enabled: bool = true
var _time_of_day: Node = null
var _is_transitioning: bool = false

func _ready() -> void:
	if AudioManager:
		AudioManager.play_music("menu")
		_sfx_enabled = AudioManager.sfx_volume_db > -40.0
		_music_enabled = AudioManager.music_volume_db > -40.0

	_setup_layout_and_background()
	_setup_buttons_and_focus()

	play_btn.pressed.connect(_on_play_pressed)
	controls_btn.pressed.connect(_on_controls_pressed)
	close_controls_btn.pressed.connect(_on_close_controls_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)

	sfx_btn.set_pressed_no_signal(_sfx_enabled)
	music_btn.set_pressed_no_signal(_music_enabled)
	UI_ANIMATOR._update_toggle_visual(sfx_btn, _sfx_enabled, false)
	UI_ANIMATOR._update_toggle_visual(music_btn, _music_enabled, false)

	sfx_btn.toggled.connect(_on_sfx_toggled)
	music_btn.toggled.connect(_on_music_toggled)

	controls_panel.visible = false
	_update_high_score()
	play_btn.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if controls_panel and controls_panel.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			_on_close_controls_pressed()
			get_viewport().set_input_as_handled()

func _setup_layout_and_background() -> void:
	if get_parent() is Window:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		set_anchors_preset(Control.PRESET_TOP_LEFT)
		position = Vector2.ZERO
		size = Vector2(480.0, 270.0)

	var sky_mat: ShaderMaterial = null
	if bg_sky:
		sky_mat = ShaderMaterial.new()
		sky_mat.shader = SKY_SHADER
		bg_sky.material = sky_mat

	_time_of_day = TIME_OF_DAY_SCRIPT.new()
	_time_of_day.name = "TimeOfDay"
	add_child(_time_of_day)
	_time_of_day.bind_layers(sky_mat, bg_skyline, bg_buildings, bg_overpass)
	# Default lobby background to dusk with the sun low and setting cleanly in the right sky gap
	if not _time_of_day._debug_override_active:
		_time_of_day.set_fixed_time(0.36)

func _setup_buttons_and_focus() -> void:
	UI_ANIMATOR.style_button(play_btn, true)
	UI_ANIMATOR.style_button(controls_btn, false)
	UI_ANIMATOR.style_button(exit_btn, false)
	UI_ANIMATOR.style_button(close_controls_btn, true)
	UI_ANIMATOR.style_toggle_button(sfx_btn, "SFX")
	UI_ANIMATOR.style_toggle_button(music_btn, "BGM")

	play_btn.focus_neighbor_top = exit_btn.get_path()
	play_btn.focus_neighbor_bottom = controls_btn.get_path()
	controls_btn.focus_neighbor_top = play_btn.get_path()
	controls_btn.focus_neighbor_bottom = sfx_btn.get_path()
	sfx_btn.focus_neighbor_top = controls_btn.get_path()
	sfx_btn.focus_neighbor_right = music_btn.get_path()
	sfx_btn.focus_neighbor_bottom = exit_btn.get_path()
	music_btn.focus_neighbor_top = controls_btn.get_path()
	music_btn.focus_neighbor_left = sfx_btn.get_path()
	music_btn.focus_neighbor_bottom = exit_btn.get_path()
	exit_btn.focus_neighbor_top = sfx_btn.get_path()
	exit_btn.focus_neighbor_bottom = play_btn.get_path()

func _update_high_score() -> void:
	if GameManager:
		highscore_label.text = "HIGH SCORE: %d\nRECORD: %dm" % [GameManager.high_score, int(GameManager.max_distance)]

func _on_play_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	play_btn.disabled = true
	controls_btn.disabled = true
	exit_btn.disabled = true
	if AudioManager:
		AudioManager.play_sfx("ui_click")

	# Quick 0.18s pixel fade before starting the run
	var fade := ColorRect.new()
	fade.color = Color(0.04, 0.04, 0.08, 0.0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fade)
	var tw: Tween = create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.18)
	tw.tween_callback(func():
		if GameManager:
			GameManager.restart_game()
	)

func _on_controls_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	if center_container:
		center_container.visible = false
	controls_panel.visible = true
	close_controls_btn.grab_focus()

func _on_close_controls_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	controls_panel.visible = false
	if center_container:
		center_container.visible = true
	controls_btn.grab_focus()

func _on_sfx_toggled(toggled_on: bool) -> void:
	_sfx_enabled = toggled_on
	if AudioManager:
		AudioManager.set_sfx_volume(1.0 if _sfx_enabled else 0.0)
		if _sfx_enabled:
			AudioManager.play_sfx("ui_click")

func _on_music_toggled(toggled_on: bool) -> void:
	_music_enabled = toggled_on
	if AudioManager:
		AudioManager.set_music_volume(1.0 if _music_enabled else 0.0)
		AudioManager.play_sfx("ui_click")

func _on_exit_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	get_tree().quit()
