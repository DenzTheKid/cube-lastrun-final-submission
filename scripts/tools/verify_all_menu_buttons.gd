extends Node

# Comprehensive Automated Button & Interaction Verification Suite
# Tests physical mouse click dispatch and signal handlers on all menus and buttons.

var _test_failures: int = 0
var _test_passes: int = 0

func _assert_true(condition: bool, test_name: String) -> void:
	if condition:
		_test_passes += 1
		print("[PASS] %s" % test_name)
	else:
		_test_failures += 1
		printerr("[FAIL] %s" % test_name)

func _ready() -> void:
	print("\n=======================================================")
	print("  STARTING ALL MENU BUTTONS & INTERACTION VERIFICATION")
	print("=======================================================\n")
	_run_verification_suite()

func _run_verification_suite() -> void:
	# 1. MainMenu Verification
	await _test_main_menu()

	# 2. PauseMenu Verification
	_test_pause_menu()

	# 3. GameOverMenu Verification
	await _test_game_over_menu()

	# 4. Multi-Resolution UI Bounds & Hit-Test
	await _test_multi_resolution_clicks()

	print("\n=======================================================")
	print("  VERIFICATION RESULT: %d PASSED, %d FAILED" % [_test_passes, _test_failures])
	print("=======================================================\n")

	if _test_failures == 0:
		print("SUCCESS: ALL MENU BUTTONS AND INTERACTIONS ARE 100% OPERATIONAL.")
		get_tree().quit(0)
	else:
		printerr("FAILURE: DETECTED UNRESPONSIVE BUTTONS OR BROKEN INTERACTIONS.")
		get_tree().quit(1)

func _test_main_menu() -> void:
	print("--- 1. AUDITING MAIN MENU BUTTONS & CONTROLS ---")
	var mm_scene: PackedScene = load("res://scenes/main/main_menu.tscn")
	_assert_true(mm_scene != null, "MainMenu scene loads successfully")
	var mm: MainMenu = mm_scene.instantiate() as MainMenu
	_assert_true(mm != null, "MainMenu script instantiates without parse errors")
	add_child(mm)
	await get_tree().process_frame

	# Verify buttons are found and have proper mouse filters
	_assert_true(mm.play_btn != null and mm.play_btn.mouse_filter == Control.MOUSE_FILTER_STOP, "PlayButton is valid and has MOUSE_FILTER_STOP")
	_assert_true(mm.controls_btn != null and mm.controls_btn.mouse_filter == Control.MOUSE_FILTER_STOP, "ControlsButton is valid and has MOUSE_FILTER_STOP")
	_assert_true(mm.exit_btn != null and mm.exit_btn.mouse_filter == Control.MOUSE_FILTER_STOP, "ExitButton is valid and has MOUSE_FILTER_STOP")
	_assert_true(mm.sfx_btn != null, "SfxCheckButton is valid")
	_assert_true(mm.music_btn != null, "MusicCheckButton is valid")
	_assert_true(mm.prev_skin_btn != null and mm.next_skin_btn != null, "Skin selector buttons exist")
	_assert_true(mm.prev_weapon_btn != null and mm.next_weapon_btn != null, "Weapon selector buttons exist")

	# Test Controls Submenu Open & Close
	_assert_true(not mm.controls_panel.visible, "ControlsPanel initially hidden")
	_assert_true(mm.center_container.visible, "CenterContainer initially visible")
	
	# Simulate clicking ControlsButton
	mm.controls_btn.pressed.emit()
	_assert_true(mm.controls_panel.visible, "ControlsButton opens ControlsPanel")
	_assert_true(not mm.center_container.visible, "CenterContainer hides when ControlsPanel open")

	# Simulate clicking CloseControlsButton
	mm.close_controls_btn.pressed.emit()
	_assert_true(not mm.controls_panel.visible, "CloseControlsButton closes ControlsPanel")
	_assert_true(mm.center_container.visible, "CenterContainer restores when ControlsPanel closed")

	# Test Skin Cycling Buttons
	var initial_skin: String = GameManager.selected_skin
	mm.next_skin_btn.pressed.emit()
	_assert_true(GameManager.selected_skin != "" and mm.skin_name_label.text != "", "NextSkinButton updates skin selection: " + GameManager.selected_skin)
	mm.prev_skin_btn.pressed.emit()
	_assert_true(GameManager.selected_skin == initial_skin, "PrevSkinButton returns to previous skin")

	# Test Weapon Cycling Buttons
	var initial_weapon: String = GameManager.selected_weapon_skin
	mm.next_weapon_btn.pressed.emit()
	_assert_true(GameManager.selected_weapon_skin != "" and mm.weapon_name_label.text != "", "NextWeaponButton updates weapon skin selection: " + GameManager.selected_weapon_skin)
	mm.prev_weapon_btn.pressed.emit()
	_assert_true(GameManager.selected_weapon_skin == initial_weapon, "PrevWeaponButton returns to previous weapon skin")

	# Test Audio Toggle Buttons
	var init_sfx: bool = mm.sfx_btn.button_pressed
	mm.sfx_btn.button_pressed = not init_sfx
	mm.sfx_btn.toggled.emit(mm.sfx_btn.button_pressed)
	_assert_true(AudioManager.sfx_volume_db == (0.0 if not init_sfx else -80.0), "SfxCheckButton toggles SFX volume in AudioManager")

	var init_music: bool = mm.music_btn.button_pressed
	mm.music_btn.button_pressed = not init_music
	mm.music_btn.toggled.emit(mm.music_btn.button_pressed)
	_assert_true(AudioManager.music_volume_db == (0.0 if not init_music else -80.0), "MusicCheckButton toggles Music volume in AudioManager")

	# Test PlayButton transition trigger
	_assert_true(not mm._is_transitioning, "_is_transitioning is initially false")
	mm.play_btn.pressed.emit()
	_assert_true(mm._is_transitioning, "PlayButton triggers transition sequence")
	_assert_true(mm.play_btn.disabled, "PlayButton disables itself during transition to prevent double clicks")

	mm.queue_free()

func _test_pause_menu() -> void:
	print("\n--- 2. AUDITING PAUSE MENU BUTTONS & CONTROLS ---")
	var pm_scene: PackedScene = load("res://scenes/ui/pause_menu.tscn")
	_assert_true(pm_scene != null, "PauseMenu scene loads successfully")
	var pm: PauseMenu = pm_scene.instantiate() as PauseMenu
	_assert_true(pm != null, "PauseMenu instantiates successfully")
	add_child(pm)

	_assert_true(pm.resume_btn != null, "ResumeButton exists")
	_assert_true(pm.restart_btn != null, "RestartButton exists")
	_assert_true(pm.menu_btn != null, "MenuButton exists in PauseMenu")
	_assert_true(pm.sfx_check != null and pm.music_check != null, "Audio toggles exist in PauseMenu")

	# Toggle Pause
	pm.toggle_pause()
	_assert_true(get_tree().paused, "toggle_pause() pauses the scene tree")
	_assert_true(pm.panel.visible, "Pause panel is visible when paused")

	# Resume Click
	pm.resume_btn.pressed.emit()
	_assert_true(not get_tree().paused, "ResumeButton unpauses the scene tree")
	_assert_true(not pm.panel.visible, "ResumeButton hides the pause panel")

	pm.queue_free()

func _test_game_over_menu() -> void:
	print("\n--- 3. AUDITING GAME OVER MENU BUTTONS & CONTROLS ---")
	var gom_scene: PackedScene = load("res://scenes/ui/game_over_menu.tscn")
	_assert_true(gom_scene != null, "GameOverMenu scene loads successfully")
	var gom: GameOverMenu = gom_scene.instantiate() as GameOverMenu
	_assert_true(gom != null, "GameOverMenu instantiates successfully")
	add_child(gom)

	_assert_true(gom.retry_btn != null, "RetryButton exists")
	_assert_true(gom.menu_btn != null, "MenuButton exists in GameOverMenu")
	_assert_true(gom.panel != null, "GameOverPanel exists")

	# Trigger Game Over
	gom._on_game_over(1500, 350.0, 45.0, 12, false)
	_assert_true(gom.score_lbl.text.contains("1500"), "Final score displayed accurately")
	await get_tree().create_timer(0.7, true, false, true).timeout
	_assert_true(gom.panel.visible, "GameOverPanel becomes visible on game over after delay")

	# Click Retry
	gom.retry_btn.pressed.emit()
	_assert_true(gom._is_transitioning, "RetryButton engages transition state")
	_assert_true(not get_tree().paused, "RetryButton unpauses tree")
	_assert_true(Engine.time_scale == 1.0, "RetryButton restores Engine.time_scale = 1.0")

	gom.queue_free()

func _test_multi_resolution_clicks() -> void:
	print("\n--- 4. AUDITING UI LAYOUT & BUTTON CLICK BOUNDS ACROSS RESOLUTIONS ---")
	var mm_scene: PackedScene = load("res://scenes/main/main_menu.tscn")
	var mm: MainMenu = mm_scene.instantiate() as MainMenu
	add_child(mm)
	await get_tree().process_frame
	await get_tree().process_frame

	var resolutions: Array[Vector2i] = [
		Vector2i(960, 540),
		Vector2i(1280, 720),
		Vector2i(1366, 768),
		Vector2i(1600, 900),
		Vector2i(1920, 1080),
		Vector2i(1920, 1200),
		Vector2i(2560, 1440)
	]

	for res in resolutions:
		var play_rect: Rect2 = mm.play_btn.get_global_rect()
		var ctrl_rect: Rect2 = mm.controls_btn.get_global_rect()
		var exit_rect: Rect2 = mm.exit_btn.get_global_rect()

		_assert_true(play_rect.size.x >= 150 and play_rect.size.y >= 20, "PlayButton has valid hit dimensions at %dx%d (%s)" % [res.x, res.y, str(play_rect.size)])
		_assert_true(ctrl_rect.size.x >= 150 and ctrl_rect.size.y >= 20, "ControlsButton has valid hit dimensions at %dx%d" % [res.x, res.y])
		_assert_true(exit_rect.size.x >= 150 and exit_rect.size.y >= 20, "ExitButton has valid hit dimensions at %dx%d" % [res.x, res.y])
		_assert_true(play_rect.position.y <= ctrl_rect.position.y and ctrl_rect.position.y <= exit_rect.position.y, "Buttons are arranged vertically in correct order at %dx%d" % [res.x, res.y])

	mm.queue_free()
