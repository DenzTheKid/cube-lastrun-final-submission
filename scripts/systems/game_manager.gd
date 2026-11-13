extends Node

# Autoload: GameManager
# Global state, score, difficulty, and progression controller.

signal game_started
signal game_over(final_score: int, distance: float, survival_time: float, kills: int, is_new_record: bool)
signal score_updated(new_score: int)
signal distance_updated(distance_meters: float)
signal zombie_killed(total_kills: int)
signal horde_proximity_changed(proximity: float) # 0.0 (far) to 1.0 (caught)

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

var current_state: State = State.MENU

var score: int = 0
var distance: float = 0.0 # world units / 10 = meters
var survival_time: float = 0.0
var zombie_kills: int = 0
var high_score: int = 0
var max_distance: float = 0.0

# Difficulty multipliers
var difficulty_factor: float = 1.0 # starts at 1.0, increases smoothly over time
var base_player_speed: float = 170.0

const SAVE_PATH: String = "user://cube_lastrun_save.json"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game_data()

func _process(delta: float) -> void:
	if current_state == State.PLAYING:
		survival_time += delta
		# Difficulty increases slowly over distance and time
		difficulty_factor = 1.0 + (distance / 500.0) + (survival_time / 90.0)
		difficulty_factor = clampf(difficulty_factor, 1.0, 2.5)

func start_game() -> void:
	current_state = State.PLAYING
	score = 0
	distance = 0.0
	survival_time = 0.0
	zombie_kills = 0
	difficulty_factor = 1.0
	get_tree().paused = false
	game_started.emit()
	if AudioManager:
		AudioManager.play_music("gameplay")

func add_distance(amount: float) -> void:
	if current_state != State.PLAYING:
		return
	distance += amount
	score += int(amount * 0.5)
	distance_updated.emit(distance)
	score_updated.emit(score)

func add_kill(kill_score: int = 100) -> void:
	if current_state != State.PLAYING:
		return
	zombie_kills += 1
	score += kill_score
	zombie_killed.emit(zombie_kills)
	score_updated.emit(score)

func update_horde_proximity(proximity: float) -> void:
	if current_state == State.PLAYING:
		horde_proximity_changed.emit(proximity)

func trigger_game_over() -> void:
	if current_state == State.GAME_OVER:
		return
	current_state = State.GAME_OVER
	var is_new: bool = false
	if score > high_score:
		high_score = score
		is_new = true
	if distance > max_distance:
		max_distance = distance
	save_game_data()
	
	if AudioManager:
		AudioManager.stop_music()
		AudioManager.play_sfx("game_over")
		
	game_over.emit(score, distance, survival_time, zombie_kills, is_new)

func restart_game() -> void:
	start_game()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main/game_world.tscn")

func go_to_menu() -> void:
	current_state = State.MENU
	get_tree().paused = false
	if AudioManager:
		AudioManager.play_music("menu")
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main/main_menu.tscn")

func save_game_data() -> void:
	var data: Dictionary = {
		"high_score": high_score,
		"max_distance": max_distance
	}
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

func load_game_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var txt: String = f.get_as_text()
		f.close()
		var json: JSON = JSON.new()
		if json.parse(txt) == OK:
			var dict: Dictionary = json.data
			high_score = int(dict.get("high_score", 0))
			max_distance = float(dict.get("max_distance", 0.0))
