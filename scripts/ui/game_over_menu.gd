extends CanvasLayer
class_name GameOverMenu

# Game Over presentation showing final score, distance, survival stats,
# new high-score fanfare, and retry controls using the shared game_theme.tres.

const UI_ANIMATOR = preload("res://scripts/ui/ui_animator.gd")

@onready var panel: PanelContainer = %GameOverPanel
@onready var score_lbl: Label = %FinalScoreLabel
@onready var dist_lbl: Label = %FinalDistLabel
@onready var time_lbl: Label = %FinalTimeLabel
@onready var kills_lbl: Label = %FinalKillsLabel
@onready var record_banner: Label = %RecordBanner
@onready var retry_btn: Button = %RetryButton
@onready var menu_btn: Button = %MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	UI_ANIMATOR.style_button(retry_btn, true)
	UI_ANIMATOR.style_button(menu_btn, false)
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

	record_banner.visible = is_new

	await get_tree().create_timer(0.8).timeout
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
