extends CanvasLayer
class_name HUD

# Gameplay HUD for CUBE: LAST RUN.
# Uses the shared res://assets/ui/game_theme.tres Theme resource and ThemePalette
# while keeping all telemetry values, signals, and update rules unchanged.

const PIP_FULL_TEX: Texture2D = preload("res://assets/ui/px_heart_full.png")
const PIP_EMPTY_TEX: Texture2D = preload("res://assets/ui/px_heart_empty.png")
const SHELL_FULL_TEX: Texture2D = preload("res://assets/ui/px_shell_full.png")
const SHELL_EMPTY_TEX: Texture2D = preload("res://assets/ui/px_shell_empty.png")
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
@onready var _hp_pip_1: TextureRect = %Heart1
@onready var _hp_pip_2: TextureRect = %Heart2

var _is_reloading: bool = false
var _reload_duration: float = 0.80
var _reload_elapsed: float = 0.0
var _warning_pulse_timer: float = 0.0
var _last_hp: int = 2

func _ready() -> void:
	_set_mouse_filter_ignore(root_control)
	if GameManager:
		GameManager.score_updated.connect(_on_score_updated)
		GameManager.distance_updated.connect(_on_distance_updated)
		GameManager.horde_proximity_changed.connect(_on_horde_proximity_changed)
	if reload_box:
		reload_box.visible = false
	reload_bar.visible = false
	reload_label.visible = false
	horde_warning.visible = false

func _set_mouse_filter_ignore(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_ignore(child)

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
		_on_health_changed(player.current_hp, player.max_hp)
		if player.shotgun:
			player.shotgun.ammo_changed.connect(_on_ammo_changed)
			player.shotgun.reload_started.connect(_on_reload_started)
			player.shotgun.reload_finished.connect(_on_reload_finished)
			_on_ammo_changed(player.shotgun.current_ammo, player.shotgun.max_ammo)

func _on_score_updated(new_score: int) -> void:
	score_label.text = "SCORE: %05d" % new_score

func _on_distance_updated(dist: float) -> void:
	distance_label.text = "DIST: %dm" % int(dist)

func _on_health_changed(hp: int, max_hp: int) -> void:
	hp_label.text = "%d/%d" % [hp, max_hp]
	if _hp_pip_1:
		_hp_pip_1.texture = PIP_FULL_TEX if hp >= 1 else PIP_EMPTY_TEX
	if _hp_pip_2:
		_hp_pip_2.texture = PIP_FULL_TEX if hp >= 2 else PIP_EMPTY_TEX

	if hp < _last_hp and hp == 1 and _hp_pip_2:
		_hp_pip_2.pivot_offset = Vector2(10.0, 8.5)
		_hp_pip_2.scale = Vector2(1.35, 1.35)
		var tw: Tween = create_tween()
		tw.tween_property(_hp_pip_2, "scale", Vector2.ONE, 0.16)
	elif hp > _last_hp and _hp_pip_2:
		var pop_pip: TextureRect = _hp_pip_2 if hp >= 2 else _hp_pip_1
		if pop_pip:
			pop_pip.pivot_offset = Vector2(10.0, 8.5)
			pop_pip.scale = Vector2(1.38, 1.38)
			var tw_heal: Tween = create_tween()
			tw_heal.tween_property(pop_pip, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_last_hp = hp

	if hp == 1:
		hp_label.modulate = PALETTE.ACCENT_MAGENTA
	else:
		hp_label.modulate = Color.WHITE

func _on_ammo_changed(current: int, _max_ammo: int) -> void:
	if shell_1:
		shell_1.texture = SHELL_FULL_TEX if current >= 1 else SHELL_EMPTY_TEX
		shell_1.modulate = Color.WHITE
	if shell_2:
		shell_2.texture = SHELL_FULL_TEX if current >= 2 else SHELL_EMPTY_TEX
		shell_2.modulate = Color.WHITE

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
