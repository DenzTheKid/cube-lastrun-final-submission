extends Node

# Autoload: AudioManager for CUBE: LAST RUN V1.1.
# Features:
# - Polyphonic 8-channel SFX voice pool with pitch modulation.
# - Anti-spam cooldown timers per sound effect.
# - Seamless music playback for gameplay and menu.
# - Independent linear-to-dB volume controls for SFX and Music.

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _current_music_name: String = ""
var _music_tween: Tween = null

var sfx_volume_db: float = 0.0
var music_volume_db: float = -6.0

# Cooldown tracking to prevent audio spam / cacophony
var _sfx_cooldowns: Dictionary = {}
const MIN_SFX_INTERVAL: float = 0.045

# Per-track mix trim so mastered BGM tracks sit cleanly beneath shotgun & zombie SFX
const MUSIC_TRACK_TRIM_DB: Dictionary = {
	"menu": -3.0,
	"gameplay": -4.0,
}

const SFX_STREAMS: Dictionary = {
	"jump": preload("res://assets/audio/sfx_jump.wav"),
	"land": preload("res://assets/audio/sfx_land.wav"),
	"shotgun": preload("res://assets/audio/sfx_shotgun.wav"),
	"recoil": preload("res://assets/audio/sfx_recoil.wav"),
	"empty": preload("res://assets/audio/sfx_empty.wav"),
	"reload": preload("res://assets/audio/sfx_reload.wav"),
	"shell_eject": preload("res://assets/audio/sfx_shell_eject.wav"),
	"zombie_hit": preload("res://assets/audio/sfx_zombie_hit.wav"),
	"zombie_death": preload("res://assets/audio/sfx_zombie_death.wav"),
	"player_hurt": preload("res://assets/audio/sfx_player_hurt.wav"),
	"heal": preload("res://assets/audio/sfx_heal.wav"),
	"game_over": preload("res://assets/audio/sfx_game_over.wav"),
	"ui_click": preload("res://assets/audio/sfx_ui_click.wav"),
	"shotgun_acoustic": preload("res://assets/audio/sfx_shotgun_acoustic.wav"),
	"impact_flesh": preload("res://assets/audio/sfx_impact_flesh.ogg"),
	"impact_metal": preload("res://assets/audio/sfx_impact_metal.ogg"),
}

const MUSIC_STREAMS: Dictionary = {
	"gameplay": preload("res://assets/audio/music_gameplay.ogg"),
	"menu": preload("res://assets/audio/music_menu.mp3"),
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = music_volume_db
	add_child(_music_player)

	# Pool of 8 SFX players for polyphony
	for i in range(8):
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
	if not SFX_STREAMS.has(sfx_name):
		return

	# Prevent duplicate sounds firing in rapid succession
	if _sfx_cooldowns.has(sfx_name):
		return
	_sfx_cooldowns[sfx_name] = MIN_SFX_INTERVAL

	var stream: AudioStream = SFX_STREAMS[sfx_name]
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

func play_music(music_name: String) -> void:
	if _current_music_name == music_name and _music_player.playing:
		return
	if not MUSIC_STREAMS.has(music_name):
		return
	_kill_music_tween()
	_current_music_name = music_name
	_music_player.stop()
	var stream: AudioStream = MUSIC_STREAMS[music_name]
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_music_player.stream = stream
	var target_db: float = _get_effective_music_db(music_name)
	if music_volume_db <= -79.0 or not is_inside_tree():
		_music_player.volume_db = target_db
		_music_player.play()
	else:
		_music_player.volume_db = minf(target_db - 18.0, -24.0)
		_music_player.play()
		_music_tween = create_tween()
		_music_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_music_tween.tween_property(_music_player, "volume_db", target_db, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func stop_music() -> void:
	_kill_music_tween()
	_current_music_name = ""
	_music_player.stop()

func set_sfx_volume(val_normalized: float) -> void:
	sfx_volume_db = -80.0 if val_normalized <= 0.001 else linear_to_db(clampf(val_normalized, 0.001, 1.0))
	for p in _sfx_players:
		p.volume_db = sfx_volume_db

func set_music_volume(val_normalized: float) -> void:
	_kill_music_tween()
	music_volume_db = -80.0 if val_normalized <= 0.001 else linear_to_db(clampf(val_normalized, 0.001, 1.0))
	_music_player.volume_db = _get_effective_music_db()
