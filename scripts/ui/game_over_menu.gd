extends CanvasLayer
class_name GameOverMenu

# Game Over presentation showing final score, distance, survival stats,
# new high-score fanfare, and retry controls using the shared game_theme.tres.

const UI_ANIMATOR = preload("res://scripts/ui/ui_animator.gd")

@onready var panel: PanelContainer = %GameOverPanel
@onready var dimmer: ColorRect = %Dimmer
@onready var score_lbl: Label = %FinalScoreLabel
@onready var dist_lbl: Label = %FinalDistLabel
@onready var time_lbl: Label = %FinalTimeLabel
@onready var kills_lbl: Label = %FinalKillsLabel
@onready var combo_lbl: Label = %FinalComboLabel
@onready var record_banner: Label = %RecordBanner
@onready var unlock_banner: Label = %UnlockBanner
@onready var retry_btn: Button = %RetryButton
@onready var menu_btn: Button = %MenuButton

var _is_transitioning: bool = false

func _exit_tree() -> void:
	if GameManager and GameManager.game_over.is_connected(_on_game_over):
		GameManager.game_over.disconnect(_on_game_over)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	if dimmer:
		dimmer.visible = false
	UI_ANIMATOR.style_button(retry_btn, true)
	UI_ANIMATOR.style_button(menu_btn, false)
	retry_btn.focus_neighbor_top = menu_btn.get_path()
	retry_btn.focus_neighbor_bottom = menu_btn.get_path()
	menu_btn.focus_neighbor_top = retry_btn.get_path()
	menu_btn.focus_neighbor_bottom = retry_btn.get_path()
	if GameManager:
		if not GameManager.game_over.is_connected(_on_game_over):
			GameManager.game_over.connect(_on_game_over)
	retry_btn.pressed.connect(_on_retry_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)

func _on_game_over(final_score: int, distance: float, survival_time: float, kills: int, is_new: bool) -> void:
	score_lbl.text = "FINAL SCORE: %d" % final_score
	dist_lbl.text = "DISTANCE: %dm" % int(distance)

	var t: int = int(survival_time)
	var mins: int = int(t / 60.0)
	var secs: int = t % 60
	time_lbl.text = "TIME SURVIVED: %02d:%02d" % [mins, secs]
	kills_lbl.text = "ZOMBIES PURGED: %d" % kills

	var run_combo: int = GameManager.best_combo if GameManager else 0
	var rec_combo: int = GameManager.all_time_best_combo if GameManager else 0
	if combo_lbl:
		if GameManager and GameManager.last_run_new_combo_record and run_combo >= 2:
			combo_lbl.text = "BEST COMBO: %dx  (NEW BEST!)" % run_combo
		else:
			combo_lbl.text = "BEST COMBO: %dx  (RECORD: %dx)" % [run_combo, rec_combo]

	var new_dist: bool = GameManager != null and GameManager.last_run_new_distance_record and distance >= 10.0
	record_banner.visible = is_new or new_dist
	if is_new and new_dist:
		record_banner.text = "NEW SCORE & DISTANCE RECORD!"
	elif is_new:
		record_banner.text = "NEW HIGH SCORE RECORD!"
	elif new_dist:
		record_banner.text = "NEW DISTANCE RECORD!"

	if unlock_banner:
		var unlocked_cubes: Array[String] = GameManager.last_run_unlocked_skins if GameManager else []
		var unlocked_guns: Array[String] = GameManager.last_run_unlocked_weapons if GameManager else []
		var parts: Array[String] = []
		if not unlocked_cubes.is_empty():
			var c_names: Array[String] = []
			for sid in unlocked_cubes:
				c_names.append(str(GameManager.get_skin_data(sid).get("name", sid)))
			parts.append("CUBE: %s" % ", ".join(c_names))
		if not unlocked_guns.is_empty():
			var w_names: Array[String] = []
			for wid in unlocked_guns:
				w_names.append(str(GameManager.get_weapon_skin_data(wid).get("name", wid)))
			parts.append("GUN: %s" % ", ".join(w_names))
		if parts.is_empty():
			unlock_banner.visible = false
		else:
			unlock_banner.text = "UNLOCKED — %s" % " | ".join(parts)
			unlock_banner.visible = true

	await get_tree().create_timer(0.6, true, false, true).timeout
	if dimmer:
		dimmer.visible = true
	panel.visible = true
	retry_btn.grab_focus()

func _on_retry_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	get_tree().paused = false
	if GameFeel:
		GameFeel.reset_hitstop()
	Engine.time_scale = 1.0
	if GameManager:
		GameManager.restart_game()

func _on_menu_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	get_tree().paused = false
	if GameFeel:
		GameFeel.reset_hitstop()
	Engine.time_scale = 1.0
	if GameManager:
		GameManager.go_to_menu()
