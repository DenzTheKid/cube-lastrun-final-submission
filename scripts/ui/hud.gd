extends CanvasLayer
class_name HUD

# Gameplay HUD for CUBE: LAST RUN.
# Uses the shared res://assets/ui/game_theme.tres Theme resource and ThemePalette
# while keeping all telemetry values, signals, and update rules unchanged.

const PIP_FULL_TEX: Texture2D = preload("res://assets/ui/hp_pip_full.png")
const PIP_EMPTY_TEX: Texture2D = preload("res://assets/ui/hp_pip_empty.png")
const PALETTE = preload("res://scripts/ui/theme_palette.gd")

@onready var root_control: Control = $RootControl
@onready var score_label: Label = %ScoreLabel
@onready var distance_label: Label = %DistanceLabel
@onready var time_label: Label = %TimeLabel
@onready var shell_1: TextureRect = %Shell1
@onready var shell_2: TextureRect = %Shell2
@onready var reload_box: VBoxContainer = $RootControl/BottomLeft/AmmoPlate/AmmoBox/ReloadBox
@onready var reload_bar: ProgressBar = %ReloadBar
@onready var reload_label: Label = %ReloadLabel
@onready var horde_bar: ProgressBar = %HordeBar
@onready var horde_warning: Label = %HordeWarning
@onready var hp_label: Label = %HpLabel

var _is_reloading: bool = false
var _reload_duration: float = 0.80
var _reload_elapsed: float = 0.0
var _warning_pulse_timer: float = 0.0

var _hp_pip_1: TextureRect = null
var _hp_pip_2: TextureRect = null

func _ready() -> void:
	_setup_hud_pips()

	if GameManager:
		GameManager.score_updated.connect(_on_score_updated)
		GameManager.distance_updated.connect(_on_distance_updated)
		GameManager.horde_proximity_changed.connect(_on_horde_proximity_changed)
	if reload_box:
		reload_box.visible = false
	reload_bar.visible = false
	reload_label.visible = false
	horde_warning.visible = false

func _setup_hud_pips() -> void:
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

func _process(delta: float) -> void:
	if GameManager and GameManager.current_state == GameManager.State.PLAYING:
		var t: int = int(GameManager.survival_time)
		var mins: int = int(t / 60.0)
		var secs: int = t % 60
		time_label.text = "TIME: %02d:%02d" % [mins, secs]

	if _is_reloading:
		_reload_elapsed += delta
		reload_bar.value = clampf((_reload_elapsed / _reload_duration) * 100.0, 0.0, 100.0)

	if horde_warning.visible:
		_warning_pulse_timer += delta * 6.0
		horde_warning.modulate.a = 0.5 + 0.5 * sin(_warning_pulse_timer)

func setup_player(player: Player) -> void:
	if player:
		player.health_changed.connect(_on_health_changed)
		if player.shotgun:
			player.shotgun.ammo_changed.connect(_on_ammo_changed)
			player.shotgun.reload_started.connect(_on_reload_started)
			player.shotgun.reload_finished.connect(_on_reload_finished)

func _on_score_updated(new_score: int) -> void:
	score_label.text = "SCORE: %05d" % new_score

func _on_distance_updated(dist: float) -> void:
	distance_label.text = "DIST: %dm" % int(dist)

func _on_health_changed(hp: int, max_hp: int) -> void:
	hp_label.text = "HP: %d/%d" % [hp, max_hp]
	if _hp_pip_1:
		_hp_pip_1.texture = PIP_FULL_TEX if hp >= 1 else PIP_EMPTY_TEX
	if _hp_pip_2:
		_hp_pip_2.texture = PIP_FULL_TEX if hp >= 2 else PIP_EMPTY_TEX

	if hp == 1:
		hp_label.modulate = PALETTE.ACCENT_MAGENTA
	else:
		hp_label.modulate = Color.WHITE

func _on_ammo_changed(current: int, _max_ammo: int) -> void:
	shell_1.modulate = Color.WHITE if current >= 1 else Color(0.25, 0.25, 0.3, 0.45)
	shell_2.modulate = Color.WHITE if current >= 2 else Color(0.25, 0.25, 0.3, 0.45)

func _on_reload_started(duration: float) -> void:
	_is_reloading = true
	_reload_duration = duration
	_reload_elapsed = 0.0
	if reload_box:
		reload_box.visible = true
	reload_bar.visible = true
	reload_label.visible = true

func _on_reload_finished() -> void:
	_is_reloading = false
	if reload_box:
		reload_box.visible = false
	reload_bar.visible = false
	reload_label.visible = false

func _on_horde_proximity_changed(proximity: float) -> void:
	horde_bar.value = proximity * 100.0
	if proximity > 0.65:
		horde_warning.visible = true
		horde_bar.modulate = PALETTE.ACCENT_MAGENTA
	elif proximity > 0.35:
		horde_warning.visible = false
		horde_bar.modulate = PALETTE.ACCENT_AMBER
	else:
		horde_warning.visible = false
		horde_bar.modulate = PALETTE.ACCENT_CYAN
