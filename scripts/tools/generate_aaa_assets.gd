extends SceneTree

# Native Godot 4 Image Generator for CUBE: LAST RUN AAA Indie Overhaul.
# Generates ultra-crisp 2.5D voxel-shaded sprite sheets, multi-layer parallax
# textures (including Foreground Overpass Layer), PointLight2D radial lightmaps,
# and glowing HUD shield pips without requiring external Python/Pillow.

const OUTLINE := Color8(14, 16, 24, 255)

func _init() -> void:
	print("=== Generating AAA Indie 2.5D Voxel Pixel Art Assets via Godot 4.7 ===")
	_make_light_textures()
	_make_ui_pips()
	_make_foreground_overpass()
	_make_upgraded_sky_and_skylines()
	_make_upgraded_player()
	_make_upgraded_zombies()
	print("=== All AAA Indie Assets Generated Successfully! ===")
	quit(0)

func _draw_rect_outline(img: Image, x0: int, y0: int, w: int, h: int, fill_col: Color, out_col: Color = OUTLINE) -> void:
	if w <= 0 or h <= 0:
		return
	img.fill_rect(Rect2i(x0, y0, w, h), fill_col)
	for x in range(x0, x0 + w):
		_safe_px(img, x, y0, out_col)
		_safe_px(img, x, y0 + h - 1, out_col)
	for y in range(y0, y0 + h):
		_safe_px(img, x0, y, out_col)
		_safe_px(img, x0 + w - 1, y, out_col)

func _draw_voxel_box(img: Image, x0: int, y0: int, w: int, h: int, fill_col: Color, hi_col: Color, rim_col: Color, sh_col: Color) -> void:
	_draw_rect_outline(img, x0, y0, w, h, fill_col, OUTLINE)
	for x in range(x0 + 1, x0 + w - 1):
		_safe_px(img, x, y0 + 1, rim_col)
		_safe_px(img, x, y0 + 2, hi_col)
		_safe_px(img, x, y0 + h - 2, sh_col)
	for y in range(y0 + 1, y0 + h - 1):
		_safe_px(img, x0 + w - 2, y, hi_col)
		_safe_px(img, x0 + 1, y, sh_col)

func _safe_px(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, col)

func _make_light_textures() -> void:
	var rad := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var dx := (float(x) - 31.5) / 31.5
			var dy := (float(y) - 31.5) / 31.5
			var d := sqrt(dx * dx + dy * dy)
			var a := pow(maxf(0.0, 1.0 - d), 2.0)
			rad.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	rad.save_png("res://assets/environment/point_light_radial.png")

	# Cone light texture for streetlamps
	var cone := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		var ty := float(y) / 63.0
		var half_w := lerpf(3.0, 28.0, ty)
		for x in range(64):
			var dx := absf(float(x) - 31.5)
			if dx <= half_w:
				var falloff_x := 1.0 - (dx / half_w)
				var falloff_y := 1.0 - ty * 0.85
				var a := clampf(falloff_x * falloff_y, 0.0, 1.0)
				cone.set_pixel(x, y, Color(1.0, 0.85, 0.55, a))
	cone.save_png("res://assets/environment/light_cone.png")

func _make_ui_pips() -> void:
	# Glowing Shield / Heart Pip Full (14x14)
	var full := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	_draw_voxel_box(full, 1, 2, 12, 10, Color8(235, 45, 70), Color8(255, 110, 130), Color8(255, 200, 210), Color8(135, 18, 35))
	full.fill_rect(Rect2i(4, 4, 6, 4), Color8(255, 150, 165))
	full.set_pixel(4, 4, Color.WHITE)
	full.save_png("res://assets/ui/hp_pip_full.png")

	# Shattered Empty Pip (14x14)
	var empty := Image.create(14, 14, false, Image.FORMAT_RGBA8)
	_draw_rect_outline(empty, 1, 2, 12, 10, Color8(32, 35, 46, 180), OUTLINE)
	for i in range(6):
		_safe_px(empty, 4 + i, 3 + i, OUTLINE)
	empty.save_png("res://assets/ui/hp_pip_empty.png")

func _make_foreground_overpass() -> void:
	var fore := Image.create(480, 270, false, Image.FORMAT_RGBA8)
	var rust_dark := Color8(44, 28, 32, 240)
	var rust_hi := Color8(96, 54, 46, 240)
	var pole_col := Color8(28, 32, 44, 255)
	var sodium := Color8(255, 198, 92, 255)

	# Rusted highway guardrail along road edge (y = 213..218)
	_draw_rect_outline(fore, 0, 213, 480, 5, rust_dark, OUTLINE)
	fore.fill_rect(Rect2i(0, 214, 480, 1), rust_hi)
	for gx in range(0, 480, 24):
		_draw_rect_outline(fore, gx, 210, 4, 14, rust_dark, OUTLINE)

	# Streetlamps casting warm sodium-vapor cones at x = 76, 236, 396
	for lx: int in [76, 236, 396]:
		_draw_rect_outline(fore, lx, 132, 4, 92, pole_col, OUTLINE)
		_draw_rect_outline(fore, lx, 130, 18, 4, pole_col, OUTLINE)
		_draw_rect_outline(fore, lx + 14, 132, 8, 4, sodium, OUTLINE)
		# Volumetric light cone
		for y in range(136, 224):
			var t := float(y - 136) / 88.0
			var hw := int(lerpf(3.0, 26.0, t))
			var alpha := lerpf(0.18, 0.02, t)
			for x in range(lx + 18 - hw, lx + 18 + hw):
				if x >= 0 and x < 480 and y < 213:
					var cur := fore.get_pixel(x, y)
					if cur.a < 0.1:
						fore.set_pixel(x, y, Color(1.0, 0.78, 0.35, alpha))

	# Burned-out car silhouettes behind guardrail
	for cx: int in [138, 318]:
		_draw_rect_outline(fore, cx, 203, 38, 11, Color8(24, 22, 32, 245), OUTLINE)
		_draw_rect_outline(fore, cx + 7, 196, 22, 8, Color8(30, 26, 38, 245), OUTLINE)
		fore.fill_rect(Rect2i(cx + 9, 198, 7, 5), Color8(85, 42, 48, 190))
		fore.fill_rect(Rect2i(cx + 18, 198, 8, 5), Color8(85, 42, 48, 190))

	fore.save_png("res://assets/environment/parallax_overpass_fore.png")

func _make_upgraded_sky_and_skylines() -> void:
	# 1. Sky gradient (#0f1021 -> #2b193d -> #7a2832 -> #f28c38)
	var sky := Image.create(480, 270, false, Image.FORMAT_RGBA8)
	var c0 := Color("#0f1021")
	var c1 := Color("#2b193d")
	var c2 := Color("#7a2832")
	var c3 := Color("#f28c38")
	for y in range(270):
		var ty := float(y) / 269.0
		var col: Color
		if ty < 0.32:
			col = c0.lerp(c1, ty / 0.32)
		elif ty < 0.65:
			col = c1.lerp(c2, (ty - 0.32) / 0.33)
		else:
			col = c2.lerp(c3, (ty - 0.65) / 0.35)
		sky.fill_rect(Rect2i(0, y, 480, 1), col)
	sky.save_png("res://assets/environment/parallax_sky.png")

	# 2. Distant Mega-City Silhouette with red aviation beacons
	var dist := Image.create(480, 270, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 101
	var sil_col := Color8(30, 19, 38, 240)
	var rim_col := Color8(110, 48, 58, 220)
	var bx := 0
	while bx < 480:
		var bw := rng.randi_range(24, 46)
		if bx + bw > 480:
			bw = 480 - bx
		var bh := rng.randi_range(68, 148)
		var by := 224 - bh
		dist.fill_rect(Rect2i(bx, by, bw, 270 - by), sil_col)
		dist.fill_rect(Rect2i(bx, by, bw, 1), rim_col)
		dist.fill_rect(Rect2i(bx + bw - 1, by, 1, 224 - by), rim_col)
		# Radio spire & red aviation warning light
		if rng.randf() > 0.45:
			var tx := bx + bw / 2
			var th := rng.randi_range(12, 26)
			dist.fill_rect(Rect2i(tx, by - th, 2, th), sil_col)
			dist.fill_rect(Rect2i(tx - 1, by - th - 1, 4, 4), Color8(255, 45, 55, 245))
			_safe_px(dist, tx, by - th, Color.WHITE)
		# Distant warm amber windows
		var wy := by + 8
		while wy < 210:
			var wx := bx + 4
			while wx < bx + bw - 5:
				if rng.randf() > 0.68:
					dist.fill_rect(Rect2i(wx, wy, 2, 4), Color8(245, 145, 65, 130))
				wx += 7
			wy += 10
		bx += bw + rng.randi_range(2, 6)
	dist.save_png("res://assets/environment/parallax_skyline_distant.png")

	# 3. Mid-ground Urban Skyline (#161b33, #1f2747) with amber/cyan windows & neon signs
	var mid := Image.create(480, 270, false, Image.FORMAT_RGBA8)
	rng.seed = 202
	var navy_a := Color("#161b33")
	var navy_b := Color("#1f2747")
	var mid_rim := Color8(78, 64, 102, 255)
	var win_amber := Color8(255, 182, 72, 240)
	var win_cyan := Color8(75, 228, 255, 230)
	var win_dark := Color8(12, 15, 28, 255)
	bx = 0
	var idx := 0
	while bx < 480:
		var bw := rng.randi_range(40, 72)
		if bx + bw > 480:
			bw = 480 - bx
		var bh := rng.randi_range(76, 156)
		var by := 226 - bh
		var col := navy_a if (idx % 2 == 0) else navy_b
		_draw_rect_outline(mid, bx, by, bw, 270 - by, col, OUTLINE)
		mid.fill_rect(Rect2i(bx + 1, by + 1, bw - 2, 1), mid_rim)
		mid.fill_rect(Rect2i(bx + bw - 2, by + 1, 1, 226 - by), mid_rim)
		# Rooftop neon billboard frame
		if idx % 2 == 0 and bw >= 44:
			var bbw := bw - 14
			_draw_rect_outline(mid, bx + 7, by - 20, bbw, 15, Color8(34, 20, 42, 255), OUTLINE)
			var neon := Color8(255, 65, 130, 255) if (idx % 4 == 0) else Color8(55, 235, 255, 255)
			_draw_rect_outline(mid, bx + 9, by - 18, bbw - 4, 11, Color8(24, 16, 32, 255), neon)
			mid.fill_rect(Rect2i(bx + 11, by - 5, 2, 5), OUTLINE)
			mid.fill_rect(Rect2i(bx + bbw, by - 5, 2, 5), OUTLINE)
		else:
			# Rooftop water tower
			_draw_rect_outline(mid, bx + 8, by - 16, 14, 11, Color8(56, 42, 48, 255), OUTLINE)
			mid.fill_rect(Rect2i(bx + 10, by - 5, 2, 5), OUTLINE)
			mid.fill_rect(Rect2i(bx + 18, by - 5, 2, 5), OUTLINE)

		var wy := by + 10
		while wy < 216:
			var wx := bx + 6
			while wx < bx + bw - 8:
				var rv := rng.randf()
				var wcol := win_dark
				if rv > 0.70:
					wcol = win_amber
				elif rv > 0.54:
					wcol = win_cyan
				mid.fill_rect(Rect2i(wx, wy, 4, 6), wcol)
				wx += 9
			wy += 12
		bx += bw + rng.randi_range(6, 14)
		idx += 1
	mid.save_png("res://assets/environment/parallax_buildings_mid.png")

func _make_upgraded_player() -> void:
	# Enhance cube_player.png with glowing cyan tactical visor & 2.5D voxel bevels
	var img := Image.load_from_file("res://assets/characters/cube_player.png")
	if not img:
		return
	var visor_glow := Color8(0, 245, 255, 255)
	var visor_core := Color8(230, 255, 255, 255)
	# Add glowing visor highlights on Idle (Row 0), Run (Row 1), Jump (Row 2), Fall (Row 3), Land (Row 4)
	for row: int in [0, 1, 2, 3, 4]:
		var max_cols: int = 6 if row == 1 else (4 if row == 0 else 2)
		for col: int in range(max_cols):
			if row == 0 and col == 3:
				continue # blink frame
			var cx: int = col * 24
			var cy: int = row * 24
			var bob: int = 0
			if row == 0 and col in [1, 2]:
				bob = 1
			elif row == 1:
				var bobs: Array[int] = [0, -1, 0, 1, 0, -1]
				bob = bobs[col]
			elif row == 2:
				bob = 1 if col == 0 else -2
			elif row == 3:
				bob = 0 if col == 0 else 1
			elif row == 4:
				bob = 2 if col == 0 else 0
			var bx: int = cx + 4
			var by: int = cy + 4 + bob
			# Top specular voxel edge
			img.fill_rect(Rect2i(bx + 1, by + 1, 14, 1), Color8(165, 248, 255, 255))
			# Glowing cyan visor eyes
			var vx0: int = bx + 3
			var vy0: int = by + 5
			img.fill_rect(Rect2i(vx0, vy0, 11, 6), Color8(16, 22, 36, 255))
			img.fill_rect(Rect2i(vx0 + 2, vy0 + 1, 3, 4), visor_glow)
			_safe_px(img, vx0 + 3, vy0 + 1, visor_core)
			img.fill_rect(Rect2i(vx0 + 6, vy0 + 1, 3, 4), visor_glow)
			_safe_px(img, vx0 + 7, vy0 + 1, visor_core)
	img.save_png("res://assets/characters/cube_player.png")

func _make_upgraded_zombies() -> void:
	# Add glowing toxic-green eyes to Shambler (zombie_walker.png)
	var w_img := Image.load_from_file("res://assets/zombies/zombie_walker.png")
	if w_img:
		for i in range(4):
			var cx := i * 24
			var bob := 1 if i in [1, 3] else 0
			var bx := cx + 4
			var by := 4 + bob
			w_img.fill_rect(Rect2i(bx + 1, by + 1, 14, 1), Color8(150, 215, 135, 255))
			w_img.fill_rect(Rect2i(bx + 8, by + 4, 4, 3), Color8(55, 255, 65, 255))
			_safe_px(w_img, bx + 9, by + 5, Color8(230, 255, 220, 255))
		w_img.save_png("res://assets/zombies/zombie_walker.png")

	# Add glowing crimson eyes to Sprinter (zombie_runner.png)
	var r_img := Image.load_from_file("res://assets/zombies/zombie_runner.png")
	if r_img:
		for i in range(4):
			var cx := i * 24
			var bob := (i % 2) * 2
			var bx := cx + 4
			var by := 4 + bob
			r_img.fill_rect(Rect2i(bx + 1, by + 1, 14, 1), Color8(255, 125, 125, 255))
			r_img.fill_rect(Rect2i(bx + 7, by + 3, 6, 3), Color8(255, 35, 35, 255))
			_safe_px(r_img, bx + 8, by + 4, Color.WHITE)
		r_img.save_png("res://assets/zombies/zombie_runner.png")
