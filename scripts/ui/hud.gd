extends CanvasLayer
class_name HUD

# AAA-Indie Gameplay HUD for CUBE: LAST RUN.
# Features:
# - Sleek semi-transparent dark pill containers for SCORE, DIST, TIME, and HP: 2/2
# - Segmented glowing shield/heart pips (hp_pip_full.png / hp_pip_empty.png) with shatter shake
# - Dynamic floating Combo / Kill Streak Multiplier badge (x2, x3, x5)
# - Two-shell ammunition indicator with active reload gauge
# - Pulsing HORDE danger indicator + atmospheric crimson warning vignette shader

const VIGNETTE_SHADER: Shader = preload("res://shaders/atmospheric_vignette.gdshader")
const PIP_FULL_TEX: Texture2D = preload("res://assets/ui/hp_pip_full.png")
const PIP_EMPTY_TEX: Texture2D = preload("res://assets/ui/hp_pip_empty.png")

@onready var root_control: Control = $RootControl
@onready var score_label: Label = %ScoreLabel
@onready var distance_label: Label = %DistanceLabel
@onready var time_label: Label = %TimeLabel
@onready var shell_1: TextureRect = %Shell1
@onready var shell_2: TextureRect = %Shell2
@onready var reload_bar: ProgressBar = %ReloadBar
@onready var reload_label: Label = %ReloadLabel
@onready var horde_bar: ProgressBar = %HordeBar
@onready var horde_warning: Label = %HordeWarning
@onready var hp_label: Label = %HpLabel

var _is_reloading: bool = false
var _reload_duration: float = 0.80
var _reload_elapsed: float = 0.0
var _warning_pulse_timer: float = 0.0

var _combo_label: Label = null
var _hp_pip_1: TextureRect = null
var _hp_pip_2: TextureRect = null
var _vignette_mat: ShaderMaterial = null
var _current_proximity: float = 0.0
var _low_hp_danger: float = 0.0

func _ready() -> void:
	_setup_aaa_hud_visuals()

	if GameManager:
		GameManager.score_updated.connect(_on_score_updated)
		GameManager.distance_updated.connect(_on_distance_updated)
		GameManager.horde_proximity_changed.connect(_on_horde_proximity_changed)
		GameManager.combo_updated.connect(_on_combo_updated)
	reload_bar.visible = false
	reload_label.visible = false
	horde_warning.visible = false

func _setup_aaa_hud_visuals() -> void:
	# 1. Fullscreen Atmospheric Vignette + Red Danger Pulse + Speed Lines Overlay
	var vig_rect := ColorRect.new()
	vig_rect.name = "AtmosphericVignette"
	vig_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette_mat = ShaderMaterial.new()
	_vignette_mat.shader = VIGNETTE_SHADER
	_vignette_mat.set_shader_parameter("base_vignette", 0.30)
	_vignette_mat.set_shader_parameter("danger_intensity", 0.0)
	_vignette_mat.set_shader_parameter("speed_intensity", 0.0)
	vig_rect.material = _vignette_mat
	root_control.add_child(vig_rect)
	root_control.move_child(vig_rect, 0)

	# 2. Crisp Outlines & Drop Shadows on Top Bar Labels
	for lbl: Label in [score_label, distance_label, time_label, hp_label, reload_label, horde_warning]:
		if lbl:
			lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.09, 1.0))
			lbl.add_theme_constant_override("outline_size", 2)

	# 3. Segmented Glowing Heart/Shield Pips next to HP: 2/2
	var top_hbox := hp_label.get_parent() as HBoxContainer
	if top_hbox:
		var pip_box := HBoxContainer.new()
		pip_box.name = "HpPipsBox"
		pip_box.add_theme_constant_override("separation", 3)
		_hp_pip_1 = TextureRect.new()
		_hp_pip_1.custom_minimum_size = Vector2(12, 12)
		_hp_pip_1.texture = PIP_FULL_TEX
		_hp_pip_1.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_hp_pip_2 = TextureRect.new()
		_hp_pip_2.custom_minimum_size = Vector2(12, 12)
		_hp_pip_2.texture = PIP_FULL_TEX
		_hp_pip_2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pip_box.add_child(_hp_pip_1)
		pip_box.add_child(_hp_pip_2)
		top_hbox.add_child(pip_box)

	# 4. Dynamic Floating Combo / Kill Streak Multiplier Badge below SCORE
	_combo_label = Label.new()
	_combo_label.name = "ComboBadge"
	_combo_label.visible = false
	_combo_label.position = Vector2(14.0, 28.0)
	_combo_label.text = "x2 COMBO!"
	_combo_label.add_theme_font_size_override("font_size", 10)
	_combo_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.22, 1.0))
	_combo_label.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.06, 1.0))
	_combo_label.add_theme_constant_override("outline_size", 3)
	root_control.add_child(_combo_label)

func _process(delta: float) -> void:
	if GameManager and GameManager.current_state == GameManager.State.PLAYING:
		var t: int = int(GameManager.survival_time)
		var mins: int = int(t / 60.0)
		var secs: int = t % 60
		time_label.text = "TIME: %02d:%02d" % [mins, secs]

		if _vignette_mat:
			var spd_intensity: float = clampf((GameManager.difficulty_factor - 1.0) / 1.2, 0.0, 1.0)
			var horde_danger: float = clampf((_current_proximity - 0.45) / 0.55, 0.0, 1.0)
			var total_danger: float = maxf(horde_danger, _low_hp_danger)
			_vignette_mat.set_shader_parameter("speed_intensity", spd_intensity)
			_vignette_mat.set_shader_parameter("danger_intensity", total_danger)

	if _is_reloading:
		_reload_elapsed += delta
		reload_bar.value = clampf((_reload_elapsed / _reload_duration) * 100.0, 0.0, 100.0)

	if horde_warning.visible:
		_warning_pulse_timer += delta * 8.0
		var pulse: float = 0.5 + 0.5 * sin(_warning_pulse_timer)
		horde_warning.modulate.a = 0.45 + 0.55 * pulse
		horde_bar.scale = Vector2(1.0 + 0.04 * pulse, 1.0 + 0.08 * pulse)
	else:
		horde_bar.scale = Vector2.ONE

func setup_player(player: Player) -> void:
	if player:
		player.health_changed.connect(_on_health_changed)
		if player.shotgun:
			player.shotgun.ammo_changed.connect(_on_ammo_changed)
			player.shotgun.reload_started.connect(_on_reload_started)
			player.shotgun.reload_finished.connect(_on_reload_finished)

func _on_score_updated(new_score: int) -> void:
	score_label.text = "SCORE: %05d" % new_score
	score_label.pivot_offset = score_label.size * 0.5
	var tw: Tween = create_tween()
	score_label.scale = Vector2(1.08, 1.12)
	tw.tween_property(score_label, "scale", Vector2.ONE, 0.12)

func _on_distance_updated(dist: float) -> void:
	distance_label.text = "DIST: %dm" % int(dist)

func _on_combo_updated(combo_count: int, multiplier: int) -> void:
	if not _combo_label:
		return
	if multiplier <= 1 or combo_count < 2:
		_combo_label.visible = false
		return

	_combo_label.visible = true
	if multiplier >= 5:
		_combo_label.text = "🔥 x5 RAMPAGE! (%d KILLS)" % combo_count
		_combo_label.add_theme_color_override("font_color", Color(1.0, 0.32, 0.25, 1.0))
	elif multiplier >= 3:
		_combo_label.text = "⚡ x3 KILL STREAK! (%d)" % combo_count
		_combo_label.add_theme_color_override("font_color", Color(1.0, 0.62, 0.18, 1.0))
	else:
		_combo_label.text = "★ x2 COMBO!"
		_combo_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25, 1.0))

	_combo_label.scale = Vector2(1.35, 1.35)
	var tw: Tween = create_tween()
	tw.tween_property(_combo_label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_health_changed(hp: int, max_hp: int) -> void:
	hp_label.text = "HP: %d/%d" % [hp, max_hp]
	if _hp_pip_1:
		_hp_pip_1.texture = PIP_FULL_TEX if hp >= 1 else PIP_EMPTY_TEX
	if _hp_pip_2:
		_hp_pip_2.texture = PIP_FULL_TEX if hp >= 2 else PIP_EMPTY_TEX

	if hp == 1:
		hp_label.modulate = Color(1.0, 0.25, 0.25)
		_low_hp_danger = 0.55
		if _hp_pip_2:
			var tw: Tween = create_tween()
			_hp_pip_2.scale = Vector2(1.4, 1.4)
			tw.tween_property(_hp_pip_2, "scale", Vector2.ONE, 0.18)
	elif hp <= 0:
		hp_label.modulate = Color(0.6, 0.15, 0.15)
		_low_hp_danger = 0.85
	else:
		hp_label.modulate = Color.WHITE
		_low_hp_danger = 0.0

func _on_ammo_changed(current: int, _max_ammo: int) -> void:
	shell_1.modulate = Color.WHITE if current >= 1 else Color(0.25, 0.25, 0.3, 0.45)
	shell_2.modulate = Color.WHITE if current >= 2 else Color(0.25, 0.25, 0.3, 0.45)

func _on_reload_started(duration: float) -> void:
	_is_reloading = true
	_reload_duration = duration
	_reload_elapsed = 0.0
	reload_bar.visible = true
	reload_label.visible = true

func _on_reload_finished() -> void:
	_is_reloading = false
	reload_bar.visible = false
	reload_label.visible = false

func _on_horde_proximity_changed(proximity: float) -> void:
	_current_proximity = proximity
	horde_bar.value = proximity * 100.0
	if proximity > 0.65:
		horde_warning.visible = true
		horde_bar.modulate = Color(1.0, 0.15, 0.15) # Danger Red
	elif proximity > 0.35:
		horde_warning.visible = false
		horde_bar.modulate = Color(1.0, 0.85, 0.2) # Caution Yellow
	else:
		horde_warning.visible = false
		horde_bar.modulate = Color(0.2, 0.9, 0.3) # Safe Green
