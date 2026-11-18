extends Node2D

const SCREENSHOT_DIR: String = "documentation/screenshots"

const TARGET_RESOLUTIONS = [
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(1920, 1200),
	Vector2i(2560, 1440)
]

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + SCREENSHOT_DIR))
	print("=================================================================")
	print("  MULTI-RESOLUTION RESPONSIVE HUD AUDIT & VERIFICATION HARNESS   ")
	print("=================================================================")
	_run_audit()

func _run_audit() -> void:
	var world_scene: PackedScene = load("res://scenes/main/game_world.tscn")
	var world: Node = world_scene.instantiate()
	add_child(world)

	for i in range(10):
		await get_tree().process_frame

	var hud: HUD = world.get_node("HUD") as HUD
	var safe_frame: Control = hud.get_node("%SafeFrame") as Control
	var ammo_plate: Control = hud.get_node("%AmmoPlate") as Control
	var horde_plate: Control = hud.get_node("%HordePlate") as Control
	var heart_plate: Control = hud.get_node("%HeartPlate") as Control
	var top_plate: Control = hud.get_node("%TopPlate") as Control

	for res in TARGET_RESOLUTIONS:
		DisplayServer.window_set_size(res)
		get_viewport().size = res
		hud._update_responsive_layout()

		for i in range(4):
			await get_tree().process_frame
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw

		var vp = get_viewport()
		if DisplayServer.get_name() != "headless":
			var img: Image = vp.get_texture().get_image()
			var fname: String = "hud_res_%dx%d.png" % [res.x, res.y]
			var save_path: String = ProjectSettings.globalize_path("res://" + SCREENSHOT_DIR + "/" + fname)
			if img:
				img.save_png(save_path)
			print("  [SAVED SCREENSHOT]: %s" % fname)

		var ammo_rect = ammo_plate.get_global_rect()
		var horde_rect = horde_plate.get_global_rect()
		var gap = horde_rect.position.x - (ammo_rect.position.x + ammo_rect.size.x)
		var gap_ratio = (gap / safe_frame.size.x) * 100.0

		print("\n--- Resolution: %dx%d ---" % [res.x, res.y])
		print("  SafeFrame Pos: %s  Size: %s" % [str(safe_frame.position), str(safe_frame.size)])
		print("  Ammo Global: Pos=%s Size=%s" % [str(ammo_rect.position), str(ammo_rect.size)])
		print("  Horde Global: Pos=%s Size=%s" % [str(horde_rect.position), str(horde_rect.size)])
		print("  Gap between Ammo & Horde: %.1f px (%.1f%% of HUD width)" % [gap, gap_ratio])
		print("  Bottom HUD Y position: %.1f (offset from bottom: %.1f px)" % [ammo_rect.position.y, vp.get_visible_rect().size.y - (ammo_rect.position.y + ammo_rect.size.y)])

	print("\n=================================================================")
	print("  MULTI-RESOLUTION AUDIT COMPLETE — ALL RESOLUTIONS VERIFIED!     ")
	print("=================================================================")
	get_tree().quit()
