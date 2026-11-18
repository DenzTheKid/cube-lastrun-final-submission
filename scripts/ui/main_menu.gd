extends Control
class_name MainMenu

# Main Menu (Home Page) controller for CUBE: LAST RUN.
# Uses the shared res://assets/ui/game_theme.tres Theme resource, TimeOfDay
# background set to dusk with the sun low and setting, and a quick pixel fade transition.

const SKY_SHADER: Shader = preload("res://shaders/dusk_sky_gradient.gdshader")
const HERO_SKIN_SHADER: Shader = preload("res://shaders/hit_flash.gdshader")
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
@onready var hero_showcase: Sprite2D = %HeroShowcaseSprite
@onready var skin_selector_panel: PanelContainer = %SkinSelectorPanel
@onready var prev_skin_btn: Button = %PrevSkinButton
@onready var next_skin_btn: Button = %NextSkinButton
@onready var skin_name_label: Label = %SkinNameLabel
@onready var skin_status_label: Label = %SkinStatusLabel
@onready var lobby_walker: Sprite2D = %LobbyWalker
@onready var lobby_runner: Sprite2D = %LobbyRunner

var _sfx_enabled: bool = true
var _music_enabled: bool = true
var _time_of_day: Node = null
var _is_transitioning: bool = false
var _diorama_timer: float = 0.0
var _zombie_step: int = 0
var _hero_shader_mat: ShaderMaterial = null
var _skin_style: StyleBoxFlat = null
var _preview_skin_idx: int = 0

func _ready() -> void:
	if AudioManager:
		AudioManager.play_music("menu")
		_sfx_enabled = AudioManager.sfx_volume_db > -40.0
		_music_enabled = AudioManager.music_volume_db > -40.0

	_setup_layout_and_background()
	_setup_skin_selector()
	_setup_buttons_and_focus()

	play_btn.pressed.connect(_on_play_pressed)
	controls_btn.pressed.connect(_on_controls_pressed)
	close_controls_btn.pressed.connect(_on_close_controls_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)
	if prev_skin_btn:
		prev_skin_btn.pressed.connect(func(): _cycle_skin(-1))
	if next_skin_btn:
		next_skin_btn.pressed.connect(func(): _cycle_skin(1))

	sfx_btn.set_pressed_no_signal(_sfx_enabled)
	music_btn.set_pressed_no_signal(_music_enabled)
	UI_ANIMATOR._update_toggle_visual(sfx_btn, _sfx_enabled, false)
	UI_ANIMATOR._update_toggle_visual(music_btn, _music_enabled, false)

	sfx_btn.toggled.connect(_on_sfx_toggled)
	music_btn.toggled.connect(_on_music_toggled)

	controls_panel.visible = false
	_update_high_score()
	refresh_skin_showcase()
	play_btn.grab_focus()

func _process(delta: float) -> void:
	_diorama_timer += delta
	var next_zombie: int = int(_diorama_timer * 6.0) % 4
	if next_zombie != _zombie_step:
		_zombie_step = next_zombie
		if lobby_walker:
			lobby_walker.frame = _zombie_step
		if lobby_runner:
			lobby_runner.frame = (_zombie_step + 2) % 4
	if hero_showcase:
		# Subtle 1px crisp pixel breathing idle bob without shifting RecordPanel layout
		hero_showcase.position.y = -1.0 if int(_diorama_timer * 2.2) % 2 == 1 else 0.0

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
	if prev_skin_btn and next_skin_btn:
		play_btn.focus_neighbor_right = prev_skin_btn.get_path()
		controls_btn.focus_neighbor_right = prev_skin_btn.get_path()
		music_btn.focus_neighbor_right = prev_skin_btn.get_path()
		prev_skin_btn.focus_neighbor_left = play_btn.get_path()
		prev_skin_btn.focus_neighbor_right = next_skin_btn.get_path()
		next_skin_btn.focus_neighbor_left = prev_skin_btn.get_path()
		next_skin_btn.focus_neighbor_right = play_btn.get_path()

func _setup_skin_selector() -> void:
	if hero_showcase:
		_hero_shader_mat = ShaderMaterial.new()
		_hero_shader_mat.shader = HERO_SKIN_SHADER
		hero_showcase.material = _hero_shader_mat
	if skin_selector_panel:
		_skin_style = StyleBoxFlat.new()
		_skin_style.bg_color = Color(0.06, 0.08, 0.16, 0.90)
		_skin_style.border_color = Color(0.22, 0.847, 0.949, 0.55)
		_skin_style.set_border_width_all(1)
		_skin_style.set_corner_radius_all(2)
		_skin_style.content_margin_left = 4
		_skin_style.content_margin_right = 4
		_skin_style.content_margin_top = 2
		_skin_style.content_margin_bottom = 2
		skin_selector_panel.add_theme_stylebox_override("panel", _skin_style)
	if GameManager:
		var ids: Array[String] = GameManager.get_skin_ids()
		var idx: int = ids.find(GameManager.selected_skin)
		_preview_skin_idx = idx if idx >= 0 else 0

func _cycle_skin(delta_idx: int) -> void:
	if not GameManager:
		return
	var ids: Array[String] = GameManager.get_skin_ids()
	if ids.is_empty():
		return
	_preview_skin_idx = (_preview_skin_idx + delta_idx + ids.size()) % ids.size()
	var preview_id: String = ids[_preview_skin_idx]
	var unlocked: bool = GameManager.is_skin_unlocked(preview_id)
	if unlocked:
		GameManager.set_selected_skin(preview_id)
		if AudioManager:
			AudioManager.play_sfx("ui_click")
	else:
		if AudioManager:
			AudioManager.play_sfx("empty")
	refresh_skin_showcase(preview_id)

func refresh_skin_showcase(skin_id: String = "") -> void:
	if not GameManager:
		return
	var ids: Array[String] = GameManager.get_skin_ids()
	var active_id: String = GameManager.selected_skin if skin_id.is_empty() else skin_id
	var idx: int = ids.find(active_id)
	if idx >= 0:
		_preview_skin_idx = idx
	var data: Dictionary = GameManager.get_skin_data(active_id)
	var unlocked: bool = GameManager.is_skin_unlocked(active_id)

	GameManager.apply_skin_to_material(_hero_shader_mat, active_id, true)
	if hero_showcase:
		hero_showcase.modulate = Color.WHITE if unlocked else Color(0.55, 0.58, 0.68, 0.92)

	var accent: Color = data.get("band_hi", Color(1.0, 0.45, 0.49))
	if skin_name_label:
		skin_name_label.text = str(data.get("name", "RED BAND"))
		skin_name_label.add_theme_color_override("font_color", accent if unlocked else accent.darkened(0.25))
	if _skin_style:
		_skin_style.border_color = accent.lerp(Color(0.22, 0.85, 0.95), 0.35) if unlocked else Color(0.45, 0.48, 0.58, 0.65)
	if skin_status_label:
		if unlocked:
			skin_status_label.text = "EQUIPPED" if active_id == GameManager.selected_skin else "UNLOCKED"
			skin_status_label.add_theme_color_override("font_color", Color(0.45, 0.96, 0.65))
		else:
			var req_d: int = int(data.get("unlock_dist", 0))
			var req_s: int = int(data.get("unlock_score", 0))
			skin_status_label.text = "LOCKED: %dm / %d" % [req_d, req_s]
			skin_status_label.add_theme_color_override("font_color", Color(0.96, 0.62, 0.30))

func _update_high_score() -> void:
	if GameManager:
		highscore_label.text = "SCORE: %d  |  COMBO: %dx\nRECORD: %dm" % [GameManager.high_score, GameManager.all_time_best_combo, int(GameManager.max_distance)]

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
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	var tw: Tween = create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.18)
	tw.tween_callback(func():
		if GameManager:
			GameManager.restart_game()
	)
	# Safety timeout fallback to prevent UI deadlock if scene load stalls
	get_tree().create_timer(1.2, true, false, true).timeout.connect(func():
		if _is_transitioning and is_instance_valid(play_btn) and is_inside_tree():
			_is_transitioning = false
			play_btn.disabled = false
			controls_btn.disabled = false
			exit_btn.disabled = false
			if is_instance_valid(fade):
				fade.queue_free()
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
