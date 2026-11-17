extends Control
class_name MainMenu

# Main Menu (Lobby) controller for CUBE: LAST RUN.
# Uses the TimeOfDay background controller set to dusk, static city layers,
# flat pixel-art StyleBox buttons with 2px borders, keyboard/gamepad focus
# navigation, and high-score record persistence.

const SKY_SHADER: Shader = preload("res://shaders/dusk_sky_gradient.gdshader")
const TIME_OF_DAY_SCRIPT = preload("res://scripts/gameplay/time_of_day.gd")
const UI_ANIMATOR = preload("res://scripts/ui/ui_animator.gd")

@onready var play_btn: Button = %PlayButton
@onready var controls_btn: Button = %ControlsButton
@onready var exit_btn: Button = %ExitButton
@onready var controls_panel: PanelContainer = %ControlsPanel
@onready var close_controls_btn: Button = %CloseControlsButton
@onready var highscore_label: Label = %HighScoreLabel
@onready var record_header: Label = %RecordHeader
@onready var version_label: Label = %VersionLabel
@onready var hint_label: Label = %HintLabel
@onready var sfx_btn: CheckButton = %SfxCheckButton
@onready var music_btn: CheckButton = %MusicCheckButton
@onready var bg_sky: TextureRect = $BgSky
@onready var bg_skyline: TextureRect = $BgSkyline
@onready var bg_buildings: TextureRect = $BgBuildings
@onready var bg_overpass: TextureRect = $BgOverpass
@onready var title_label: Label = %Title
@onready var tagline_label: Label = %Tagline

var _sfx_enabled: bool = true
var _music_enabled: bool = true
var _time_of_day: Node = null

func _ready() -> void:
	if AudioManager:
		AudioManager.play_music("menu")
		_sfx_enabled = AudioManager.sfx_volume_db > -40.0
		_music_enabled = AudioManager.music_volume_db > -40.0

	_setup_layout_and_background()
	_setup_typography_and_buttons()

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
	# Support both root Window responsive layout and Node2D test-runner instantiation
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
	# Default lobby background to the dusk horizon look unless overridden by --tod=
	if not _time_of_day._debug_override_active:
		_time_of_day.set_fixed_time(0.65)

func _setup_typography_and_buttons() -> void:
	UI_ANIMATOR.apply_label_font(title_label, true, 22)
	UI_ANIMATOR.apply_label_font(tagline_label, false, 9)
	UI_ANIMATOR.apply_label_font(record_header, false, 9)
	UI_ANIMATOR.apply_label_font(highscore_label, false, 9)
	UI_ANIMATOR.apply_label_font(version_label, false, 8)
	UI_ANIMATOR.apply_label_font(hint_label, false, 8)

	var ctrl_header := get_node_or_null("ControlsPanel/Margin/VBox/Header") as Label
	var ctrl_text := get_node_or_null("ControlsPanel/Margin/VBox/Text") as Label
	if ctrl_header:
		UI_ANIMATOR.apply_label_font(ctrl_header, true, 12)
	if ctrl_text:
		UI_ANIMATOR.apply_label_font(ctrl_text, false, 9)

	UI_ANIMATOR.style_button(play_btn, true)
	UI_ANIMATOR.style_button(controls_btn, false)
	UI_ANIMATOR.style_button(exit_btn, false)
	UI_ANIMATOR.style_button(close_controls_btn, true)
	UI_ANIMATOR.style_toggle_button(sfx_btn, "SFX")
	UI_ANIMATOR.style_toggle_button(music_btn, "BGM")

	# Explicit keyboard / gamepad focus neighbor chain
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
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	if GameManager:
		GameManager.restart_game()

func _on_controls_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	controls_panel.visible = true
	close_controls_btn.grab_focus()

func _on_close_controls_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	controls_panel.visible = false
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
