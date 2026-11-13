extends Node

# Autoload: AudioManager
# Handles SFX and music playback across the game.

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _current_music_name: String = ""

var sfx_volume_db: float = 0.0
var music_volume_db: float = -6.0

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
	"game_over": preload("res://assets/audio/sfx_game_over.wav"),
	"ui_click": preload("res://assets/audio/sfx_ui_click.wav"),
}

const MUSIC_STREAMS: Dictionary = {
	"gameplay": preload("res://assets/audio/music_gameplay.wav"),
	"menu": preload("res://assets/audio/music_menu.wav"),
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

func play_sfx(sfx_name: String, pitch_range: float = 0.05) -> void:
	if not SFX_STREAMS.has(sfx_name):
		return
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

func play_music(music_name: String) -> void:
	if _current_music_name == music_name and _music_player.playing:
		return
	if not MUSIC_STREAMS.has(music_name):
		return
	_current_music_name = music_name
	_music_player.stop()
	_music_player.stream = MUSIC_STREAMS[music_name]
	_music_player.volume_db = music_volume_db
	_music_player.play()

func stop_music() -> void:
	_current_music_name = ""
	_music_player.stop()

func set_sfx_volume(val_normalized: float) -> void:
	sfx_volume_db = linear_to_db(clampf(val_normalized, 0.001, 1.0))
	for p in _sfx_players:
		p.volume_db = sfx_volume_db

func set_music_volume(val_normalized: float) -> void:
	music_volume_db = linear_to_db(clampf(val_normalized, 0.001, 1.0))
	_music_player.volume_db = music_volume_db
