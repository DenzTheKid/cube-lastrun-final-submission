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
		var unlocked: Array[String] = GameManager.last_run_unlocked_skins if GameManager else []
		if unlocked.is_empty():
			unlock_banner.visible = false
		else:
			var names: Array[String] = []
			for sid in unlocked:
				names.append(str(GameManager.get_skin_data(sid).get("name", sid)))
			unlock_banner.text = "SKIN UNLOCKED: %s" % ", ".join(names)
			unlock_banner.visible = true

	await get_tree().create_timer(0.6, true, false, true).timeout
	if dimmer:
		dimmer.visible = true
	panel.visible = true
	retry_btn.grab_focus()

func _on_retry_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	if GameManager:
		GameManager.restart_game()

func _on_menu_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	if GameManager:
		GameManager.go_to_menu()
