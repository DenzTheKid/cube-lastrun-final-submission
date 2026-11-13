extends CanvasLayer
class_name HUD

# Gameplay HUD for CUBE: LAST RUN V1.1.
# Displays score, distance, survival timer, health hearts,
# two-shell ammunition with active reload gauge, and dynamic horde danger radar.

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

func _ready() -> void:
	if GameManager:
		GameManager.score_updated.connect(_on_score_updated)
		GameManager.distance_updated.connect(_on_distance_updated)
		GameManager.horde_proximity_changed.connect(_on_horde_proximity_changed)
	reload_bar.visible = false
	reload_label.visible = false
	horde_warning.visible = false

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
	if hp == 1:
		hp_label.modulate = Color(1.0, 0.25, 0.25)
	else:
		hp_label.modulate = Color.WHITE

func _on_ammo_changed(current: int, _max_ammo: int) -> void:
	# Shell 1
	shell_1.modulate = Color.WHITE if current >= 1 else Color(0.25, 0.25, 0.3, 0.45)
	# Shell 2
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
