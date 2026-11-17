extends Control
class_name MainMenu

# AAA-Indie Main Menu / Lobby controller for CUBE: LAST RUN.
# Features:
# - Live animated golden-hour/dusk city skyline with dusk_sky_gradient.gdshader
# - Live Lobby Hero Diorama (running Cube Survivor with shotgun, scarf & pursuing zombies)
# - Chamfered tactical metal button plates (StyleBoxTexture) with hazard stripes
# - Crisp non-antialiased arcade pixel typography & metallic gleam title sweep

const SKY_SHADER: Shader = preload("res://shaders/dusk_sky_gradient.gdshader")
const TITLE_GLEAM_SHADER: Shader = preload("res://shaders/title_gleam.gdshader")
const VIGNETTE_SHADER: Shader = preload("res://shaders/atmospheric_vignette.gdshader")
const UI_ANIMATOR = preload("res://scripts/ui/ui_animator.gd")
const PLAYER_TEX: Texture2D = preload("res://assets/characters/cube_player.png")
const GUN_TEX: Texture2D = preload("res://assets/weapons/shotgun.png")
const WALKER_TEX: Texture2D = preload("res://assets/zombies/zombie_walker.png")
const RUNNER_TEX: Texture2D = preload("res://assets/zombies/zombie_runner.png")

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
@onready var title_label: Label = %Title
@onready var tagline_label: Label = %Tagline

var _sfx_enabled: bool = true
var _music_enabled: bool = true
var _menu_time: float = 0.0
var _hero_sprite: Sprite2D = null
var _zombie_1: Sprite2D = null
var _zombie_2: Sprite2D = null
var _scarf_line: Line2D = null

func _ready() -> void:
	if AudioManager:
		AudioManager.play_music("menu")

	_setup_live_background_and_typography()
	_setup_lobby_diorama()

	UI_ANIMATOR.style_button(play_btn, true)
	UI_ANIMATOR.style_button(controls_btn, false)
	UI_ANIMATOR.style_button(exit_btn, false)
	UI_ANIMATOR.style_button(close_controls_btn, true)
	UI_ANIMATOR.style_toggle_button(sfx_btn, "SFX")
	UI_ANIMATOR.style_toggle_button(music_btn, "BGM")

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
	position = Vector2.ZERO
	size = Vector2(480.0, 270.0)

	if bg_skyline:
		bg_skyline.offset_left = -12.0
		bg_skyline.offset_right = 12.0
	if bg_buildings:
		bg_buildings.offset_left = -16.0
		bg_buildings.offset_right = 16.0

	if bg_sky:
		var sky_mat := ShaderMaterial.new()
		sky_mat.shader = SKY_SHADER
		bg_sky.material = sky_mat

	# Drifting Embers in Lobby Background
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
	embers.scale_amount_max = 2.2
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.65, 0.22, 0.85))
	grad.set_color(1, Color(0.9, 0.25, 0.12, 0.0))
	embers.color = Color(1.0, 0.62, 0.20, 0.85)
	embers.color_ramp = grad
	add_child(embers)
	move_child(embers, 4)

	# Arcade Pixel Font & Metallic Gleam Shader on Title
	if title_label:
		UI_ANIMATOR.apply_label_font(title_label, true, 24)
		var tmat := ShaderMaterial.new()
		tmat.shader = TITLE_GLEAM_SHADER
		title_label.material = tmat

	if tagline_label:
		UI_ANIMATOR.apply_label_font(tagline_label, false, 9)

	if highscore_label:
		UI_ANIMATOR.apply_label_font(highscore_label, false, 10)

	var header_lbl := get_node_or_null("ControlsPanel/Margin/VBox/Header") as Label
	var body_lbl := get_node_or_null("ControlsPanel/Margin/VBox/Text") as Label
	if header_lbl:
		UI_ANIMATOR.apply_label_font(header_lbl, true, 14)
	if body_lbl:
		UI_ANIMATOR.apply_label_font(body_lbl, false, 9)

	# Subtle Cinematic Vignette Overlay
	var vig := ColorRect.new()
	vig.name = "MenuVignette"
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vmat := ShaderMaterial.new()
	vmat.shader = VIGNETTE_SHADER
	vmat.set_shader_parameter("base_vignette", 0.32)
	vig.material = vmat
	add_child(vig)

func _setup_lobby_diorama() -> void:
	var diorama := Node2D.new()
	diorama.name = "LobbyDiorama"
	add_child(diorama)
	move_child(diorama, 5) # Right above LobbyRoad, behind CenterContainer UI

	# Cube Survivor running along the highway in the lobby
	_hero_sprite = Sprite2D.new()
	_hero_sprite.texture = PLAYER_TEX
	_hero_sprite.hframes = 6
	_hero_sprite.vframes = 8
	_hero_sprite.frame = 6
	_hero_sprite.position = Vector2(78.0, 214.0)
	_hero_sprite.rotation = deg_to_rad(8.5)
	diorama.add_child(_hero_sprite)

	# Flowing crimson scarf on Lobby Hero
	_scarf_line = Line2D.new()
	_scarf_line.width = 3.0
	_scarf_line.default_color = Color(0.92, 0.18, 0.25, 1.0)
	_scarf_line.z_index = -1
	_hero_sprite.add_child(_scarf_line)

	# Equipped Double-Barrel Shotgun on Lobby Hero
	var gun := Sprite2D.new()
	gun.texture = GUN_TEX
	gun.position = Vector2(8.0, 3.0)
	_hero_sprite.add_child(gun)

	# Oncoming Zombies on the right side of the highway
	_zombie_1 = Sprite2D.new()
	_zombie_1.texture = RUNNER_TEX
	_zombie_1.hframes = 4
	_zombie_1.position = Vector2(396.0, 214.0)
	diorama.add_child(_zombie_1)

	_zombie_2 = Sprite2D.new()
	_zombie_2.texture = WALKER_TEX
	_zombie_2.hframes = 4
	_zombie_2.position = Vector2(436.0, 214.0)
	diorama.add_child(_zombie_2)

func _process(delta: float) -> void:
	_menu_time += delta
	if bg_skyline:
		bg_skyline.position.x = -12.0 + sin(_menu_time * 0.45) * 6.0
	if bg_buildings:
		bg_buildings.position.x = -16.0 + sin(_menu_time * 0.75 + 1.0) * 10.0

	if title_label:
		title_label.pivot_offset = title_label.size * 0.5
		var s: float = 1.0 + 0.025 * sin(_menu_time * 2.6)
		title_label.scale = Vector2(s, s)

	# Animate Lobby Diorama Characters
	var run_frame: int = int(_menu_time * 10.0) % 6
	if _hero_sprite:
		_hero_sprite.frame = 6 + run_frame
	if _zombie_1:
		_zombie_1.frame = int(_menu_time * 8.0) % 4
	if _zombie_2:
		_zombie_2.frame = int(_menu_time * 6.0 + 2.0) % 4
	if _scarf_line:
		var pts := PackedVector2Array()
		for i in range(6):
			pts.append(Vector2(-4.0 - float(i) * 2.5, -3.0 + sin(_menu_time * 14.0 - float(i) * 0.9) * 1.6))
		_scarf_line.points = pts

func _update_high_score() -> void:
	if GameManager:
		highscore_label.text = "★ HIGH SCORE: %d  |  RECORD: %dm ★" % [GameManager.high_score, int(GameManager.max_distance)]

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
