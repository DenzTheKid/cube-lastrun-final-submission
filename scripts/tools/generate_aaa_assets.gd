extends SceneTree

# Deterministic Pixel-Art Asset Generator for CUBE: LAST RUN.
# Generates:
# - Clean distant & mid-ground city skylines with structured, clustered window grids
# - Regular static street lamps every 96px along the road edge
# - Clean ground-level RearHorde texture without floating sky/building dots

const OUTLINE := Color8(10, 11, 20, 255)

func _init() -> void:
	print("=== Generating City Skylines, Clustered Windows, Street Lamps, Horde & Pixel UI Plates ===")
	_make_clean_horde_wall()
	_make_foreground_overpass()
	_make_city_skylines()
	_make_pixel_button_plates()
	print("=== Asset Generation Complete ===")
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

func _safe_px(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, col)

func _make_clean_horde_wall() -> void:
	# RearHorde sits at global_position.y = 212 with centered Sprite2D (128x360 -> y_local -180..+180).
	# Keep horde silhouettes strictly near the road corridor (y_img = 135..215) with ZERO floating sky dots.
	var hw: int = 128
	var hh: int = 360
	var h_img := Image.create(hw, hh, false, Image.FORMAT_RGBA8)

	# Ground-hugging shadow mist & zombie crowd silhouettes only between y = 148..208
	for y in range(148, 210):
		var v_fade: float = sin(clampf(float(y - 148) / 62.0, 0.0, 1.0) * PI)
		for x in range(hw):
			var h_fade: float = pow(1.0 - (float(x) / float(hw)), 1.6)
			var a: float = clampf(h_fade * v_fade * 0.88, 0.0, 0.92)
			if a > 0.02:
				h_img.set_pixel(x, y, Color(0.06, 0.04, 0.09, a))

	# Compact zombie head/arm silhouettes strictly along street level (y = 162..196)
	var silhouettes: Array[Vector3i] = [
		Vector3i(12, 166, 18), Vector3i(28, 170, 22), Vector3i(46, 164, 16),
		Vector3i(62, 172, 20), Vector3i(78, 168, 16), Vector3i(92, 174, 14)
	]
	for s: Vector3i in silhouettes:
		var sx: int = s.x
		var sy: int = s.y
		var sh: int = s.z
		_draw_rect_outline(h_img, sx, sy, 14, sh, Color8(22, 18, 32, 245), OUTLINE)
		# Reaching arm at street level
		_draw_rect_outline(h_img, sx + 10, sy + 5, 10, 4, Color8(28, 22, 38, 245), OUTLINE)
		# Subtle static crimson eye pair on the zombie head (street level only)
		h_img.fill_rect(Rect2i(sx + 9, sy + 3, 2, 2), Color8(230, 57, 98, 240))

	h_img.save_png("res://assets/zombies/horde_wall.png")

func _make_foreground_overpass() -> void:
	# Layer 4 (Parallax 0.60): Regular static street lamps every 96px (5 lamps per 480px repeat)
	# plus rusted highway guardrail along the road edge (y = 213..224).
	var fore := Image.create(480, 270, false, Image.FORMAT_RGBA8)
	var rail_dark := Color8(36, 26, 38, 255)
	var rail_hi := Color8(78, 52, 64, 255)
	var pole_col := Color8(24, 28, 44, 255)
	var pole_hi := Color8(48, 56, 84, 255)
	var lamp_amber := Color("#f28c38")
	var lamp_core := Color("#fff3b0")

	# Continuous guardrail beam along road edge
	_draw_rect_outline(fore, 0, 213, 480, 5, rail_dark, OUTLINE)
	fore.fill_rect(Rect2i(0, 214, 480, 1), rail_hi)
	for gx in range(0, 480, 24):
		_draw_rect_outline(fore, gx, 210, 4, 14, rail_dark, OUTLINE)

	# 5 evenly spaced static street lamps (every 96px: x = 36, 132, 228, 324, 420)
	for lx: int in [36, 132, 228, 324, 420]:
		# Vertical pole
		_draw_rect_outline(fore, lx, 142, 4, 82, pole_col, OUTLINE)
		fore.fill_rect(Rect2i(lx + 2, 143, 1, 79), pole_hi)
		# Horizontal mast arm
		_draw_rect_outline(fore, lx, 140, 16, 4, pole_col, OUTLINE)
		# Lamp housing & static warm amber bulb
		_draw_rect_outline(fore, lx + 12, 142, 8, 4, pole_col, OUTLINE)
		fore.fill_rect(Rect2i(lx + 13, 145, 6, 2), lamp_amber)
		fore.fill_rect(Rect2i(lx + 14, 145, 4, 1), lamp_core)

		# Subtle static pixel-stepped light cone onto the road verge
		for y in range(147, 213):
			var t: float = float(y - 147) / 66.0
			var hw: int = int(lerpf(3.0, 20.0, t))
			var alpha: float = lerpf(0.14, 0.02, t)
			for x in range(lx + 16 - hw, lx + 16 + hw):
				if x >= 0 and x < 480:
					var cur: Color = fore.get_pixel(x, y)
					if cur.a < 0.1:
						fore.set_pixel(x, y, Color(0.95, 0.62, 0.25, alpha))

	fore.save_png("res://assets/environment/parallax_overpass_fore.png")

func _make_city_skylines() -> void:
	# 1. Base Sky Texture (480x270) — 6 clean pixel-art horizontal dusk bands
	var sky := Image.create(480, 270, false, Image.FORMAT_RGBA8)
	var bands: Array[Color] = [
		Color("#0f1021"),
		Color("#1c1530"),
		Color("#2b193d"),
		Color("#522038"),
		Color("#7a2832"),
		Color("#f28c38")
	]
	for y in range(270):
		var b_idx: int = clampi(int((float(y) / 270.0) * float(bands.size())), 0, bands.size() - 1)
		sky.fill_rect(Rect2i(0, y, 480, 1), bands[b_idx])
	sky.save_png("res://assets/environment/parallax_sky.png")

	# 2. Distant Skyline Layer (Parallax 0.10, 480x270)
	# 100% opaque building silhouettes so the setting sun passes cleanly behind them.
	# Deliberate horizontal office window strip clusters; zero random single-pixel noise.
	var dist := Image.create(480, 270, false, Image.FORMAT_RGBA8)
	var sil_col := Color8(22, 18, 36, 255)
	var sil_rim := Color8(46, 32, 62, 255)
	var win_unlit := Color8(14, 12, 24, 255)
	var win_amber_dim := Color8(195, 118, 56, 255)
	var win_cyan_dim := Color8(52, 148, 178, 255)

	# Fixed deterministic distant building specifications: [x, width, top_y, has_spire, cluster_seed]
	var dist_buildings: Array[ Array ] = [
		[0, 44, 118, true, 1],
		[42, 38, 136, false, 2],
		[78, 52, 98, true, 3],
		[128, 40, 128, false, 4],
		[166, 48, 108, true, 5],
		[212, 42, 134, false, 6],
		[252, 54, 94, true, 7],
		[304, 38, 140, false, 8],
		[340, 48, 112, true, 9],
		[386, 46, 126, false, 10],
		[430, 50, 104, true, 11]
	]

	for b: Array in dist_buildings:
		var bx: int = b[0]
		var bw: int = b[1]
		var by: int = b[2]
		var has_spire: bool = b[3]
		var b_seed: int = b[4]

		_draw_rect_outline(dist, bx, by, bw, 270 - by, sil_col, OUTLINE)
		dist.fill_rect(Rect2i(bx + 1, by + 1, bw - 2, 1), sil_rim)

		# Static rooftop spire with a single 2x2 static red beacon tip
		if has_spire:
			var tx: int = bx + bw / 2
			var th: int = 16
			dist.fill_rect(Rect2i(tx, by - th, 2, th), sil_col)
			dist.fill_rect(Rect2i(tx, by - th - 2, 2, 2), Color("#e63962"))

		# Structured floor grid: 3px wide x 3px tall windows, 6px column step, 7px floor step
		var cols: int = (bw - 10) / 6
		var floor_idx: int = 0
		var wy: int = by + 8
		while wy < 214:
			# Deliberate floor pattern: some floors have a contiguous lit cluster of 2-4 windows
			var lit_start: int = -1
			var lit_len: int = 0
			var use_cyan: bool = ((floor_idx + b_seed) % 4 == 0)
			if (floor_idx * 3 + b_seed) % 3 == 0:
				lit_start = (floor_idx + b_seed) % max(1, cols - 2)
				lit_len = 3
			elif (floor_idx + b_seed * 2) % 4 == 1:
				lit_start = (b_seed) % max(1, cols - 1)
				lit_len = 2

			for c in range(cols):
				var wx: int = bx + 6 + c * 6
				var wcol: Color = win_unlit
				if c >= lit_start and c < lit_start + lit_len:
					wcol = win_cyan_dim if use_cyan else win_amber_dim
				dist.fill_rect(Rect2i(wx, wy, 3, 3), wcol)
			wy += 7
			floor_idx += 1

	dist.save_png("res://assets/environment/parallax_skyline_distant.png")

	# 3. Mid-Ground Urban Skyline Layer (Parallax 0.25, 480x270)
	# Dark navy/slate buildings (#161b33, #1f2747) with structured floor-and-bay window grids,
	# clustered warm amber & cyan lit rooms, static rooftop neon sign frames, and water towers.
	var mid := Image.create(480, 270, false, Image.FORMAT_RGBA8)
	var navy_dark := Color("#161b33")
	var navy_slate := Color("#1f2747")
	var mid_rim := Color8(52, 62, 102, 255)
	var mid_unlit := Color8(11, 14, 26, 255)
	var win_amber := Color("#f28c38")
	var win_cyan := Color("#38d8f2")
	var neon_magenta := Color("#e63962")

	# Deterministic mid-ground buildings: [x, width, top_y, style_idx, roof_feature]
	# Note: Gap left around x = 280..335 (uv.x ~ 0.60..0.68) so the setting sun & rising moon
	# have a dramatic canyon vista before sinking behind the mid-ground skyline at y = 138!
	var mid_buildings: Array[ Array ] = [
		[0, 56, 106, 0, "neon_magenta"],
		[62, 52, 82, 1, "tower"],
		[120, 60, 96, 0, "neon_cyan"],
		[186, 48, 122, 1, "ac"],
		[240, 52, 88, 0, "neon_magenta"],
		[298, 48, 134, 1, "ac"],
		[352, 64, 78, 0, "neon_cyan"],
		[422, 58, 102, 1, "tower"]
	]

	for idx in range(mid_buildings.size()):
		var mb: Array = mid_buildings[idx]
		var bx: int = mb[0]
		var bw: int = mb[1]
		var by: int = mb[2]
		var st: int = mb[3]
		var roof_feat: String = mb[4]
		var bcol: Color = navy_dark if st == 0 else navy_slate

		_draw_rect_outline(mid, bx, by, bw, 270 - by, bcol, OUTLINE)
		# Top cornice ledge (3px deep)
		_draw_rect_outline(mid, bx - 1, by, bw + 2, 4, navy_slate.lightened(0.08), OUTLINE)
		mid.fill_rect(Rect2i(bx, by + 1, bw, 1), mid_rim)

		# Static rooftop architecture
		if roof_feat == "neon_magenta" or roof_feat == "neon_cyan":
			var bbw: int = bw - 14
			var ncol: Color = neon_magenta if roof_feat == "neon_magenta" else win_cyan
			_draw_rect_outline(mid, bx + 7, by - 18, bbw, 14, Color8(18, 16, 30, 255), OUTLINE)
			_draw_rect_outline(mid, bx + 9, by - 16, bbw - 4, 10, Color8(14, 12, 24, 255), ncol)
			# Static inner horizontal neon bar
			mid.fill_rect(Rect2i(bx + 13, by - 12, bbw - 12, 2), ncol)
			mid.fill_rect(Rect2i(bx + 11, by - 4, 2, 4), OUTLINE)
			mid.fill_rect(Rect2i(bx + bbw + 1, by - 4, 2, 4), OUTLINE)
		elif roof_feat == "tower":
			_draw_rect_outline(mid, bx + 10, by - 16, 16, 12, Color8(48, 38, 46, 255), OUTLINE)
			_draw_rect_outline(mid, bx + 8, by - 18, 20, 3, Color8(36, 28, 36, 255), OUTLINE)
			mid.fill_rect(Rect2i(bx + 12, by - 4, 2, 4), OUTLINE)
			mid.fill_rect(Rect2i(bx + 22, by - 4, 2, 4), OUTLINE)
		else:
			_draw_rect_outline(mid, bx + 8, by - 7, 16, 7, navy_dark, OUTLINE)
			_draw_rect_outline(mid, bx + 28, by - 5, 12, 5, navy_dark, OUTLINE)

		# Structured window grid: 4px wide x 6px tall windows, 8px column step, 10px floor step
		var cols: int = (bw - 10) / 8
		var floor_num: int = 0
		var wy: int = by + 8
		while wy < 214:
			# Subtle horizontal floor divider line
			mid.fill_rect(Rect2i(bx + 2, wy - 2, bw - 4, 1), bcol.darkened(0.15))

			# Deliberate clustered window lighting per floor (2-3 adjacent lit rooms per cluster)
			var c_start_a: int = -10
			var c_len_a: int = 0
			var c_col_a: Color = win_amber

			var c_start_b: int = -10
			var c_len_b: int = 0
			var c_col_b: Color = win_cyan

			var pat: int = (floor_num * 5 + idx * 3) % 7
			if pat == 0:
				c_start_a = 0
				c_len_a = min(3, cols)
			elif pat == 1:
				c_start_a = max(0, cols - 3)
				c_len_a = min(3, cols)
			elif pat == 2:
				c_start_b = 1
				c_len_b = min(2, max(0, cols - 1))
			elif pat == 3:
				c_start_a = 0
				c_len_a = 2
				c_start_b = max(2, cols - 2)
				c_len_b = 2
			elif pat == 4:
				c_start_a = max(0, (cols / 2) - 1)
				c_len_a = 2
			# pat 5 & 6: unlit floor for natural vertical rhythm

			for c in range(cols):
				var wx: int = bx + 6 + c * 8
				var wcol: Color = mid_unlit
				if c >= c_start_a and c < c_start_a + c_len_a:
					wcol = c_col_a
				elif c >= c_start_b and c < c_start_b + c_len_b:
					wcol = c_col_b
				mid.fill_rect(Rect2i(wx, wy, 4, 6), wcol)
				# Subtle window sill shadow
				mid.fill_rect(Rect2i(wx, wy + 6, 4, 1), OUTLINE)

			wy += 10
			floor_num += 1

	mid.save_png("res://assets/environment/parallax_buildings_mid.png")

func _draw_pixel_keycap_plate(w: int, h: int, top_col: Color, bot_col: Color, hi_rim: Color, sh_rim: Color, border_col: Color, bracket_col: Color, pressed: bool) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var mid_y: int = h / 2
	for y in range(h):
		for x in range(w):
			# 1px pixel-notched corners (classic 16-bit chamfered pixel corner, not rounded)
			if (x == 0 or x == w - 1) and (y == 0 or y == h - 1):
				continue
			# Outer dark outline
			var on_outer_edge: bool = (x == 0 or x == w - 1 or y == 0 or y == h - 1)
			var on_inner_corner: bool = ((x == 1 or x == w - 2) and (y == 1 or y == h - 2))
			if on_outer_edge or on_inner_corner:
				img.set_pixel(x, y, OUTLINE)
				continue

			# Border frame (1px inside outer outline)
			if x == 1 or x == w - 2 or y == 1 or y == h - 2:
				img.set_pixel(x, y, border_col)
				continue

			if not pressed:
				# Top 1px bright specular pixel bevel
				if y == 2 and x >= 2 and x <= w - 3:
					img.set_pixel(x, y, hi_rim)
				# Bottom 2px thick 3D keycap shadow lip
				elif y >= h - 4 and x >= 2 and x <= w - 3:
					img.set_pixel(x, y, sh_rim)
				else:
					# Stepped 2-tone pixel fill
					img.set_pixel(x, y, top_col if y < mid_y else bot_col)
			else:
				# Pressed state: top shadow lip, flat compressed body
				if y <= 3 and x >= 2 and x <= w - 3:
					img.set_pixel(x, y, sh_rim)
				elif y == h - 3 and x >= 2 and x <= w - 3:
					img.set_pixel(x, y, hi_rim.darkened(0.25))
				else:
					img.set_pixel(x, y, bot_col.darkened(0.15))

	# Hand-pixelled L-shaped corner brackets / rivets inside plate for crisp mechanical look
	var b_top: int = 3 if pressed else 2
	var b_bot: int = h - 3 if pressed else h - 5
	for dx in [2, 3, 4]:
		_safe_px(img, dx, b_top, bracket_col)
		_safe_px(img, w - 1 - dx, b_top, bracket_col)
		_safe_px(img, dx, b_bot, bracket_col)
		_safe_px(img, w - 1 - dx, b_bot, bracket_col)
	for dy in range(b_top, min(b_top + 3, h - 2)):
		_safe_px(img, 2, dy, bracket_col)
		_safe_px(img, w - 3, dy, bracket_col)
	for dy in range(max(2, b_bot - 2), b_bot + 1):
		_safe_px(img, 2, dy, bracket_col)
		_safe_px(img, w - 3, dy, bracket_col)

	return img

func _make_pixel_button_plates() -> void:
	# Primary Action Button Plates (PLAY MISSION / RESUME / TRY AGAIN) — Amber/Crimson accent
	var pri_idle := _draw_pixel_keycap_plate(
		64, 24,
		Color("#2e1c2b"), Color("#1e1324"),
		Color("#f2a85c"), Color("#7a2832"),
		Color("#f28c38"), Color("#fff3b0"), false
	)
	pri_idle.save_png("res://assets/ui/px_btn_primary_idle.png")

	var pri_hover := _draw_pixel_keycap_plate(
		64, 24,
		Color("#4a2534"), Color("#2c1626"),
		Color("#fff3b0"), Color("#9e323c"),
		Color("#fff3b0"), Color("#f28c38"), false
	)
	pri_hover.save_png("res://assets/ui/px_btn_primary_hover.png")

	var pri_pressed := _draw_pixel_keycap_plate(
		64, 24,
		Color("#2a1624"), Color("#190d1a"),
		Color("#f28c38"), Color("#521b24"),
		Color("#f28c38"), Color("#fff3b0"), true
	)
	pri_pressed.save_png("res://assets/ui/px_btn_primary_pressed.png")

	# Secondary Action Button Plates (CONTROLS / EXIT GAME / MAIN MENU) — Dark Navy Slate
	var sec_idle := _draw_pixel_keycap_plate(
		64, 24,
		Color("#1c2240"), Color("#12162b"),
		Color("#4a588a"), Color("#0a0c18"),
		Color("#2e3659"), Color("#5c6d9e"), false
	)
	sec_idle.save_png("res://assets/ui/px_btn_secondary_idle.png")

	var sec_hover := _draw_pixel_keycap_plate(
		64, 24,
		Color("#283056"), Color("#191e3a"),
		Color("#f2a85c"), Color("#0e1020"),
		Color("#f28c38"), Color("#fff3b0"), false
	)
	sec_hover.save_png("res://assets/ui/px_btn_secondary_hover.png")

	var sec_pressed := _draw_pixel_keycap_plate(
		64, 24,
		Color("#141930"), Color("#0e1121"),
		Color("#38d8f2"), Color("#070812"),
		Color("#38d8f2"), Color("#f2f4fa"), true
	)
	sec_pressed.save_png("res://assets/ui/px_btn_secondary_pressed.png")

	var btn_dis := _draw_pixel_keycap_plate(
		64, 24,
		Color("#121422"), Color("#0d0f1a"),
		Color("#232946"), Color("#080912"),
		Color("#232946"), Color("#2e3659"), true
	)
	btn_dis.save_png("res://assets/ui/px_btn_disabled.png")

	# Clean Framed Pixel Panel Plate (for Record Card, Menu Backdrop, Modals)
	var panel_plate := _draw_pixel_keycap_plate(
		64, 32,
		Color("#101221"), Color("#0c0e1b"),
		Color("#39446e"), Color("#080912"),
		Color("#2e3659"), Color("#38d8f2"), false
	)
	panel_plate.save_png("res://assets/ui/px_panel_plate.png")

