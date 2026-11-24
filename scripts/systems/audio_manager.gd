extends Node

# Autoload: AudioManager for CUBE: LAST RUN V1.2.
# Features:
# - Polyphonic 12-channel SFX voice pool with pitch modulation and anti-spam cooldowns.
# - Dedicated ambient loop player for highway atmospheric audio.
# - Dynamic music playback with cross-fading & per-track mix trim (menu, gameplay run, horde rush, game over).
# - Independent linear-to-dB volume controls for SFX, Music, and Ambient.

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _current_music_name: String = ""
var _current_ambient_name: String = ""
var _music_tween: Tween = null
var _ambient_tween: Tween = null

var sfx_volume_db: float = 0.0
var music_volume_db: float = -6.0
var ambient_volume_db: float = -10.0

# Cooldown tracking to prevent audio spam / cacophony
var _sfx_cooldowns: Dictionary = {}
const MIN_SFX_INTERVAL: float = 0.040

# Per-track mix trim so mastered BGM tracks sit cleanly beneath shotgun & zombie SFX
const MUSIC_TRACK_TRIM_DB: Dictionary = {
	"menu": -3.0,
	"gameplay": -4.0,
	"horde": -3.0,
	"game_over": -2.0,
}

# Lazy-loaded audio caches to preserve memory footprint (< 60MB)
var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}
var _ambient_cache: Dictionary = {}

const SFX_PATHS: Dictionary = {
	# Core Gameplay & Combat
	"jump": "res://assets/audio/sfx_jump.wav",
	"land": "res://assets/audio/sfx_land.wav",
	"shotgun": "res://assets/audio/sfx_shotgun.wav",
	"shotgun_blast": "res://assets/audio/sfx/weapons/shotgun_blast_cc0.wav",
	"shotgun_punch": "res://assets/audio/sfx/weapons/shotgun_punch_cc0.wav",
	"shotgun_pump": "res://assets/audio/sfx/weapons/shotgun_pump_cc0.wav",
	"recoil": "res://assets/audio/sfx_recoil.wav",
	"empty": "res://assets/audio/sfx/weapons/dry_fire_click_cc0.wav",
	"reload": "res://assets/audio/sfx/weapons/shotgun_reload_cc0.wav",
	"shell_eject": "res://assets/audio/sfx/weapons/shell_casing_eject_cc0.wav",
	"shotgun_acoustic": "res://assets/audio/sfx_shotgun_acoustic.wav",

	# Impacts
	"impact_flesh": "res://assets/audio/sfx_impact_flesh.ogg",
	"impact_metal": "res://assets/audio/sfx_impact_metal.ogg",
	"impact_concrete": "res://assets/audio/sfx/weapons/bullet_impact_concrete_cc0.wav",
	"impact_flesh_wet": "res://assets/audio/sfx/weapons/bullet_impact_flesh_cc0.mp3",
	"barricade_hit": "res://assets/audio/sfx/environment/sfx_barricade_hit.wav",

	# Player Health, Shield & Movement
	"player_hurt": "res://assets/audio/sfx_player_hurt.wav",
	"heal": "res://assets/audio/sfx/player/sfx_player_heal.wav",
	"shield": "res://assets/audio/sfx/player/sfx_player_shield.wav",
	"footstep": "res://assets/audio/sfx/player/sfx_player_footstep.wav",
	"player_jump": "res://assets/audio/sfx/player/sfx_player_jump.wav",
	"player_land": "res://assets/audio/sfx/player/sfx_player_land.wav",

	# Enemy Reactions
	"zombie_hit": "res://assets/audio/sfx_zombie_hit.wav",
	"zombie_death": "res://assets/audio/sfx_zombie_death.wav",
	"zombie_walker_groan": "res://assets/audio/sfx/enemies/sfx_zombie_walker_groan_01.wav",
	"zombie_walker_idle": "res://assets/audio/sfx/enemies/sfx_zombie_walker_idle_01.wav",
	"zombie_runner_screech": "res://assets/audio/sfx/enemies/sfx_zombie_runner_screech_01.ogg",
	"mutant_screech": "res://assets/audio/sfx/enemies/sfx_zombie_mutant_screech_01.wav",
	"mutant_leap": "res://assets/audio/sfx/enemies/sfx_zombie_mutant_leap_01.wav",
	"brute_roar": "res://assets/audio/sfx/enemies/sfx_zombie_brute_roar_01.wav",
	"brute_tank": "res://assets/audio/sfx/enemies/sfx_zombie_brute_tank_01.wav",
	"zombie_squish": "res://assets/audio/sfx/enemies/sfx_zombie_flesh_squish_01.mp3",
	"zombie_death_splat": "res://assets/audio/sfx/enemies/sfx_zombie_death_splat_01.mp3",

	# UI & Presentation
	"ui_click": "res://assets/audio/sfx/ui/sfx_ui_click.wav",
	"ui_hover": "res://assets/audio/sfx/ui/sfx_ui_hover.wav",
	"ui_milestone": "res://assets/audio/sfx/ui/sfx_ui_milestone.wav",
	"ui_toggle": "res://assets/audio/sfx/ui/sfx_ui_toggle.wav",
	"game_over": "res://assets/audio/sfx_game_over.wav",
}

const MUSIC_PATHS: Dictionary = {
	"menu": "res://assets/audio/music/bgm_menu_dusk.ogg",
	"gameplay": "res://assets/audio/music/bgm_gameplay_run.ogg",
	"horde": "res://assets/audio/music/bgm_horde_intense.ogg",
	"game_over": "res://assets/audio/music/bgm_game_over.ogg",
	# Legacy fallbacks
	"menu_classic": "res://assets/audio/music_menu.mp3",
	"gameplay_classic": "res://assets/audio/music_gameplay.ogg",
}

const AMBIENT_PATHS: Dictionary = {
	"night_wind": "res://assets/audio/ambient/amb_night_highway_wind.ogg",
}

const SFX_STREAMS: Dictionary = SFX_PATHS
const MUSIC_STREAMS: Dictionary = MUSIC_PATHS
const AMBIENT_STREAMS: Dictionary = AMBIENT_PATHS

func _get_sfx_stream(sfx_name: String) -> AudioStream:
	if _sfx_cache.has(sfx_name):
		return _sfx_cache[sfx_name]
	if SFX_PATHS.has(sfx_name):
		var res = load(SFX_PATHS[sfx_name])
		if res is AudioStream:
			_sfx_cache[sfx_name] = res
			return res
	return null

func _get_music_stream(music_name: String) -> AudioStream:
	if _music_cache.has(music_name):
		return _music_cache[music_name]
	if MUSIC_PATHS.has(music_name):
		var res = load(MUSIC_PATHS[music_name])
		if res is AudioStream:
			_music_cache[music_name] = res
			return res
	return null

func _get_ambient_stream(ambient_name: String) -> AudioStream:
	if _ambient_cache.has(ambient_name):
		return _ambient_cache[ambient_name]
	if AMBIENT_PATHS.has(ambient_name):
		var res = load(AMBIENT_PATHS[ambient_name])
		if res is AudioStream:
			_ambient_cache[ambient_name] = res
			return res
	return null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = music_volume_db
	add_child(_music_player)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Master"
	_ambient_player.volume_db = ambient_volume_db
	add_child(_ambient_player)

	# Polyphonic pool of 12 SFX players
	for i in range(12):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = sfx_volume_db
		add_child(p)
		_sfx_players.append(p)

func _process(delta: float) -> void:
	# Decrement cooldown timers
	for k in _sfx_cooldowns.keys():
		_sfx_cooldowns[k] -= delta
		if _sfx_cooldowns[k] <= 0.0:
			_sfx_cooldowns.erase(k)

func play_sfx(sfx_name: String, pitch_range: float = 0.05) -> void:
	if not SFX_PATHS.has(sfx_name):
		return

	# Prevent duplicate sounds firing in rapid succession
	if _sfx_cooldowns.has(sfx_name):
		return
	_sfx_cooldowns[sfx_name] = MIN_SFX_INTERVAL

	var stream: AudioStream = _get_sfx_stream(sfx_name)
	if not stream:
		return

	for p in _sfx_players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
			p.volume_db = sfx_volume_db
			p.play()
			return

	# If all busy, reuse the first player
	var fallback: AudioStreamPlayer = _sfx_players[0]
	fallback.stream = stream
	fallback.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
	fallback.volume_db = sfx_volume_db
	fallback.play()

func _get_effective_music_db(music_name: String = "") -> float:
	if music_volume_db <= -79.0:
		return -80.0
	var key: String = _current_music_name if music_name.is_empty() else music_name
	var trim_db: float = float(MUSIC_TRACK_TRIM_DB.get(key, 0.0))
	return music_volume_db + trim_db

func _kill_music_tween() -> void:
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = null

func play_music(music_name: String, crossfade_time: float = 0.35) -> void:
	if _current_music_name == music_name and _music_player.playing:
		return
	if not MUSIC_PATHS.has(music_name):
		return

	var next_stream: AudioStream = _get_music_stream(music_name)
	if not next_stream:
		return

	var should_loop: bool = (music_name != "game_over")
	if next_stream is AudioStreamMP3:
		(next_stream as AudioStreamMP3).loop = should_loop
	elif next_stream is AudioStreamOggVorbis:
		(next_stream as AudioStreamOggVorbis).loop = should_loop

	_current_music_name = music_name
	var target_db: float = _get_effective_music_db(music_name)

	_kill_music_tween()

	# Fast switch or smooth crossfade
	if crossfade_time <= 0.05 or not _music_player.playing or music_volume_db <= -70.0 or not is_inside_tree():
		_music_player.stop()
		_music_player.stream = next_stream
		_music_player.volume_db = target_db
		_music_player.play()
		return

	_music_tween = create_tween()
	_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_tween.tween_property(_music_player, "volume_db", -40.0, crossfade_time * 0.5)
	_music_tween.tween_callback(func():
		if is_instance_valid(_music_player):
			_music_player.stop()
			_music_player.stream = next_stream
			_music_player.play()
	)
	_music_tween.tween_property(_music_player, "volume_db", target_db, crossfade_time * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func stop_music() -> void:
	_kill_music_tween()
	_current_music_name = ""
	_music_player.stop()

func play_ambient(ambient_name: String = "night_wind", fade_in_time: float = 1.0) -> void:
	if _current_ambient_name == ambient_name and _ambient_player.playing:
		return
	if not AMBIENT_PATHS.has(ambient_name):
		return

	var stream: AudioStream = _get_ambient_stream(ambient_name)
	if not stream:
		return

	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true

	_current_ambient_name = ambient_name
	_ambient_player.stream = stream

	if _ambient_tween and _ambient_tween.is_valid():
		_ambient_tween.kill()

	if fade_in_time > 0.1 and ambient_volume_db > -70.0 and is_inside_tree():
		_ambient_player.volume_db = -50.0
		_ambient_player.play()
		_ambient_tween = create_tween()
		_ambient_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_ambient_tween.tween_property(_ambient_player, "volume_db", ambient_volume_db, fade_in_time)
	else:
		_ambient_player.volume_db = ambient_volume_db
		_ambient_player.play()

func stop_ambient(fade_out_time: float = 0.5) -> void:
	_current_ambient_name = ""
	if _ambient_tween and _ambient_tween.is_valid():
		_ambient_tween.kill()
	if fade_out_time > 0.1 and _ambient_player.playing and is_inside_tree():
		_ambient_tween = create_tween()
		_ambient_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_ambient_tween.tween_property(_ambient_player, "volume_db", -50.0, fade_out_time)
		_ambient_tween.tween_callback(_ambient_player.stop)
	else:
		_ambient_player.stop()

func set_sfx_volume(val_normalized: float) -> void:
	sfx_volume_db = -80.0 if val_normalized <= 0.001 else linear_to_db(clampf(val_normalized, 0.001, 1.0))
	for p in _sfx_players:
		p.volume_db = sfx_volume_db

func set_music_volume(val_normalized: float) -> void:
	_kill_music_tween()
	music_volume_db = -80.0 if val_normalized <= 0.001 else linear_to_db(clampf(val_normalized, 0.001, 1.0))
	_music_player.volume_db = _get_effective_music_db()

func set_ambient_volume(val_normalized: float) -> void:
	ambient_volume_db = -80.0 if val_normalized <= 0.001 else linear_to_db(clampf(val_normalized, 0.001, 1.0))
	_ambient_player.volume_db = ambient_volume_db
