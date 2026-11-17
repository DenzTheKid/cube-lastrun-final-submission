extends Control
class_name MainMenu

# AAA-Indie Main Menu controller for CUBE: LAST RUN.
# Features:
# - Live animated golden-hour/dusk city skyline with dusk_sky_gradient.gdshader
# - Drifting atmospheric embers and gentle camera sway
# - Metallic gleam title shader (title_gleam.gdshader) & rhythmic breathing scale
# - Sleek beveled interactive buttons with Tween hover animations via UIAnimator

const SKY_SHADER: Shader = preload("res://shaders/dusk_sky_gradient.gdshader")
const TITLE_GLEAM_SHADER: Shader = preload("res://shaders/title_gleam.gdshader")
const VIGNETTE_SHADER: Shader = preload("res://shaders/atmospheric_vignette.gdshader")
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
@onready var title_label: Label = $CenterContainer/VBox/Title
@onready var tagline_label: Label = $CenterContainer/VBox/Tagline

var _sfx_enabled: bool = true
var _music_enabled: bool = true
var _menu_time: float = 0.0

func _ready() -> void:
	if AudioManager:
		AudioManager.play_music("menu")

	_setup_live_background_and_typography()

	UI_ANIMATOR.style_button(play_btn, true)
	UI_ANIMATOR.style_button(controls_btn, false)
	UI_ANIMATOR.style_button(exit_btn, false)
	UI_ANIMATOR.style_button(close_controls_btn, true)

	play_btn.pressed.connect(_on_play_pressed)
	controls_btn.pressed.connect(_on_controls_pressed)
	close_controls_btn.pressed.connect(func():
		if AudioManager:
			AudioManager.play_sfx("ui_click")
		controls_panel.visible = false
		play_btn.grab_focus()
	)
	exit_btn.pressed.connect(_on_exit_pressed)

	sfx_btn.toggled.connect(_on_sfx_toggled)
	music_btn.toggled.connect(_on_music_toggled)

	controls_panel.visible = false
	_update_high_score()
	play_btn.grab_focus()

func _setup_live_background_and_typography() -> void:
	# Ensure exact 480x270 full-rect alignment whether run as main scene or child of Node2D
	if get_parent() is Window:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	else:
		size = Vector2(480.0, 270.0)

	if bg_skyline:
		bg_skyline.offset_left = -12.0
		bg_skyline.offset_right = 12.0
	if bg_buildings:
		bg_buildings.offset_left = -16.0
		bg_buildings.offset_right = 16.0

	# 1. Atmospheric Dusk Sky Shader on BgSky
	if bg_sky:
		var sky_mat := ShaderMaterial.new()
		sky_mat.shader = SKY_SHADER
		bg_sky.material = sky_mat

	# 2. Drifting Embers in Menu Background
	var embers := CPUParticles2D.new()
	embers.name = "MenuEmbers"
	embers.position = Vector2(490.0, 135.0)
	embers.amount = 24
	embers.lifetime = 4.0
	embers.preprocess = 2.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(20.0, 135.0)
	embers.direction = Vector2(-1.0, -0.1)
	embers.spread = 15.0
	embers.gravity = Vector2(-5.0, -4.0)
	embers.initial_velocity_min = 45.0
	embers.initial_velocity_max = 95.0
	embers.scale_amount_min = 1.2
	embers.scale_amount_max = 2.4
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.65, 0.22, 0.85))
	grad.set_color(1, Color(0.9, 0.25, 0.12, 0.0))
	embers.color = Color(1.0, 0.62, 0.20, 0.85)
	embers.color_ramp = grad
	add_child(embers)
	move_child(embers, 3)

	# 3. Title Typography Bevel, Outline & Gleam Sweep Shader
	if title_label:
		title_label.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.10, 1.0))
		title_label.add_theme_constant_override("outline_size", 4)
		var tmat := ShaderMaterial.new()
		tmat.shader = TITLE_GLEAM_SHADER
		title_label.material = tmat

	if tagline_label:
		tagline_label.add_theme_color_override("font_outline_color", Color(0.06, 0.05, 0.10, 1.0))
		tagline_label.add_theme_constant_override("outline_size", 2)

	# 4. Subtle Cinematic Vignette Overlay
	var vig := ColorRect.new()
	vig.name = "MenuVignette"
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vmat := ShaderMaterial.new()
	vmat.shader = VIGNETTE_SHADER
	vmat.set_shader_parameter("base_vignette", 0.36)
	vig.material = vmat
	add_child(vig)

func _process(delta: float) -> void:
	_menu_time += delta
	# Gentle live camera sway on skyline layers
	if bg_skyline:
		bg_skyline.position.x = -12.0 + sin(_menu_time * 0.45) * 6.0
	if bg_buildings:
		bg_buildings.position.x = -16.0 + sin(_menu_time * 0.75 + 1.0) * 10.0
	# Rhythmic breathing scale on title typography
	if title_label:
		title_label.pivot_offset = title_label.size * 0.5
		var s: float = 1.0 + 0.025 * sin(_menu_time * 2.4)
		title_label.scale = Vector2(s, s)

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
