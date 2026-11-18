extends CanvasLayer
class_name HUD

# Gameplay HUD for CUBE: LAST RUN.
# Uses the shared res://assets/ui/game_theme.tres Theme resource and ThemePalette
# while keeping all telemetry values, signals, and update rules unchanged.

const PIP_FULL_TEX: Texture2D = preload("res://assets/ui/px_heart_full.png")
const PIP_EMPTY_TEX: Texture2D = preload("res://assets/ui/px_heart_empty.png")
const SHIELD_FULL_TEX: Texture2D = preload("res://assets/ui/px_shield_full.png")
const SHIELD_EMPTY_TEX: Texture2D = preload("res://assets/ui/px_shield_empty.png")
const SHELL_FULL_TEX: Texture2D = preload("res://assets/ui/px_shell_full.png")
const SHELL_EMPTY_TEX: Texture2D = preload("res://assets/ui/px_shell_empty.png")
const PALETTE = preload("res://scripts/ui/theme_palette.gd")

@onready var root_control: Control = $RootControl
@onready var safe_frame: Control = %SafeFrame
@onready var top_margin: MarginContainer = %TopMargin
@onready var bottom_margin: MarginContainer = %BottomMargin
@onready var score_label: Label = %ScoreLabel
@onready var distance_label: Label = %DistanceLabel
@onready var time_label: Label = %TimeLabel
@onready var shell_1: TextureRect = %Shell1
@onready var shell_2: TextureRect = %Shell2
@onready var reload_box: VBoxContainer = %ReloadBox
@onready var reload_bar: ProgressBar = %ReloadBar
@onready var reload_label: Label = %ReloadLabel
@onready var horde_bar: ProgressBar = %HordeBar
@onready var horde_warning: Label = %HordeWarning
@onready var hp_label: Label = %HpLabel
@onready var _hp_pip_1: TextureRect = %Heart1
@onready var _hp_pip_2: TextureRect = %Heart2
@onready var _shield_icon: TextureRect = %ShieldIcon
@onready var combo_plate: PanelContainer = %ComboPlate
@onready var combo_label: Label = %ComboLabel
@onready var critical_vignette: ColorRect = %CriticalVignette
@onready var milestone_banner: CenterContainer = %MilestoneBanner
@onready var milestone_panel: PanelContainer = %MilestonePanel
@onready var milestone_title: Label = %MilestoneTitle
@onready var milestone_sub: Label = %MilestoneSub

const ZONE_MILESTONES: Array[Dictionary] = [
	{ "dist": 250, "title": "ZONE 2: DOWNTOWN", "sub": "250m MILESTONE", "color": Color(0.28, 0.94, 0.42) },
	{ "dist": 500, "title": "ZONE 3: INDUSTRIAL", "sub": "500m MILESTONE", "color": Color(1.0, 0.80, 0.24) },
	{ "dist": 1000, "title": "ZONE 4: QUARANTINE", "sub": "1000m MILESTONE", "color": Color(0.84, 0.40, 1.0) },
	{ "dist": 1500, "title": "ZONE 5: DEAD HIGHWAY", "sub": "1500m MILESTONE", "color": Color(0.22, 0.96, 1.0) },
	{ "dist": 2000, "title": "ZONE 6: ENDLESS NIGHT", "sub": "2000m SURVIVOR", "color": Color(1.0, 0.44, 0.48) }
]

var _player: Player = null
var _game_manager: Object = null
var _is_reloading: bool = false
var _reload_duration: float = 0.80
var _reload_elapsed: float = 0.0
var _warning_pulse_timer: float = 0.0
var _critical_pulse_timer: float = 0.0
var _is_low_hp: bool = false
var _last_hp: int = 2
var _has_shield: bool = false
var _last_shield: int = 0
var _combo_tween: Tween = null
var _milestone_tween: Tween = null
var _milestone_style: StyleBoxFlat = null
var _banner_queue: Array[Dictionary] = []
var _banner_active: bool = false
var _next_zone_idx: int = 0
var _next_repeat_dist: int = 2500
var _record_announced: bool = false
var _record_baseline_dist: float = 0.0
var _last_unlock_check_dist: float = 0.0
var _last_unlock_check_score: int = 0
var _last_unlock_check_combo: int = 0
var _last_vp_size: Vector2 = Vector2.ZERO
var _last_win_size: Vector2i = Vector2i.ZERO
var _last_fullscreen: bool = false
var _last_displayed_dist: int = -1
var _last_displayed_score: int = -1

func _enter_tree() -> void:
	_connect_viewport_signals()

func _exit_tree() -> void:
	if _milestone_tween and _milestone_tween.is_valid():
		_milestone_tween.kill()
	if _combo_tween and _combo_tween.is_valid():
		_combo_tween.kill()
	_banner_queue.clear()
	_banner_active = false
	_disconnect_viewport_signals()
	_disconnect_game_manager_signals()
	_disconnect_player_signals()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_update_responsive_layout()

func _ready() -> void:
	_set_mouse_filter_ignore(root_control)
	_connect_viewport_signals()
	_update_responsive_layout()
	_setup_milestone_style()
	_connect_game_manager_signals()
	_reset_run_milestones()
	if reload_box:
		reload_box.visible = false
	reload_bar.visible = false
	reload_label.visible = false
	horde_warning.visible = false
	if combo_plate:
		combo_plate.visible = false
	if critical_vignette:
		critical_vignette.visible = false

func _connect_viewport_signals() -> void:
	var vp: Viewport = get_viewport()
	if vp and not vp.size_changed.is_connected(_update_responsive_layout):
		vp.size_changed.connect(_update_responsive_layout)

func _disconnect_viewport_signals() -> void:
	var vp: Viewport = get_viewport()
	if vp and vp.size_changed.is_connected(_update_responsive_layout):
		vp.size_changed.disconnect(_update_responsive_layout)

func _connect_game_manager_signals() -> void:
	if has_node("/root/GameManager"):
		_game_manager = get_node("/root/GameManager")
		if not _game_manager.score_updated.is_connected(_on_score_updated):
			_game_manager.score_updated.connect(_on_score_updated)
		if not _game_manager.distance_updated.is_connected(_on_distance_updated):
			_game_manager.distance_updated.connect(_on_distance_updated)
		if not _game_manager.horde_proximity_changed.is_connected(_on_horde_proximity_changed):
			_game_manager.horde_proximity_changed.connect(_on_horde_proximity_changed)
		if not _game_manager.combo_updated.is_connected(_on_combo_updated):
			_game_manager.combo_updated.connect(_on_combo_updated)
		if not _game_manager.game_started.is_connected(_reset_run_milestones):
			_game_manager.game_started.connect(_reset_run_milestones)
		if not _game_manager.game_over.is_connected(_on_game_over_hide_banner):
			_game_manager.game_over.connect(_on_game_over_hide_banner)

func _disconnect_game_manager_signals() -> void:
	if _game_manager and is_instance_valid(_game_manager):
		if _game_manager.score_updated.is_connected(_on_score_updated):
			_game_manager.score_updated.disconnect(_on_score_updated)
		if _game_manager.distance_updated.is_connected(_on_distance_updated):
			_game_manager.distance_updated.disconnect(_on_distance_updated)
		if _game_manager.horde_proximity_changed.is_connected(_on_horde_proximity_changed):
			_game_manager.horde_proximity_changed.disconnect(_on_horde_proximity_changed)
		if _game_manager.combo_updated.is_connected(_on_combo_updated):
			_game_manager.combo_updated.disconnect(_on_combo_updated)
		if _game_manager.game_started.is_connected(_reset_run_milestones):
			_game_manager.game_started.disconnect(_reset_run_milestones)
		if _game_manager.game_over.is_connected(_on_game_over_hide_banner):
			_game_manager.game_over.disconnect(_on_game_over_hide_banner)

func _disconnect_player_signals() -> void:
	if _player and is_instance_valid(_player):
		if _player.health_changed.is_connected(_on_health_changed):
			_player.health_changed.disconnect(_on_health_changed)
		if _player.shield_changed.is_connected(_on_shield_changed):
			_player.shield_changed.disconnect(_on_shield_changed)
		if _player.shotgun and is_instance_valid(_player.shotgun):
			if _player.shotgun.ammo_changed.is_connected(_on_ammo_changed):
				_player.shotgun.ammo_changed.disconnect(_on_ammo_changed)
			if _player.shotgun.reload_started.is_connected(_on_reload_started):
				_player.shotgun.reload_started.disconnect(_on_reload_started)
			if _player.shotgun.reload_finished.is_connected(_on_reload_finished):
				_player.shotgun.reload_finished.disconnect(_on_reload_finished)

func _update_responsive_layout() -> void:
	if not is_instance_valid(safe_frame) or not is_instance_valid(root_control):
		return

	var vp: Viewport = get_viewport()
	if not vp:
		return

	var vp_size: Vector2 = vp.get_visible_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return

	# Retrieve exact window size and mode across windowed, maximized, and fullscreen states
	var win: Window = get_window()
	var win_size: Vector2i = Vector2i.ZERO
	var is_fullscreen: bool = false
	if win:
		win_size = win.size
		is_fullscreen = (
			win.mode == Window.MODE_FULLSCREEN
			or win.mode == Window.MODE_EXCLUSIVE_FULLSCREEN
		)
	else:
		win_size = DisplayServer.window_get_size()
		var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
		is_fullscreen = (
			mode == DisplayServer.WINDOW_MODE_FULLSCREEN
			or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		)

	if win_size.x <= 0 or win_size.y <= 0:
		win_size = Vector2i(int(roundf(vp_size.x * 2.0)), int(roundf(vp_size.y * 2.0)))

	if vp_size == _last_vp_size and win_size == _last_win_size and is_fullscreen == _last_fullscreen:
		return
	_last_vp_size = vp_size
	_last_win_size = win_size
	_last_fullscreen = is_fullscreen

	# 1. Base 16:9 focal dimensions constraint (SafeFrame architecture)
	var target_aspect: float = 16.0 / 9.0
	var current_aspect: float = vp_size.x / maxf(vp_size.y, 1.0)

	var focal_w: float = vp_size.x
	var focal_h: float = vp_size.y

	if current_aspect > target_aspect:
		# Wider than 16:9 (e.g. 21:9 ultrawide) -> clamp focal width to 16:9
		focal_w = vp_size.y * target_aspect
	elif current_aspect < target_aspect:
		# Taller than 16:9 (e.g. 16:10 like 1920x1200 or 4:3) -> clamp focal height to 16:9
		focal_h = vp_size.x / target_aspect

	var origin_y: float = (vp_size.y - focal_h) * 0.5
	var origin_x: float = (vp_size.x - focal_w) * 0.5

	# 2. Responsive horizontal padding based on window size & fullscreen state
	# Small window (960x540): compact pad_x (12px).
	# Fullscreen & high resolutions (1080p, 1200p, 1440p): pad_x scales smoothly
	# so HUD elements stay in the player's focal vision rather than drifting to outer bezels.
	var scale_factor: float = clampf(float(win_size.x) / 960.0, 1.0, 2.67)
	var base_pad: float = lerpf(12.0, 32.0, clampf((scale_factor - 1.0) / 1.0, 0.0, 1.0))
	if is_fullscreen:
		base_pad = maxf(base_pad, 30.0)

	# 3. Crisp pixel art integer snapping (avoid subpixel jitter, blurry fonts, and 1px edge bleeding)
	base_pad = roundf(base_pad)
	origin_x = roundf(origin_x)
	origin_y = roundf(origin_y)
	focal_w = roundf(focal_w)
	focal_h = roundf(focal_h)

	# Clamp padding to guarantee minimum comfortable width for HUD elements (avoid overlap in extreme aspect ratios)
	var max_allowed_pad: float = floorf((focal_w - 340.0) * 0.5)
	if max_allowed_pad > 12.0:
		base_pad = clampf(base_pad, 12.0, max_allowed_pad)

	var target_pos: Vector2 = Vector2(origin_x + base_pad, origin_y)
	var target_size: Vector2 = Vector2(focal_w - (base_pad * 2.0), focal_h)

	safe_frame.position = target_pos
	safe_frame.size = target_size

func _set_mouse_filter_ignore(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_filter_ignore(child)

func _process(delta: float) -> void:
	if _game_manager and _game_manager.current_state == _game_manager.State.PLAYING:
		var t: int = int(_game_manager.survival_time)
		var mins: int = int(t / 60.0)
		var secs: int = t % 60
		time_label.text = "TIME: %02d:%02d" % [mins, secs]

	if _is_reloading:
		_reload_elapsed += delta
		reload_bar.value = clampf((_reload_elapsed / _reload_duration) * 100.0, 0.0, 100.0)

	if horde_warning.visible:
		_warning_pulse_timer += delta * 6.0
		horde_warning.modulate.a = 0.5 + 0.5 * sin(_warning_pulse_timer)

	if _is_low_hp:
		_critical_pulse_timer += delta * 4.4
		var beat: float = 0.5 + 0.5 * sin(_critical_pulse_timer)
		if critical_vignette and critical_vignette.material is ShaderMaterial:
			var smat := critical_vignette.material as ShaderMaterial
			smat.set_shader_parameter("pulse_alpha", lerpf(0.22, 0.44, beat))
		if _hp_pip_1:
			_hp_pip_1.pivot_offset = Vector2(10.0, 8.5)
			var pip_s: float = 1.0 + 0.14 * pow(beat, 2.0)
			_hp_pip_1.scale = Vector2(pip_s, pip_s)
		if hp_label:
			hp_label.modulate = PALETTE.ACCENT_MAGENTA.lerp(Color(1.0, 0.52, 0.62, 1.0), beat * 0.65)

	if _has_shield and _shield_icon and is_instance_valid(_player):
		if _player.shield_time_left <= 2.0:
			var warn_pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.024)
			_shield_icon.modulate.a = 0.35 + 0.65 * warn_pulse
		else:
			_shield_icon.modulate.a = 1.0

func setup_player(player: Player) -> void:
	_disconnect_player_signals()
	_player = player
	if _player:
		if not _player.health_changed.is_connected(_on_health_changed):
			_player.health_changed.connect(_on_health_changed)
		if not _player.shield_changed.is_connected(_on_shield_changed):
			_player.shield_changed.connect(_on_shield_changed)
		_on_health_changed(_player.current_hp, _player.max_hp)
		_on_shield_changed(_player.shield_hp, _player.max_shield)
		if _player.shotgun:
			if not _player.shotgun.ammo_changed.is_connected(_on_ammo_changed):
				_player.shotgun.ammo_changed.connect(_on_ammo_changed)
			if not _player.shotgun.reload_started.is_connected(_on_reload_started):
				_player.shotgun.reload_started.connect(_on_reload_started)
			if not _player.shotgun.reload_finished.is_connected(_on_reload_finished):
				_player.shotgun.reload_finished.connect(_on_reload_finished)
			_on_ammo_changed(_player.shotgun.current_ammo, _player.shotgun.max_ammo)

func _setup_milestone_style() -> void:
	if not milestone_panel:
		return
	_milestone_style = StyleBoxFlat.new()
	_milestone_style.bg_color = Color(0.05, 0.07, 0.14, 0.90)
	_milestone_style.border_color = Color(1.0, 0.82, 0.25, 1.0)
	_milestone_style.set_border_width_all(2)
	_milestone_style.set_corner_radius_all(2)
	_milestone_style.content_margin_left = 12
	_milestone_style.content_margin_right = 12
	_milestone_style.content_margin_top = 4
	_milestone_style.content_margin_bottom = 4
	milestone_panel.add_theme_stylebox_override("panel", _milestone_style)

func _reset_run_milestones() -> void:
	_next_zone_idx = 0
	_next_repeat_dist = 2500
	_record_announced = false
	_banner_queue.clear()
	_banner_active = false
	if _milestone_tween and _milestone_tween.is_valid():
		_milestone_tween.kill()
	if milestone_banner:
		milestone_banner.visible = false
	if GameManager:
		_record_baseline_dist = GameManager.run_start_max_distance
		_last_unlock_check_dist = GameManager.run_start_max_distance
		_last_unlock_check_score = GameManager.run_start_high_score
		_last_unlock_check_combo = GameManager.run_start_best_combo

func _on_game_over_hide_banner(_s: int, _d: float, _t: float, _k: int, _n: bool) -> void:
	_banner_queue.clear()
	_banner_active = false
	if _milestone_tween and _milestone_tween.is_valid():
		_milestone_tween.kill()
	if milestone_banner:
		milestone_banner.visible = false

func _on_score_updated(new_score: int) -> void:
	if new_score != _last_displayed_score:
		_last_displayed_score = new_score
		score_label.text = "SCORE: %05d" % new_score
	if GameManager and GameManager.current_state == GameManager.State.PLAYING:
		_check_skin_unlock_banners(GameManager.distance, new_score, GameManager.best_combo)

func _on_distance_updated(dist: float) -> void:
	var cur_dist_int: int = int(dist)
	if cur_dist_int != _last_displayed_dist:
		_last_displayed_dist = cur_dist_int
		distance_label.text = "DIST: %dm" % cur_dist_int
	if not GameManager or GameManager.current_state != GameManager.State.PLAYING:
		return

	var crossed_skin_ids: Array[String] = GameManager.get_newly_unlocked_skins(
		_last_unlock_check_dist,
		_last_unlock_check_score,
		maxf(_record_baseline_dist, dist),
		maxi(GameManager.run_start_high_score, GameManager.score)
	)
	_last_unlock_check_dist = maxf(_last_unlock_check_dist, maxf(_record_baseline_dist, dist))
	_last_unlock_check_score = maxi(_last_unlock_check_score, maxi(GameManager.run_start_high_score, GameManager.score))

	# Advance crossed zone milestones; keep latest if jumped far in one step
	var zone_entry: Dictionary = {}
	while _next_zone_idx < ZONE_MILESTONES.size() and dist >= float(ZONE_MILESTONES[_next_zone_idx]["dist"]):
		zone_entry = ZONE_MILESTONES[_next_zone_idx].duplicate()
		_next_zone_idx += 1
	while _next_zone_idx >= ZONE_MILESTONES.size() and dist >= float(_next_repeat_dist):
		zone_entry = {
			"dist": _next_repeat_dist,
			"title": "%dm SURVIVED!" % _next_repeat_dist,
			"sub": "UNSTOPPABLE RUN",
			"color": Color(1.0, 0.78, 0.30)
		}
		_next_repeat_dist += 500

	if not zone_entry.is_empty():
		var sub_txt: String = str(zone_entry["sub"])
		if not crossed_skin_ids.is_empty():
			var first_skin: Dictionary = GameManager.get_skin_data(crossed_skin_ids[0])
			sub_txt = "%s  |  UNLOCKED: %s" % [sub_txt, str(first_skin.get("name", ""))]
			crossed_skin_ids.remove_at(0)
		_queue_milestone_banner(str(zone_entry["title"]), sub_txt, zone_entry["color"])

	for sid in crossed_skin_ids:
		var sdata: Dictionary = GameManager.get_skin_data(sid)
		_queue_milestone_banner(
			"SKIN UNLOCKED!",
			str(sdata.get("name", "")),
			sdata.get("light", Color(1.0, 0.85, 0.30))
		)

	if not _record_announced and _record_baseline_dist >= 25.0 and dist > _record_baseline_dist:
		_record_announced = true
		_queue_milestone_banner("NEW DISTANCE RECORD!", "PREVIOUS BEST: %dm" % int(_record_baseline_dist), Color(1.0, 0.84, 0.24))

func _check_skin_unlock_banners(dist: float, scr: int, combo: int = 0) -> void:
	if not GameManager:
		return
	var cur_d: float = maxf(_record_baseline_dist, dist)
	var cur_s: int = maxi(GameManager.run_start_high_score, scr)
	var cur_c: int = maxi(GameManager.run_start_best_combo, combo)
	var newly_cubes: Array[String] = GameManager.get_newly_unlocked_skins(_last_unlock_check_dist, _last_unlock_check_score, cur_d, cur_s)
	var newly_guns: Array[String] = GameManager.get_newly_unlocked_weapon_skins(_last_unlock_check_combo, _last_unlock_check_score, cur_c, cur_s)
	_last_unlock_check_dist = maxf(_last_unlock_check_dist, cur_d)
	_last_unlock_check_score = maxi(_last_unlock_check_score, cur_s)
	_last_unlock_check_combo = maxi(_last_unlock_check_combo, cur_c)
	for sid in newly_cubes:
		var sdata: Dictionary = GameManager.get_skin_data(sid)
		_queue_milestone_banner(
			"SKIN UNLOCKED!",
			str(sdata.get("name", "")),
			sdata.get("light", Color(1.0, 0.85, 0.30))
		)
	for wid in newly_guns:
		var wdata: Dictionary = GameManager.get_weapon_skin_data(wid)
		_queue_milestone_banner(
			"GUN SKIN UNLOCKED!",
			str(wdata.get("name", "")),
			wdata.get("accent", Color(1.0, 0.85, 0.30))
		)

func _queue_milestone_banner(title: String, sub: String, accent: Color) -> void:
	if _banner_queue.size() >= 3:
		_banner_queue.remove_at(0)
	_banner_queue.append({ "title": title, "sub": sub, "color": accent })
	if not _banner_active:
		_play_next_milestone_banner()

func _play_next_milestone_banner() -> void:
	if not is_instance_valid(milestone_banner) or not is_instance_valid(milestone_panel):
		_banner_active = false
		return
	if _banner_queue.is_empty():
		_banner_active = false
		milestone_banner.visible = false
		return

	_banner_active = true
	var item: Dictionary = _banner_queue.pop_front()
	var accent: Color = item.get("color", Color(1.0, 0.82, 0.25))
	milestone_title.text = str(item.get("title", ""))
	milestone_sub.text = str(item.get("sub", ""))
	milestone_title.add_theme_color_override("font_color", accent)
	if _milestone_style:
		_milestone_style.border_color = accent

	if AudioManager:
		AudioManager.play_sfx("heal", 0.08)

	milestone_banner.visible = true
	milestone_banner.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var sz: Vector2 = milestone_panel.get_combined_minimum_size()
	milestone_panel.pivot_offset = sz * 0.5
	milestone_panel.scale = Vector2(0.86, 0.86)

	if _milestone_tween and _milestone_tween.is_valid():
		_milestone_tween.kill()
	_milestone_tween = create_tween()
	_milestone_tween.set_parallel(true)
	_milestone_tween.tween_property(milestone_banner, "modulate:a", 1.0, 0.18)
	_milestone_tween.tween_property(milestone_panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_milestone_tween.set_parallel(false)
	_milestone_tween.tween_interval(2.2)
	_milestone_tween.tween_property(milestone_banner, "modulate:a", 0.0, 0.30)
	_milestone_tween.tween_callback(func():
		milestone_banner.visible = false
		_play_next_milestone_banner()
	)

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

	_is_low_hp = (hp == 1)
	if critical_vignette:
		critical_vignette.visible = _is_low_hp
		if not _is_low_hp and critical_vignette.material is ShaderMaterial:
			(critical_vignette.material as ShaderMaterial).set_shader_parameter("pulse_alpha", 0.0)
	if not _is_low_hp and _hp_pip_1:
		_hp_pip_1.scale = Vector2.ONE

	if _is_low_hp:
		_critical_pulse_timer = PI * 0.5
		hp_label.modulate = PALETTE.ACCENT_MAGENTA
	else:
		hp_label.modulate = Color.WHITE

func _on_shield_changed(shield_hp: int, _max_shield: int) -> void:
	_has_shield = shield_hp > 0
	if not _shield_icon:
		return
	_shield_icon.texture = SHIELD_FULL_TEX if _has_shield else SHIELD_EMPTY_TEX
	_shield_icon.modulate = Color.WHITE if _has_shield else Color(0.75, 0.82, 0.94, 0.55)
	if shield_hp != _last_shield:
		_shield_icon.pivot_offset = Vector2(8.5, 8.5)
		_shield_icon.scale = Vector2(1.40, 1.40)
		var tw_sh: Tween = create_tween()
		tw_sh.tween_property(_shield_icon, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_last_shield = shield_hp

func _on_combo_updated(combo_count: int, multiplier: int) -> void:
	if GameManager and GameManager.current_state == GameManager.State.PLAYING:
		_check_skin_unlock_banners(GameManager.distance, GameManager.score, GameManager.best_combo)
	if not combo_plate or not combo_label:
		return
	if combo_count < 2:
		combo_plate.visible = false
		return

	combo_plate.visible = true
	combo_label.text = "COMBO x%d  (%d HIT)" % [multiplier, combo_count]
	if multiplier >= 5:
		combo_label.modulate = Color(1.0, 0.45, 0.60, 1.0)
	elif multiplier >= 3:
		combo_label.modulate = Color(0.96, 0.60, 0.30, 1.0)
	else:
		combo_label.modulate = Color(0.96, 0.84, 0.45, 1.0)

	var sz: Vector2 = combo_plate.get_combined_minimum_size() if combo_plate.size.x < 1.0 else combo_plate.size
	combo_plate.pivot_offset = sz * 0.5
	combo_plate.scale = Vector2(1.18, 1.18)
	if _combo_tween and _combo_tween.is_valid():
		_combo_tween.kill()
	_combo_tween = create_tween()
	_combo_tween.tween_property(combo_plate, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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
