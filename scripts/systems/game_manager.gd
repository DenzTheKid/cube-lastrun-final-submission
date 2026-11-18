extends Node

# Autoload: GameManager
# Global state, score, difficulty, and progression controller.

signal game_started
signal game_over(final_score: int, distance: float, survival_time: float, kills: int, is_new_record: bool)
signal score_updated(new_score: int)
signal distance_updated(distance_meters: float)
signal zombie_killed(total_kills: int)
signal combo_updated(combo_count: int, multiplier: int)
signal horde_proximity_changed(proximity: float) # 0.0 (far) to 1.0 (caught)
signal skin_changed(skin_id: String)
signal weapon_skin_changed(weapon_id: String)

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

var current_state: State = State.MENU

var score: int = 0
var distance: float = 0.0 # world units / 10 = meters
var survival_time: float = 0.0
var zombie_kills: int = 0
var combo_count: int = 0
var combo_multiplier: int = 1
var combo_timer: float = 0.0
var best_combo: int = 0
const COMBO_WINDOW: float = 3.2
var high_score: int = 0
var max_distance: float = 0.0
var all_time_best_combo: int = 0
var selected_skin: String = "crimson"
var selected_weapon_skin: String = "classic"

var run_start_high_score: int = 0
var run_start_max_distance: float = 0.0
var run_start_best_combo: int = 0
var last_run_new_distance_record: bool = false
var last_run_new_combo_record: bool = false
var last_run_unlocked_skins: Array[String] = []
var last_run_unlocked_weapons: Array[String] = []

const WEAPON_SKIN_ORDER: Array[String] = ["classic", "crimson", "toxic", "gold", "plasma"]
const WEAPON_SKIN_CATALOG: Dictionary = {
	"classic": {
		"id": "classic",
		"name": "CLASSIC STEEL",
		"unlock_combo": 0,
		"unlock_score": 0,
		"tex": "res://assets/weapons/shotgun.png",
		"overlay": "",
		"accent": Color(0.95, 0.72, 0.36),
		"tracer": Color(1.0, 0.85, 0.42),
		"light": Color(1.0, 0.72, 0.28)
	},
	"crimson": {
		"id": "crimson",
		"name": "CRIMSON OPS",
		"unlock_combo": 3,
		"unlock_score": 1200,
		"tex": "res://assets/weapons/shotgun_crimson.png",
		"overlay": "res://assets/ui/px_hero_gun_crimson.png",
		"accent": Color(0.98, 0.36, 0.48),
		"tracer": Color(1.0, 0.30, 0.42),
		"light": Color(1.0, 0.36, 0.46)
	},
	"toxic": {
		"id": "toxic",
		"name": "VENOM BIO",
		"unlock_combo": 5,
		"unlock_score": 3000,
		"tex": "res://assets/weapons/shotgun_toxic.png",
		"overlay": "res://assets/ui/px_hero_gun_toxic.png",
		"accent": Color(0.56, 0.96, 0.32),
		"tracer": Color(0.48, 1.0, 0.32),
		"light": Color(0.50, 1.0, 0.36)
	},
	"gold": {
		"id": "gold",
		"name": "ROYAL GOLD",
		"unlock_combo": 8,
		"unlock_score": 6000,
		"tex": "res://assets/weapons/shotgun_gold.png",
		"overlay": "res://assets/ui/px_hero_gun_gold.png",
		"accent": Color(1.0, 0.88, 0.38),
		"tracer": Color(1.0, 0.90, 0.36),
		"light": Color(1.0, 0.82, 0.28)
	},
	"plasma": {
		"id": "plasma",
		"name": "CYBER PLASMA",
		"unlock_combo": 10,
		"unlock_score": 10000,
		"tex": "res://assets/weapons/shotgun_plasma.png",
		"overlay": "res://assets/ui/px_hero_gun_plasma.png",
		"accent": Color(0.38, 0.94, 1.0),
		"tracer": Color(0.32, 0.96, 1.0),
		"light": Color(0.34, 0.95, 1.0)
	}
}

const SKIN_ORDER: Array[String] = ["crimson", "emerald", "gold", "violet", "cyan"]
const SKIN_CATALOG: Dictionary = {
	"crimson": {
		"id": "crimson",
		"name": "RED BAND",
		"tag": "DEFAULT",
		"unlock_dist": 0.0,
		"unlock_score": 0,
		"swap": false,
		"band_hi": Color(1.0, 0.45, 0.49),
		"band_base": Color(0.92, 0.18, 0.25),
		"band_sh": Color(0.57, 0.08, 0.14),
		"visor_hi": Color(0.0, 0.96, 1.0),
		"visor_base": Color(0.30, 0.78, 0.87),
		"visor_core": Color(0.88, 1.0, 1.0),
		"scarf": Color(0.92, 0.17, 0.25, 0.95),
		"light": Color(0.0, 0.95, 1.0, 1.0)
	},
	"emerald": {
		"id": "emerald",
		"name": "VENOM LIME",
		"tag": "250m",
		"unlock_dist": 250.0,
		"unlock_score": 1500,
		"swap": true,
		"band_hi": Color(0.73, 1.0, 0.55),
		"band_base": Color(0.22, 0.85, 0.29),
		"band_sh": Color(0.07, 0.42, 0.16),
		"visor_hi": Color(0.72, 1.0, 0.32),
		"visor_base": Color(0.30, 0.90, 0.18),
		"visor_core": Color(0.93, 1.0, 0.81),
		"scarf": Color(0.22, 0.85, 0.29, 0.95),
		"light": Color(0.38, 1.0, 0.32, 1.0)
	},
	"gold": {
		"id": "gold",
		"name": "SOLAR GOLD",
		"tag": "500m",
		"unlock_dist": 500.0,
		"unlock_score": 3500,
		"swap": true,
		"band_hi": Color(1.0, 0.94, 0.53),
		"band_base": Color(0.96, 0.72, 0.18),
		"band_sh": Color(0.61, 0.36, 0.05),
		"visor_hi": Color(1.0, 0.91, 0.40),
		"visor_base": Color(1.0, 0.62, 0.14),
		"visor_core": Color(1.0, 0.97, 0.84),
		"scarf": Color(0.96, 0.72, 0.18, 0.95),
		"light": Color(1.0, 0.80, 0.24, 1.0)
	},
	"violet": {
		"id": "violet",
		"name": "SHADOW VIOLET",
		"tag": "1000m",
		"unlock_dist": 1000.0,
		"unlock_score": 7000,
		"swap": true,
		"band_hi": Color(1.0, 0.64, 1.0),
		"band_base": Color(0.79, 0.24, 0.97),
		"band_sh": Color(0.37, 0.08, 0.53),
		"visor_hi": Color(1.0, 0.55, 0.90),
		"visor_base": Color(0.85, 0.28, 1.0),
		"visor_core": Color(1.0, 0.91, 0.99),
		"scarf": Color(0.79, 0.24, 0.97, 0.95),
		"light": Color(0.88, 0.38, 1.0, 1.0)
	},
	"cyan": {
		"id": "cyan",
		"name": "NEON CYAN",
		"tag": "1500m",
		"unlock_dist": 1500.0,
		"unlock_score": 11000,
		"swap": true,
		"band_hi": Color(0.62, 0.99, 1.0),
		"band_base": Color(0.08, 0.89, 0.96),
		"band_sh": Color(0.04, 0.43, 0.54),
		"visor_hi": Color(0.77, 0.98, 1.0),
		"visor_base": Color(0.35, 0.85, 1.0),
		"visor_core": Color(1.0, 1.0, 1.0),
		"scarf": Color(0.08, 0.89, 0.96, 0.95),
		"light": Color(0.28, 0.96, 1.0, 1.0)
	}
}

# Difficulty multipliers
var difficulty_factor: float = 1.0 # starts at 1.0, increases smoothly over time
var base_player_speed: float = 145.0

const SAVE_PATH: String = "user://cube_lastrun_save.json"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game_data()

func _process(delta: float) -> void:
	if current_state == State.PLAYING:
		survival_time += delta
		# Difficulty increases gently over distance and time for fair pacing
		difficulty_factor = 1.0 + (distance / 850.0) + (survival_time / 150.0)
		difficulty_factor = clampf(difficulty_factor, 1.0, 1.85)
		if combo_count > 0:
			combo_timer -= delta
			if combo_timer <= 0.0:
				reset_combo()

func start_game() -> void:
	current_state = State.PLAYING
	score = 0
	distance = 0.0
	survival_time = 0.0
	zombie_kills = 0
	combo_count = 0
	combo_multiplier = 1
	combo_timer = 0.0
	best_combo = 0
	run_start_high_score = high_score
	run_start_max_distance = max_distance
	run_start_best_combo = all_time_best_combo
	last_run_new_distance_record = false
	last_run_new_combo_record = false
	last_run_unlocked_skins.clear()
	last_run_unlocked_weapons.clear()
	difficulty_factor = 1.0
	get_tree().paused = false
	Engine.time_scale = 1.0
	if GameFeel:
		GameFeel.reset_hitstop()
	Input.action_release("shoot")
	Input.action_release("jump")
	Input.action_release("pause")
	game_started.emit()
	combo_updated.emit(combo_count, combo_multiplier)
	if AudioManager:
		AudioManager.play_music("gameplay")

func add_distance(amount: float) -> void:
	if current_state != State.PLAYING:
		return
	distance += amount
	var prev_score: int = score
	score += int(amount * 0.5)
	distance_updated.emit(distance)
	if score != prev_score:
		score_updated.emit(score)

func add_kill(kill_score: int = 100) -> void:
	if current_state != State.PLAYING:
		return
	zombie_kills += 1
	combo_count += 1
	best_combo = maxi(best_combo, combo_count)
	combo_timer = COMBO_WINDOW
	if combo_count >= 5:
		combo_multiplier = 5
	elif combo_count >= 3:
		combo_multiplier = 3
	elif combo_count >= 2:
		combo_multiplier = 2
	else:
		combo_multiplier = 1
	score += kill_score
	zombie_killed.emit(zombie_kills)
	combo_updated.emit(combo_count, combo_multiplier)
	score_updated.emit(score)

func add_bonus_score(points: int) -> void:
	if current_state != State.PLAYING or points <= 0:
		return
	score += points
	score_updated.emit(score)

func reset_combo() -> void:
	if combo_count > 0 or combo_multiplier > 1:
		combo_count = 0
		combo_multiplier = 1
		combo_timer = 0.0
		combo_updated.emit(combo_count, combo_multiplier)

func update_horde_proximity(proximity: float) -> void:
	if current_state == State.PLAYING:
		horde_proximity_changed.emit(proximity)

func trigger_game_over() -> void:
	if current_state == State.GAME_OVER:
		return
	current_state = State.GAME_OVER
	var prev_best_dist: float = max_distance
	var prev_best_score: int = high_score
	var prev_best_combo: int = all_time_best_combo
	var is_new: bool = false
	last_run_new_distance_record = false
	last_run_new_combo_record = false
	if score > high_score:
		high_score = score
		is_new = true
	if distance > max_distance:
		max_distance = distance
		last_run_new_distance_record = true
	if best_combo > all_time_best_combo:
		all_time_best_combo = best_combo
		last_run_new_combo_record = true
	last_run_unlocked_skins = get_newly_unlocked_skins(prev_best_dist, prev_best_score, max_distance, high_score)
	last_run_unlocked_weapons = get_newly_unlocked_weapon_skins(prev_best_combo, prev_best_score, all_time_best_combo, high_score)
	save_game_data()
	
	if AudioManager:
		AudioManager.stop_music()
		AudioManager.play_sfx("game_over")
		
	game_over.emit(score, distance, survival_time, zombie_kills, is_new)

func restart_game() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	if GameFeel:
		GameFeel.reset_hitstop()
	start_game()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main/game_world.tscn")

func go_to_menu() -> void:
	current_state = State.MENU
	get_tree().paused = false
	Engine.time_scale = 1.0
	if GameFeel:
		GameFeel.reset_hitstop()
	if AudioManager:
		AudioManager.play_music("menu")
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main/main_menu.tscn")

func get_skin_ids() -> Array[String]:
	return SKIN_ORDER

func get_skin_data(skin_id: String = "") -> Dictionary:
	var id: String = selected_skin if skin_id.is_empty() else skin_id
	return SKIN_CATALOG.get(id, SKIN_CATALOG["crimson"])

func is_skin_unlocked(skin_id: String, check_dist: float = -1.0, check_score: int = -1) -> bool:
	var data: Dictionary = SKIN_CATALOG.get(skin_id, {})
	if data.is_empty():
		return false
	var req_dist: float = float(data.get("unlock_dist", 0.0))
	var req_score: int = int(data.get("unlock_score", 0))
	if req_dist <= 0.0 and req_score <= 0:
		return true
	var d: float = max_distance if check_dist < 0.0 else check_dist
	var s: int = high_score if check_score < 0 else check_score
	return d >= req_dist or s >= req_score

func get_newly_unlocked_skins(prev_dist: float, prev_score: int, new_dist: float, new_score: int) -> Array[String]:
	var unlocked: Array[String] = []
	for id in SKIN_ORDER:
		if not is_skin_unlocked(id, prev_dist, prev_score) and is_skin_unlocked(id, new_dist, new_score):
			unlocked.append(id)
	return unlocked

func set_selected_skin(skin_id: String) -> bool:
	if not SKIN_CATALOG.has(skin_id) or not is_skin_unlocked(skin_id):
		return false
	if selected_skin == skin_id:
		return true
	selected_skin = skin_id
	save_game_data()
	skin_changed.emit(selected_skin)
	return true

func apply_skin_to_material(mat: ShaderMaterial, skin_id: String = "", is_showcase: bool = false) -> void:
	if mat == null:
		return
	var data: Dictionary = get_skin_data(skin_id)
	var swap_active: bool = bool(data.get("swap", false))
	mat.set_shader_parameter("skin_swap_enabled", 1.0 if swap_active else 0.0)
	mat.set_shader_parameter("skin_y_limit", 0.70 if is_showcase else 1.0)
	mat.set_shader_parameter("band_hi_color", data.get("band_hi", Color(1.0, 0.45, 0.49)))
	mat.set_shader_parameter("band_base_color", data.get("band_base", Color(0.92, 0.18, 0.25)))
	mat.set_shader_parameter("band_sh_color", data.get("band_sh", Color(0.57, 0.08, 0.14)))
	if not swap_active:
		mat.set_shader_parameter("visor_swap_enabled", 0.0)
		return
	mat.set_shader_parameter("visor_swap_enabled", 2.0 if is_showcase else 1.0)
	mat.set_shader_parameter("visor_uv_bounds", Vector4(0.38, 0.30, 0.65, 0.62) if is_showcase else Vector4(0.0, 0.0, 1.0, 1.0))
	mat.set_shader_parameter("visor_hi_color", data.get("visor_hi", Color(0.0, 0.96, 1.0)))
	mat.set_shader_parameter("visor_base_color", data.get("visor_base", Color(0.30, 0.78, 0.87)))
	mat.set_shader_parameter("visor_core_color", data.get("visor_core", Color(0.88, 1.0, 1.0)))

func get_weapon_skin_ids() -> Array[String]:
	return WEAPON_SKIN_ORDER

func get_weapon_skin_data(weapon_id: String = "") -> Dictionary:
	var id: String = selected_weapon_skin if weapon_id.is_empty() else weapon_id
	return WEAPON_SKIN_CATALOG.get(id, WEAPON_SKIN_CATALOG["classic"])

func is_weapon_skin_unlocked(weapon_id: String, check_combo: int = -1, check_score: int = -1) -> bool:
	var data: Dictionary = WEAPON_SKIN_CATALOG.get(weapon_id, {})
	if data.is_empty():
		return false
	var req_combo: int = int(data.get("unlock_combo", 0))
	var req_score: int = int(data.get("unlock_score", 0))
	if req_combo <= 0 and req_score <= 0:
		return true
	var c: int = all_time_best_combo if check_combo < 0 else check_combo
	var s: int = high_score if check_score < 0 else check_score
	return c >= req_combo or s >= req_score

func get_newly_unlocked_weapon_skins(prev_combo: int, prev_score: int, new_combo: int, new_score: int) -> Array[String]:
	var unlocked: Array[String] = []
	for id in WEAPON_SKIN_ORDER:
		if not is_weapon_skin_unlocked(id, prev_combo, prev_score) and is_weapon_skin_unlocked(id, new_combo, new_score):
			unlocked.append(id)
	return unlocked

func set_selected_weapon_skin(weapon_id: String) -> bool:
	if not WEAPON_SKIN_CATALOG.has(weapon_id) or not is_weapon_skin_unlocked(weapon_id):
		return false
	if selected_weapon_skin == weapon_id:
		return true
	selected_weapon_skin = weapon_id
	save_game_data()
	weapon_skin_changed.emit(selected_weapon_skin)
	return true

func save_game_data() -> void:
	var data: Dictionary = {
		"high_score": high_score,
		"max_distance": max_distance,
		"all_time_best_combo": all_time_best_combo,
		"selected_skin": selected_skin,
		"selected_weapon_skin": selected_weapon_skin
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
		if json.parse(txt) == OK and typeof(json.data) == TYPE_DICTIONARY:
			var dict: Dictionary = json.data
			high_score = int(dict.get("high_score", 0))
			max_distance = float(dict.get("max_distance", 0.0))
			all_time_best_combo = int(dict.get("all_time_best_combo", 0))
			var saved_skin: String = str(dict.get("selected_skin", "crimson"))
			selected_skin = saved_skin if is_skin_unlocked(saved_skin) else "crimson"
			var saved_wpn: String = str(dict.get("selected_weapon_skin", "classic"))
			selected_weapon_skin = saved_wpn if is_weapon_skin_unlocked(saved_wpn) else "classic"
