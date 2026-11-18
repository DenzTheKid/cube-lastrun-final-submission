extends SceneTree

# Deterministic Pixel-Art Asset Generator for CUBE: LAST RUN.
# Generates:
# - Clean distant & mid-ground city skylines with structured, clustered window grids
# - Regular static street lamps every 96px along the road edge
# - Clean ground-level RearHorde texture without floating sky/building dots

const OUTLINE := Color8(10, 11, 20, 255)

func _init() -> void:
	print("=== Generating City Skylines, Clustered Windows, Street Lamps, Horde & AAA Pixel UI Art ===")
	_make_clean_horde_wall()
	_make_foreground_overpass()
	_make_city_skylines()
	_make_pixel_button_plates()
	_make_pixel_icons()
	_make_title_logo_and_ribbon()
	_make_empty_and_hero_showcase()
	_make_pixel_hearts()
	_make_wrecked_car_and_medkit()
	_make_vehicle_varieties_and_barrier()
	_make_tactical_shield_assets()
	_make_heal_sfx()
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
	# plus grounded highway guardrail firmly anchored into the curb (y = 212..227).
	var fore := Image.create(480, 270, false, Image.FORMAT_RGBA8)
	var rail_dark := Color8(36, 26, 38, 255)
	var rail_hi := Color8(88, 62, 76, 255)
	var rail_ridge := Color8(62, 44, 54, 255)
	var rail_channel := Color8(24, 17, 26, 255)
	var pole_col := Color8(24, 28, 44, 255)
	var pole_hi := Color8(56, 64, 96, 255)
	var lamp_amber := Color("#f28c38")
	var lamp_core := Color("#fff3b0")

	# Continuous corrugated highway W-beam guardrail (y = 212..218)
	for x in range(480):
		fore.set_pixel(x, 212, OUTLINE)
		fore.set_pixel(x, 213, rail_hi)
		fore.set_pixel(x, 214, rail_ridge)
		fore.set_pixel(x, 215, rail_channel)
		fore.set_pixel(x, 216, rail_ridge)
		fore.set_pixel(x, 217, rail_dark)
		fore.set_pixel(x, 218, OUTLINE)

	# Splicing rivets every 48px
	for sx in range(12, 480, 48):
		fore.set_pixel(sx, 213, Color8(140, 100, 120, 255))
		fore.set_pixel(sx + 1, 213, OUTLINE)
		fore.set_pixel(sx, 217, Color8(140, 100, 120, 255))
		fore.set_pixel(sx + 1, 217, OUTLINE)

	# Guardrail vertical posts (Tiang Pagar) every 24px - anchored firmly into the curb (y = 209..227)
	for gx in range(0, 480, 24):
		for x in range(gx, gx + 4):
			fore.set_pixel(x, 209, OUTLINE)
		for y in range(210, 224):
			fore.set_pixel(gx, y, OUTLINE)
			fore.set_pixel(gx + 1, y, Color8(46, 34, 48, 255))
			fore.set_pixel(gx + 2, y, Color8(70, 50, 72, 255))
			fore.set_pixel(gx + 3, y, OUTLINE)

		# Reinforced baseplate bracket firmly seated on curb at y = 224..227 (ZERO FLOATING)
		for x in range(gx - 2, gx + 6):
			fore.set_pixel(x, 224, Color8(88, 66, 92, 255))
		for y in range(225, 228):
			for x in range(gx - 2, gx + 6):
				if x == gx - 2 or x == gx + 5 or y == 227:
					fore.set_pixel(x, y, OUTLINE)
				elif x == gx - 1 or x == gx + 4:
					fore.set_pixel(x, y, Color8(18, 14, 22, 255))
				else:
					fore.set_pixel(x, y, Color8(52, 40, 56, 255))

	# 5 evenly spaced street lamps (every 96px: x = 36, 132, 228, 324, 420)
	for lx: int in [36, 132, 228, 324, 420]:
		# Vertical mast pole: y = 142 down to y = 223
		for y in range(142, 223):
			fore.set_pixel(lx, y, OUTLINE)
			fore.set_pixel(lx + 1, y, pole_col)
			fore.set_pixel(lx + 2, y, pole_hi)
			fore.set_pixel(lx + 3, y, OUTLINE)

		# Heavy octagonal mounting pedestal at curb (y = 223..227)
		for x in range(lx - 1, lx + 5):
			fore.set_pixel(x, 223, Color8(74, 86, 125, 255))
		for y in range(224, 228):
			for x in range(lx - 3, lx + 7):
				if x == lx - 3 or x == lx + 6 or y == 227:
					fore.set_pixel(x, y, OUTLINE)
				elif x == lx - 2 or x == lx + 5:
					fore.set_pixel(x, y, Color8(18, 22, 36, 255))
				else:
					fore.set_pixel(x, y, Color8(42, 50, 76, 255))

		# Horizontal mast arm
		_draw_rect_outline(fore, lx, 140, 18, 3, pole_col, OUTLINE)
		# Lamp housing & static warm amber bulb
		_draw_rect_outline(fore, lx + 12, 142, 9, 5, pole_col, OUTLINE)
		fore.fill_rect(Rect2i(lx + 13, 145, 7, 2), lamp_amber)
		fore.fill_rect(Rect2i(lx + 14, 145, 5, 1), lamp_core)

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

		# Mostly darkened post-apocalyptic distant towers; only 2 buildings retain a couple dim rooms
		var dist_has_lights: bool = (b_seed == 1 or b_seed == 4)
		var cols: int = (bw - 10) / 6
		var floor_idx: int = 0
		var wy: int = by + 8
		while wy < 214:
			var lit_col: int = -1
			if dist_has_lights and (floor_idx == 2 or floor_idx == 5):
				lit_col = (floor_idx + b_seed) % max(1, cols)

			for c in range(cols):
				var wx: int = bx + 6 + c * 6
				var wcol: Color = win_amber_dim if c == lit_col else win_unlit
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

		# Most buildings keep dark unlit windows (blacked-out city); only a few buildings (idx 1 & 6) keep sparse lit rooms
		var mid_has_lights: bool = (idx == 1 or idx == 6)
		var cols: int = (bw - 10) / 8
		var floor_num: int = 0
		var wy: int = by + 8
		while wy < 214:
			# Subtle horizontal floor divider line
			mid.fill_rect(Rect2i(bx + 2, wy - 2, bw - 4, 1), bcol.darkened(0.15))

			var c_start_a: int = -10
			var c_len_a: int = 0
			var c_col_a: Color = win_amber

			if mid_has_lights:
				if (idx == 1 and (floor_num == 2 or floor_num == 6)):
					c_start_a = 1 if floor_num == 2 else max(0, cols - 2)
					c_len_a = min(2, cols)
					c_col_a = win_amber if floor_num == 2 else win_cyan
				elif (idx == 6 and (floor_num == 3 or floor_num == 7 or floor_num == 10)):
					c_start_a = 2 if floor_num == 3 else 1
					c_len_a = min(2, cols)
					c_col_a = win_cyan if floor_num == 7 else win_amber

			for c in range(cols):
				var wx: int = bx + 6 + c * 8
				var wcol: Color = c_col_a if (c >= c_start_a and c < c_start_a + c_len_a) else mid_unlit
				mid.fill_rect(Rect2i(wx, wy, 4, 6), wcol)
				# Subtle window sill shadow
				mid.fill_rect(Rect2i(wx, wy + 6, 4, 1), OUTLINE)

			wy += 10
			floor_num += 1

	mid.save_png("res://assets/environment/parallax_buildings_mid.png")

func _draw_pixel_keycap_plate(
	w: int, h: int, top_col: Color, bot_col: Color, hi_rim: Color, sh_rim: Color,
	border_col: Color, clasp_hi: Color, clasp_lo: Color, pressed: bool, has_clasp: bool = true
) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var mid_y: int = h / 2
	for y in range(h):
		for x in range(w):
			# 4px stepped 45-degree octagonal pixel chamfer corners (distinct non-boxy arcade badge silhouette)
			var dx: int = mini(x, w - 1 - x)
			var dy: int = mini(y, h - 1 - y)
			if dx + dy <= 2:
				continue
			if dx + dy == 3:
				img.set_pixel(x, y, OUTLINE)
				continue

			# Crisp 1px obsidian outer frame + 1px inner edge
			if x == 0 or x == w - 1 or y == 0 or y == h - 1:
				img.set_pixel(x, y, OUTLINE)
				continue
			if x == 1 or x == w - 2 or y == 1 or y == h - 2 or dx + dy == 4:
				img.set_pixel(x, y, border_col)
				continue

			if not pressed:
				# Bottom 3px thick 3D extruded keycap front lip + 1px shadow crease
				if y >= h - 4 and x >= 2 and x <= w - 3:
					img.set_pixel(x, y, sh_rim if y > h - 4 else sh_rim.darkened(0.28))
					continue
				# Left vertical power clasp tab (solid glowing LED spine, zero hazard stripes)
				if has_clasp and x >= 3 and x <= 5 and y >= 3 and y <= h - 6:
					img.set_pixel(x, y, clasp_hi if y < mid_y else clasp_lo)
					continue
				if has_clasp and x == 6 and y >= 3 and y <= h - 6:
					img.set_pixel(x, y, OUTLINE)
					continue
				# Top 1px specular catchlight
				if y == 2 and x >= 2 and x <= w - 3:
					img.set_pixel(x, y, hi_rim)
				elif y == mid_y and x > (6 if has_clasp else 2) and x <= w - 4:
					img.set_pixel(x, y, bot_col.darkened(0.12))
				else:
					img.set_pixel(x, y, top_col if y < mid_y else bot_col)
			else:
				# Pressed state: top shadow drop + sunk interior
				if y <= 3 and x >= 2 and x <= w - 3:
					img.set_pixel(x, y, sh_rim)
					continue
				if has_clasp and x >= 3 and x <= 5 and y >= 4 and y <= h - 4:
					img.set_pixel(x, y, clasp_lo)
					continue
				if has_clasp and x == 6 and y >= 4 and y <= h - 4:
					img.set_pixel(x, y, OUTLINE)
					continue
				if y == h - 3 and x >= 2 and x <= w - 3:
					img.set_pixel(x, y, hi_rim.darkened(0.3))
				else:
					img.set_pixel(x, y, bot_col.darkened(0.18))

	# Twin precision pixel rivets on right edge (below 1px specular catchlight)
	var r_top: int = 5 if pressed else 4
	var r_bot: int = h - 4 if pressed else h - 6
	_safe_px(img, w - 5, r_top, clasp_hi)
	_safe_px(img, w - 5, r_bot, clasp_lo)
	if not has_clasp:
		_safe_px(img, 4, r_top, clasp_hi)
		_safe_px(img, 4, r_bot, clasp_lo)
		for rx in [4, 5, w - 6, w - 5]:
			_safe_px(img, rx, r_top, clasp_hi)

	return img

func _make_pixel_button_plates() -> void:
	# Primary Action Button Plates (PLAY MISSION / RESUME / TRY AGAIN) — Warm mellow Amber & Crimson 3D keycap
	var pri_idle := _draw_pixel_keycap_plate(
		72, 26,
		Color("#331d2d"), Color("#231424"),
		Color("#f2c879"), Color("#632030"),
		Color("#e08743"), Color("#f5d287"), Color("#d9783b"), false, true
	)
	pri_idle.save_png("res://assets/ui/px_btn_primary_idle.png")

	var pri_hover := _draw_pixel_keycap_plate(
		72, 26,
		Color("#4a2736"), Color("#321a28"),
		Color("#ffe29e"), Color("#7d293a"),
		Color("#f5c26b"), Color("#ffe29e"), Color("#e88c48"), false, true
	)
	pri_hover.save_png("res://assets/ui/px_btn_primary_hover.png")

	var pri_pressed := _draw_pixel_keycap_plate(
		72, 26,
		Color("#2b1724"), Color("#1b0f1b"),
		Color("#d97c3e"), Color("#421520"),
		Color("#d97c3e"), Color("#d97c3e"), Color("#944527"), true, true
	)
	pri_pressed.save_png("res://assets/ui/px_btn_primary_pressed.png")

	# Secondary Action Button Plates (CONTROLS / SFX / BGM / EXIT) — Smooth Brushed Slate-Indigo with Soft Aqua clasp
	var sec_idle := _draw_pixel_keycap_plate(
		72, 26,
		Color("#242d52"), Color("#181e38"),
		Color("#6d7eb5"), Color("#0b0e1c"),
		Color("#3f4c7a"), Color("#4ec8de"), Color("#297b96"), false, true
	)
	sec_idle.save_png("res://assets/ui/px_btn_secondary_idle.png")

	var sec_hover := _draw_pixel_keycap_plate(
		72, 26,
		Color("#2f3966"), Color("#202747"),
		Color("#edb072"), Color("#101426"),
		Color("#e38c46"), Color("#f5d287"), Color("#e38c46"), false, true
	)
	sec_hover.save_png("res://assets/ui/px_btn_secondary_hover.png")

	var sec_pressed := _draw_pixel_keycap_plate(
		72, 26,
		Color("#181e38"), Color("#101426"),
		Color("#4ec8de"), Color("#080a14"),
		Color("#4ec8de"), Color("#e3edf5"), Color("#4ec8de"), true, true
	)
	sec_pressed.save_png("res://assets/ui/px_btn_secondary_pressed.png")

	var btn_dis := _draw_pixel_keycap_plate(
		72, 26,
		Color("#171b2e"), Color("#111321"),
		Color("#2f3654"), Color("#090b14"),
		Color("#272e4d"), Color("#3e486b"), Color("#272e4d"), true, true
	)
	btn_dis.save_png("res://assets/ui/px_btn_disabled.png")

	# Unified Chamfered Panel Plate (Modals, HUD Plates, Controls)
	var panel_plate := _draw_pixel_keycap_plate(
		64, 36,
		Color("#14182b"), Color("#0d101f"),
		Color("#4e5e91"), Color("#080a14"),
		Color("#343e66"), Color("#4ec8de"), Color("#297b96"), false, false
	)
	panel_plate.save_png("res://assets/ui/px_panel_plate.png")

	# Survivor Record Armored Plaque (Chamfered Terminal Badge with soft aqua crest)
	var record_card := _draw_pixel_keycap_plate(
		64, 40,
		Color("#161b30"), Color("#0e1121"),
		Color("#4ec8de"), Color("#080a14"),
		Color("#3f4c7a"), Color("#f5d287"), Color("#e08743"), false, false
	)
	for x in range(8, 56):
		_safe_px(record_card, x, 5, Color("#1f2747"))
		_safe_px(record_card, x, 6, Color("#080912"))
	record_card.save_png("res://assets/ui/px_record_card.png")

func _draw_bitmap_icon(rows: PackedStringArray, col_map: Dictionary) -> Image:
	var h: int = rows.size()
	var w: int = rows[0].length()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var line: String = rows[y]
		for x in range(w):
			var ch: String = line.substr(x, 1)
			if col_map.has(ch):
				img.set_pixel(x, y, col_map[ch])
	return img

func _make_pixel_icons() -> void:
	# 1. Play Mission Chevron + Shell Spark (12x12)
	var play_map := {"o": OUTLINE, "*": Color("#fff3b0"), "#": Color("#f28c38"), "s": Color("#c9384a")}
	_draw_bitmap_icon(PackedStringArray([
		"..oo........",
		".o*#o.......",
		".o**#oo.....",
		".o***##oo...",
		".o****###oo.",
		".o***######o",
		".o***####soo",
		".o**###ssoo.",
		".o*##ssoo...",
		".o#ssoo.....",
		"..ooo.......",
		"............"
	]), play_map).save_png("res://assets/ui/px_icon_play.png")

	# 2. Controls Crosshair / Tactical D-Pad (12x12)
	var ctrl_map := {"o": OUTLINE, "*": Color("#f2f4fa"), "#": Color("#38d8f2"), "s": Color("#1e7e9c")}
	_draw_bitmap_icon(PackedStringArray([
		"....oooo....",
		"...o****o...",
		"...o*##*o...",
		".ooo*##*ooo.",
		"o**##oo##**o",
		"o*#s*##*s#*o",
		"o**##oo##**o",
		".ooos##sooo.",
		"...o####o...",
		"...osssso...",
		"....oooo....",
		"............"
	]), ctrl_map).save_png("res://assets/ui/px_icon_controls.png")

	# 3. SFX On & Off (12x12)
	var sfx_on_map := {"o": OUTLINE, "*": Color("#f2f4fa"), "#": Color("#38d8f2"), "s": Color("#1e7e9c"), "a": Color("#fff3b0")}
	_draw_bitmap_icon(PackedStringArray([
		".....oo.....",
		"....o*#o.oo.",
		"..ooo*#o..ao",
		".o**##*o.o.a",
		"o**####oo.oa",
		"o**####o..oa",
		"o*#####oo.oa",
		".oss###o.o.a",
		"..ooos#o..ao",
		"....os#o.oo.",
		".....oo.....",
		"............"
	]), sfx_on_map).save_png("res://assets/ui/px_icon_sfx_on.png")

	var off_map := {"o": OUTLINE, "*": Color("#707a9c"), "#": Color("#464f70"), "x": Color("#e63962")}
	_draw_bitmap_icon(PackedStringArray([
		".....oo.....",
		"....o*#o....",
		"..ooo*#o.o.o",
		".o**##*ooxxo",
		"o**####ooxxo",
		"o**####o.xx.",
		"o*#####ooxxo",
		".oss###ooxxo",
		"..ooos#o.o.o",
		"....os#o....",
		".....oo.....",
		"............"
	]), off_map).save_png("res://assets/ui/px_icon_sfx_off.png")

	# 4. BGM Music Note On & Off (12x12)
	_draw_bitmap_icon(PackedStringArray([
		"....ooooooo.",
		"...o*******o",
		"...o#######o",
		"...o##oo##o.",
		"...o#o..o#o.",
		"..oo#o..o#o.",
		".o*##o.oo#o.",
		"o***#oo*##o.",
		"o*###oo***o.",
		".oooo..ooo..",
		"............",
		"............"
	]), sfx_on_map).save_png("res://assets/ui/px_icon_music_on.png")

	_draw_bitmap_icon(PackedStringArray([
		"o...ooooooo.",
		"xo.o*******o",
		"oxo#######o.",
		".oxo##oo##o.",
		"..oxo#o.o#o.",
		"..oo#oxo#o..",
		".o*##ooxoo..",
		"o***#o.oxo..",
		"o*###o..oxo.",
		".oooo....oo.",
		"............",
		"............"
	]), off_map).save_png("res://assets/ui/px_icon_music_off.png")

	# 5. Exit Doorway + Arrow (12x12)
	var exit_map := {"o": OUTLINE, "*": Color("#ffb3c6"), "#": Color("#e63962"), "s": Color("#7a2832"), "w": Color("#5c6d9e")}
	_draw_bitmap_icon(PackedStringArray([
		".oooooo.....",
		"owwwwwwo....",
		"ow.oo..o..o.",
		"ow.o*##oooo.",
		"ow.o***####o",
		"ow.o***####o",
		"ow.o#ssoooo.",
		"ow.oo..o..o.",
		"owwwwwwo....",
		".oooooo.....",
		"............",
		"............"
	]), exit_map).save_png("res://assets/ui/px_icon_exit.png")

	# 6. Trophy Medallion Icon for SURVIVOR RECORD (14x14)
	var cup_map := {"o": OUTLINE, "*": Color("#fff8d6"), "#": Color("#f28c38"), "d": Color("#b85822"), "g": Color("#e63962")}
	_draw_bitmap_icon(PackedStringArray([
		"..oooooooooo..",
		".o**********o.",
		"oo*########*oo",
		"o*#o*####*o#*o",
		"oo#o*#gg#*o#oo",
		".oo.*####*.oo.",
		"...oo####oo...",
		".....o##o.....",
		".....o##o.....",
		"....o*##do....",
		"...oo****oo...",
		"..o########o..",
		"..oooooooooo..",
		".............."
	]), cup_map).save_png("res://assets/ui/px_icon_trophy.png")

func _make_title_logo_and_ribbon() -> void:
	# A. Sleek tapered hexagonal ribbon for Tagline ("RUN. SHOOT. SURVIVE. DON'T STOP.")
	var rw: int = 276
	var rh: int = 16
	var rib := Image.create(rw, rh, false, Image.FORMAT_RGBA8)
	var mid_ry: int = rh / 2
	for y in range(rh):
		var inset: int = absi(y - mid_ry)
		if y == 0 or y == rh - 1:
			inset += 2
		for x in range(inset, rw - inset):
			var dist_edge: int = mini(x - inset, (rw - inset - 1) - x)
			if y == 0 or y == rh - 1 or dist_edge == 0:
				rib.set_pixel(x, y, OUTLINE)
			elif y == 1 or y == rh - 2 or dist_edge == 1:
				rib.set_pixel(x, y, Color("#7a2832") if dist_edge > 6 else Color("#f28c38"))
			else:
				rib.set_pixel(x, y, Color("#130e20") if y < mid_ry else Color("#0c0916"))
	# Tapered chevron wing studs on left & right ribbon tips
	for y in range(4, 12):
		var dx: int = absi(y - 7)
		_safe_px(rib, 9 - dx, y, Color("#fff3b0"))
		_safe_px(rib, 10 - dx, y, Color("#f28c38"))
		_safe_px(rib, rw - 10 + dx, y, Color("#fff3b0"))
		_safe_px(rib, rw - 11 + dx, y, Color("#f28c38"))
	rib.save_png("res://assets/ui/px_tagline_ribbon.png")

	# B. Hero Title Crest Sprite (px_title_logo.png, 276x54): Winged Armored Steel Badge + CUBE: + 3D Fiery LAST RUN
	var lw: int = 276
	var lh: int = 54
	var logo := Image.create(lw, lh, false, Image.FORMAT_RGBA8)

	# 1. Tactical Armored Hex Backplate behind LAST RUN (stepped diagonal wings, NOT a flat box)
	for y in range(13, 52):
		var wing_inset: int = 16
		if y < 20:
			wing_inset = 16 + (20 - y) * 2
		elif y > 45:
			wing_inset = 16 + (y - 45) * 2
		for x in range(wing_inset, lw - wing_inset):
			var ex: int = mini(x - wing_inset, lw - wing_inset - 1 - x)
			if y == 13 or y == 51 or ex <= 1:
				logo.set_pixel(x, y, OUTLINE)
			elif y == 14 or y == 50 or ex == 2:
				logo.set_pixel(x, y, Color("#39446e") if y < 32 else Color("#232946"))
			elif y == 15:
				logo.set_pixel(x, y, Color("#f28c38") if (x < 52 or x > lw - 53) else Color("#5c6d9e"))
			else:
				logo.set_pixel(x, y, Color("#121526") if y < 34 else Color("#0c0e1a"))

	# Flared orange-gold kinetic speed chevrons protruding past the wings
	for row in range(3):
		var sy: int = 24 + row * 7
		for k in range(14 - row * 2):
			_safe_px(logo, 4 + row * 2 + k, sy, OUTLINE)
			_safe_px(logo, 4 + row * 2 + k, sy + 1, Color("#f28c38") if k < 6 else Color("#fff3b0"))
			_safe_px(logo, 4 + row * 2 + k, sy + 2, Color("#7a2832"))
			_safe_px(logo, 4 + row * 2 + k, sy + 3, OUTLINE)
			_safe_px(logo, lw - 5 - row * 2 - k, sy, OUTLINE)
			_safe_px(logo, lw - 5 - row * 2 - k, sy + 1, Color("#f28c38") if k < 6 else Color("#fff3b0"))
			_safe_px(logo, lw - 5 - row * 2 - k, sy + 2, Color("#7a2832"))
			_safe_px(logo, lw - 5 - row * 2 - k, sy + 3, OUTLINE)

	# 2. Top CUBE: Badge Header Plate + Twin Shotgun Shell Studs
	for y in range(1, 16):
		var top_cut: int = maxi(0, 5 - y)
		var x0: int = 84 + top_cut
		var x1: int = lw - 84 - top_cut
		for x in range(x0, x1):
			if y == 1 or x == x0 or x == x1 - 1:
				logo.set_pixel(x, y, OUTLINE)
			elif y == 2 or x == x0 + 1 or x == x1 - 2:
				logo.set_pixel(x, y, Color("#38d8f2"))
			else:
				logo.set_pixel(x, y, Color("#19203d") if y < 9 else Color("#101429"))

	# Twin Horizontal Shotgun Shell Studs inside the top header wings (left & right of "CUBE:")
	for side_x in [93, lw - 103]:
		_draw_rect_outline(logo, side_x, 5, 10, 6, Color("#e63962"), OUTLINE)
		logo.fill_rect(Rect2i(side_x + 1, 6, 3, 4), Color("#f28c38"))
		logo.fill_rect(Rect2i(side_x + 4, 6, 4, 1), Color("#fff3b0"))

	# Draw "CUBE:" in chunky metallic sky-cyan pixels (2x crisp blocks)
	var cube_glyphs := {
		"C": PackedStringArray([".####", "##...", "##...", "##...", ".####"]),
		"U": PackedStringArray(["##.##", "##.##", "##.##", "##.##", ".###."]),
		"B": PackedStringArray(["####.", "##.##", "####.", "##.##", "####."]),
		"E": PackedStringArray(["#####", "##...", "####.", "##...", "#####"]),
		":": PackedStringArray(["..", "##", "..", "##", ".."]),
	}
	var cx: int = 110
	for ch in ["C", "U", "B", "E", ":"]:
		var g: PackedStringArray = cube_glyphs[ch]
		for gy in range(g.size()):
			var line: String = g[gy]
			for gx in range(line.length()):
				if line.substr(gx, 1) == "#":
					var px: int = cx + gx * 2
					var py: int = 4 + gy * 2
					for oy in range(-1, 3):
						for ox in range(-1, 3):
							_safe_px(logo, px + ox, py + oy, OUTLINE)
		for gy in range(g.size()):
			var line: String = g[gy]
			for gx in range(line.length()):
				if line.substr(gx, 1) == "#":
					var col: Color = Color("#f2f4fa") if gy <= 1 else (Color("#38d8f2") if gy <= 3 else Color("#1e7e9c"))
					logo.fill_rect(Rect2i(cx + gx * 2, 4 + gy * 2, 2, 2), col)
		cx += (4 if ch == ":" else 10) + 2

	# 3. Hero Monument Typography: "LAST RUN" (bold 2x chamfer-smoothed pixel lettering with 3D extrusion!)
	var hero_glyphs := {
		"L": PackedStringArray(["###.....", "###.....", "###.....", "###.....", "###.....", "###.....", "###.....", "###.....", "###...##", "########", "########"]),
		"A": PackedStringArray(["..#####..", ".#######.", "###...###", "###...###", "###...###", "#########", "#########", "###...###", "###...###", "###...###", "###...###"]),
		"S": PackedStringArray([".#######.", "#########", "###...###", "###......", ".######..", "..######.", "......###", "......###", "###...###", "#########", ".#######."]),
		"T": PackedStringArray(["#########", "#########", "##.###.##", "...###...", "...###...", "...###...", "...###...", "...###...", "...###...", "...###...", "...###..."]),
		"R": PackedStringArray(["#######..", "########.", "###...###", "###...###", "###..###.", "#######..", "########.", "###..###.", "###...###", "###...###", "###...###"]),
		"U": PackedStringArray(["###...###", "###...###", "###...###", "###...###", "###...###", "###...###", "###...###", "###...###", "###...###", "#########", ".#######."]),
		"N": PackedStringArray(["###...###", "####..###", "#####.###", "#########", "#########", "###.#####", "###..####", "###...###", "###...###", "###...###", "###...###"])
	}
	var word: Array[String] = ["L", "A", "S", "T", " ", "R", "U", "N"]
	# Compute total advance to center horizontally
	var total_w: int = 0
	for ch in word:
		if ch == " ":
			total_w += 10
		else:
			total_w += hero_glyphs[ch][0].length() * 2 + 3
	total_w -= 3

	var start_x: int = (lw - total_w) / 2
	var start_y: int = 20

	# First build a crisp binary mask (2x scaled + 1px Scale2X corner chamfers for each glyph)
	var mask := Image.create(lw, lh, false, Image.FORMAT_RGBA8)
	var cur_x: int = start_x
	for ch in word:
		if ch == " ":
			cur_x += 10
			continue
		var g: PackedStringArray = hero_glyphs[ch]
		var gh: int = g.size()
		var gw: int = g[0].length()
		for gy in range(gh):
			for gx in range(gw):
				var on: bool = g[gy].substr(gx, 1) == "#"
				if on:
					var up_on: bool = gy > 0 and g[gy - 1].substr(gx, 1) == "#"
					var dn_on: bool = gy + 1 < gh and g[gy + 1].substr(gx, 1) == "#"
					var lf_on: bool = gx > 0 and g[gy].substr(gx - 1, 1) == "#"
					var rt_on: bool = gx + 1 < gw and g[gy].substr(gx + 1, 1) == "#"
					for sy in range(2):
						for sx in range(2):
							var trim_tl: bool = (sx == 0 and sy == 0 and not up_on and not lf_on and dn_on and rt_on)
							var trim_tr: bool = (sx == 1 and sy == 0 and not up_on and not rt_on and dn_on and lf_on)
							var trim_bl: bool = (sx == 0 and sy == 1 and not dn_on and not lf_on and up_on and rt_on)
							var trim_br: bool = (sx == 1 and sy == 1 and not dn_on and not rt_on and up_on and lf_on)
							if not (trim_tl or trim_tr or trim_bl or trim_br):
								_safe_px(mask, cur_x + gx * 2 + sx, start_y + gy * 2 + sy, Color.WHITE)
		# Add diagonal inner-corner pixel fills where diagonals step cleanly
		for gy in range(gh - 1):
			for gx in range(gw - 1):
				var a: bool = g[gy].substr(gx, 1) == "#"
				var b: bool = g[gy].substr(gx + 1, 1) == "#"
				var c: bool = g[gy + 1].substr(gx, 1) == "#"
				var d: bool = g[gy + 1].substr(gx + 1, 1) == "#"
				if a and d and not b and not c:
					_safe_px(mask, cur_x + gx * 2 + 2, start_y + gy * 2 + 1, Color.WHITE)
					_safe_px(mask, cur_x + gx * 2 + 1, start_y + gy * 2 + 2, Color.WHITE)
				elif b and c and not a and not d:
					_safe_px(mask, cur_x + gx * 2 + 1, start_y + gy * 2 + 1, Color.WHITE)
					_safe_px(mask, cur_x + gx * 2 + 2, start_y + gy * 2 + 2, Color.WHITE)
		cur_x += gw * 2 + 3

	# Pass 1: 3D Extruded Deep Crimson-Plum Drop Shadow Block (dx +1..+3, dy +2..+4) + Obsidian Outline
	for y in range(lh):
		for x in range(lw):
			if mask.get_pixel(x, y).a > 0.5:
				for ez in [3, 2, 1]:
					_safe_px(logo, x + ez - 1, y + ez + 1, OUTLINE)
					_safe_px(logo, x + ez, y + ez + 1, OUTLINE)
	for y in range(lh):
		for x in range(lw):
			if mask.get_pixel(x, y).a > 0.5:
				_safe_px(logo, x + 2, y + 3, Color("#4f1826"))
				_safe_px(logo, x + 1, y + 2, Color("#7a2832"))

	# Pass 2: Bold 1px Obsidian Outline around foreground letters
	for y in range(lh):
		for x in range(lw):
			if mask.get_pixel(x, y).a > 0.5:
				for oy in range(-1, 2):
					for ox in range(-1, 2):
						if ox != 0 or oy != 0:
							_safe_px(logo, x + ox, y + oy, OUTLINE)

	# Pass 3: 4-Stop Fiery Sunset Pixel Fill + Top Cream Specular Rim
	for y in range(lh):
		for x in range(lw):
			if mask.get_pixel(x, y).a > 0.5:
				var rel_y: int = y - start_y
				var is_top_edge: bool = (y > 0 and mask.get_pixel(x, y - 1).a < 0.5)
				var is_bot_edge: bool = (y + 1 < lh and mask.get_pixel(x, y + 1).a < 0.5)
				var col: Color
				if is_top_edge:
					col = Color("#fce5a2")
				elif rel_y <= 4:
					col = Color("#f7d488")
				elif rel_y <= 8:
					col = Color("#f2ac5e")
				elif rel_y <= 12:
					col = Color("#eb834b")
				elif rel_y <= 16:
					col = Color("#de4a68")
				else:
					col = Color("#ad2d4a")
				if is_bot_edge and not is_top_edge:
					col = Color("#7d273b")
				logo.set_pixel(x, y, col)

	logo.save_png("res://assets/ui/px_title_logo.png")

func _make_empty_and_hero_showcase() -> void:
	# 1x1 transparent placeholder so CheckButton hides Godot's default pill toggle even in Editor preview
	var empty_img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	empty_img.save_png("res://assets/ui/px_empty.png")

	var sw: int = 172
	var sh: int = 70

	# A. Centered Full-Width (172x70) Velvety Sunset-Sky Portrait Backdrop matching SURVIVOR RECORD width
	# Uses smooth 8-band dithered twilight-to-peach glow so dark Hero silhouette separates effortlessly without harsh glare.
	var bg := Image.create(sw, sh, false, Image.FORMAT_RGBA8)
	var fx0: int = 0
	var fx1: int = sw - 1
	var fy0: int = 0
	var fy1: int = sh - 1
	var sun_c := Vector2(86.0, 35.0)
	for y in range(sh):
		for x in range(sw):
			var dx: int = mini(x - fx0, fx1 - x)
			var dy: int = mini(y - fy0, fy1 - y)
			if dx + dy <= 2:
				continue
			if dx + dy == 3 or x == fx0 or x == fx1 or y == fy0 or y == fy1:
				bg.set_pixel(x, y, OUTLINE)
				continue
			if x == fx0 + 1 or x == fx1 - 1 or y == fy0 + 1 or y == fy1 - 1 or dx + dy == 4:
				var trim_col: Color = Color("#4ec8de") if y < 16 else (Color("#e08743") if y > 56 else Color("#4a588a"))
				bg.set_pixel(x, y, trim_col)
				continue

			# Dark recessed road deck at bottom behind boots & pedestal
			if y >= 59:
				bg.set_pixel(x, y, Color("#0d101f") if y % 2 == 0 else Color("#14182b"))
				continue

			# Smooth 8-stop dithered twilight-plum -> dusty rose -> mellow peach dusk sky
			var checker: int = (x + y) % 2
			var col: Color
			if y < 11:
				col = Color("#201a3b") if (y < 9 or checker == 0) else Color("#33224a")
			elif y < 20:
				col = Color("#3c244d") if (y < 18 or checker == 0) else Color("#592a4d")
			elif y < 30:
				col = Color("#6e2e49") if (y < 28 or checker == 0) else Color("#8f3747")
			elif y < 40:
				col = Color("#ab4746") if (y < 38 or checker == 0) else Color("#c96248")
			elif y < 50:
				col = Color("#db7c4c") if (y < 48 or checker == 0) else Color("#eb9957")
			else:
				col = Color("#f0ae67") if y < 55 else Color("#de8652")

			# Soft mellow peach-gold sunset disc behind Hero (smoothly dithered edges, no harsh stark yellow)
			var d_sun: float = Vector2(float(x) - sun_c.x, (float(y) - sun_c.y) * 1.12).length()
			if d_sun < 19.0:
				col = Color("#f7cf86")
			elif d_sun < 24.0:
				col = Color("#f7cf86") if checker == 0 else Color("#f2b168")
			elif d_sun < 29.0:
				col = Color("#f2b168") if checker == 0 else Color("#eb9254")
			elif d_sun < 34.0:
				col = Color("#eb9254") if checker == 0 else col
			bg.set_pixel(x, y, col)

	# Softened low city silhouettes on left/right inside window + serene dim pixel stars
	for bld in [[4, 15, 39], [19, 13, 45], [32, 10, 50], [130, 10, 49], [140, 13, 44], [153, 15, 38]]:
		var bx: int = bld[0]
		var bw: int = bld[1]
		var by: int = bld[2]
		for yy in range(by, 59):
			for xx in range(bx, bx + bw):
				bg.set_pixel(xx, yy, Color("#1b213d") if yy < 52 else Color("#12172b"))
		bg.fill_rect(Rect2i(bx, by, bw, 1), Color("#343e66"))
	for st in [[12, 8], [27, 11], [44, 7], [128, 7], [145, 11], [158, 8]]:
		_safe_px(bg, st[0], st[1], Color("#f2d59b"))
	for rx in [4, sw - 5]:
		_safe_px(bg, rx, 4, Color("#f2d59b"))
		_safe_px(bg, rx, sh - 5, Color("#e08743"))
	bg.save_png("res://assets/ui/px_hero_backdrop.png")

	# B. Larger, Smoother-Shaded Centered Flagship Hero Showcase (172 x 70, hero centered at x = 86)
	var hero := Image.create(sw, sh, false, Image.FORMAT_RGBA8)

	# 1. Centered Stepped Asphalt Curb Pedestal at Hero's Feet (y = 58..68, x = 44..128)
	for y in range(58, 69):
		var inset: int = 0
		if y == 58 or y == 68:
			inset = 2
		elif y == 59 or y == 67:
			inset = 1
		for x in range(44 + inset, 129 - inset):
			var ex: int = mini(x - (44 + inset), (128 - inset) - x)
			if y == 58 or y == 68 or ex == 0:
				hero.set_pixel(x, y, OUTLINE)
			elif y == 59:
				hero.set_pixel(x, y, Color("#6f7fb5") if x > 62 else Color("#4ec8de"))
			elif y == 60:
				hero.set_pixel(x, y, Color("#2c3661"))
			elif y >= 65:
				hero.set_pixel(x, y, Color("#0d101f"))
			else:
				hero.set_pixel(x, y, Color("#1a2240"))
	hero.fill_rect(Rect2i(78, 61, 16, 3), Color("#eb9249"))
	hero.fill_rect(Rect2i(79, 61, 14, 1), Color("#f7d488"))

	# Two spent red/brass shotgun shells resting symmetrically at Hero's feet
	_draw_rect_outline(hero, 54, 56, 7, 3, Color("#db4663"), OUTLINE)
	hero.fill_rect(Rect2i(59, 57, 1, 1), Color("#eb9249"))
	_draw_rect_outline(hero, 111, 56, 7, 3, Color("#db4663"), OUTLINE)
	hero.fill_rect(Rect2i(112, 57, 1, 1), Color("#eb9249"))

	# 2. Larger Striding Action Legs & Combat Boots (y = 48..58)
	_draw_rect_outline(hero, 71, 48, 8, 10, Color("#253463"), OUTLINE)
	hero.fill_rect(Rect2i(72, 49, 2, 6), Color("#566aa3"))
	_draw_rect_outline(hero, 69, 53, 10, 6, Color("#141c38"), OUTLINE)
	hero.fill_rect(Rect2i(70, 54, 6, 1), Color("#6375ab"))
	_draw_rect_outline(hero, 92, 48, 8, 10, Color("#1c274d"), OUTLINE)
	hero.fill_rect(Rect2i(93, 49, 2, 6), Color("#42548a"))
	_draw_rect_outline(hero, 92, 53, 10, 6, Color("#11172e"), OUTLINE)
	hero.fill_rect(Rect2i(93, 54, 6, 1), Color("#4e5e94"))

	# 3. Flowing Rose-Crimson Headband Tails waving rightward (x = 108..131)
	for dy in range(2):
		for k in range(21):
			var wave_y: int = 18 + dy * 4 + int(sin(float(k) * 0.42 + float(dy)) * 2.0)
			var rx: int = 108 + k
			var rcol: Color = Color("#e0466b") if k < 13 else Color("#962a48")
			if k < 4:
				rcol = Color("#eb8d52")
			_safe_px(hero, rx, wave_y - 1, OUTLINE)
			_safe_px(hero, rx, wave_y, Color("#ff8ea8") if dy == 0 and k < 9 else rcol)
			_safe_px(hero, rx, wave_y + 1, rcol)
			_safe_px(hero, rx, wave_y + 2, OUTLINE)

	# 4. Larger, Smoother-Shaded Beveled Cube Torso/Head centered cleanly at x = 62..109 (48px wide, y = 12..49)
	var bx0: int = 62
	var bx1: int = 109
	var by0: int = 12
	var by1: int = 49
	for y in range(by0, by1 + 1):
		for x in range(bx0, bx1 + 1):
			var dx: int = mini(x - bx0, bx1 - x)
			var dy: int = mini(y - by0, by1 - y)
			if dx == 0 and dy == 0:
				continue
			if x == bx0 or x == bx1 or y == by0 or y == by1 or (dx == 1 and dy == 1):
				hero.set_pixel(x, y, OUTLINE)
				continue
			if x == bx0 + 1:
				hero.set_pixel(x, y, Color("#56cde3") if y > 26 else Color("#f7d488"))
			elif x == bx1 - 1:
				hero.set_pixel(x, y, Color("#f5c678") if y < 32 else Color("#56cde3"))
			elif y == by0 + 1:
				hero.set_pixel(x, y, Color("#8ea4db"))
			elif x >= 97:
				hero.set_pixel(x, y, Color("#202d57") if y < 32 else Color("#182142"))
			else:
				hero.set_pixel(x, y, Color("#334780") if y < 29 else (Color("#293969") if y < 40 else Color("#212f59")))

	# Utility belt + smooth brass buckle
	hero.fill_rect(Rect2i(64, 43, 33, 2), Color("#0d101f"))
	hero.fill_rect(Rect2i(74, 42, 7, 4), Color("#eb9249"))
	hero.fill_rect(Rect2i(75, 43, 5, 2), Color("#f7d488"))

	# 5. Signature Rose-Crimson Headband Across Brow (y = 16..22)
	for y in range(16, 23):
		for x in range(bx0, bx1 + 1):
			if y == 16 or y == 22:
				hero.set_pixel(x, y, OUTLINE)
			elif x == bx0 + 1:
				hero.set_pixel(x, y, Color("#f7d488"))
			elif x >= 97:
				hero.set_pixel(x, y, Color("#962a48"))
			elif y == 17:
				hero.set_pixel(x, y, Color("#ff8ea8"))
			elif y >= 20:
				hero.set_pixel(x, y, Color("#bd3356"))
			else:
				hero.set_pixel(x, y, Color("#e0466b"))
	_draw_rect_outline(hero, 105, 16, 5, 7, Color("#e0466b"), OUTLINE)
	hero.fill_rect(Rect2i(106, 17, 2, 2), Color("#ff8ea8"))

	# 6. Larger Tactical Dark Visor & Soft Glowing Cyan Eyes (x = 66..91, y = 24..34)
	_draw_rect_outline(hero, 66, 24, 25, 10, Color("#090b14"), OUTLINE)
	hero.fill_rect(Rect2i(67, 25, 23, 1), Color("#233261"))
	for ex in [69, 80]:
		hero.fill_rect(Rect2i(ex, 26, 6, 6), Color("#4ec8de"))
		hero.fill_rect(Rect2i(ex + 1, 27, 4, 4), Color("#80e5f5"))
		hero.fill_rect(Rect2i(ex + 1, 27, 2, 2), Color("#e6f9ff"))

	# 7. Larger Heavy Combat Double-Barrel Shotgun (x = 39..100, angled heroically across chest)
	for i in range(42):
		var gx: int = 39 + i
		var gy: int = 29 + int(float(i) * 0.16)
		_safe_px(hero, gx, gy - 1, OUTLINE)
		_safe_px(hero, gx, gy, Color("#e6eef7") if i < 30 else Color("#9aa9cf"))
		_safe_px(hero, gx, gy + 1, Color("#9aa9cf"))
		_safe_px(hero, gx, gy + 2, Color("#495887"))
		_safe_px(hero, gx, gy + 3, OUTLINE)
	for i in range(32):
		var gx: int = 44 + i
		var gy: int = 33 + int(float(i) * 0.16)
		var is_grip: bool = (i >= 11 and i <= 23)
		_safe_px(hero, gx, gy, Color("#b86632") if is_grip else Color("#536396"))
		_safe_px(hero, gx, gy + 1, Color("#6b3519") if is_grip else Color("#283052"))
		_safe_px(hero, gx, gy + 2, OUTLINE)
	_safe_px(hero, 40, 27, OUTLINE)
	_safe_px(hero, 40, 28, Color("#eb9249"))
	_draw_rect_outline(hero, 76, 35, 9, 6, Color("#43507d"), OUTLINE)
	hero.fill_rect(Rect2i(78, 36, 4, 2), Color("#f7d488"))
	for i in range(17):
		var sx: int = 84 + i
		var sy: int = 36 + int(float(i) * 0.35)
		_safe_px(hero, sx, sy - 1, OUTLINE)
		_safe_px(hero, sx, sy, Color("#e88c48"))
		_safe_px(hero, sx, sy + 1, Color("#b5602d"))
		_safe_px(hero, sx, sy + 2, Color("#6b3519"))
		_safe_px(hero, sx, sy + 3, OUTLINE)

	_draw_rect_outline(hero, 60, 34, 7, 6, Color("#33457d"), OUTLINE)
	hero.fill_rect(Rect2i(61, 35, 3, 2), Color("#56cde3"))
	_draw_rect_outline(hero, 80, 38, 7, 6, Color("#33457d"), OUTLINE)
	hero.fill_rect(Rect2i(81, 39, 3, 2), Color("#697ab5"))

	# Gentle warm muzzle sparkle ahead of barrel tip
	_safe_px(hero, 35, 29, Color("#f7d488"))
	_safe_px(hero, 34, 29, Color("#e88c48"))
	_safe_px(hero, 36, 29, Color("#e88c48"))
	_safe_px(hero, 35, 28, Color("#e88c48"))
	_safe_px(hero, 35, 30, Color("#e88c48"))

	hero.save_png("res://assets/ui/px_hero_showcase.png")

func _make_pixel_hearts() -> void:
	# Smoothly-shaded 20x17 Pixel Hearts (soft rose-blush highlights, velvety ruby body, clear cracked empty heart)
	# Plus upright 14x22 Shotgun Shell icons for clear, well-proportioned HUD Ammo display.
	var outline_soft := Color("#171124")
	var shape := PackedStringArray([
		"...ooooo....ooooo...",
		"..o12221oooo12221o..",
		".o12www2122122222so.",
		"o12ww2222222222222so",
		"o12w22222222222222so",
		"o1222222222222222sso",
		"o2222222222222222sso",
		".o22222222222222sso.",
		".o2222222222222ssso.",
		"..o22222222222ssso..",
		"..oo222222222sssoo..",
		"....o2222222ssso....",
		".....o22222ssso.....",
		"......o222ssso......",
		".......o2ssso.......",
		"........osso........",
		".........oo........."
	])
	var w: int = shape[0].length()
	var h: int = shape.size()
	var full_img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var empty_img := Image.create(w, h, false, Image.FORMAT_RGBA8)

	# Crack path coordinates across empty socket
	var crack := {}
	for pt in [[10, 3], [9, 4], [9, 5], [8, 6], [9, 7], [10, 8], [10, 9], [9, 10], [9, 11], [10, 12]]:
		crack[Vector2i(pt[0], pt[1])] = true

	for y in range(h):
		var row: String = shape[y]
		for x in range(w):
			var ch: String = row.substr(x, 1)
			if ch == ".":
				continue
			if ch == "o":
				full_img.set_pixel(x, y, outline_soft)
				empty_img.set_pixel(x, y, outline_soft)
			else:
				# Full heart 6-stop silky coral-crimson gradient (pleasant, zero stark white)
				var fcol: Color
				if ch == "w":
					fcol = Color("#ffd9e2")
				elif ch == "1":
					fcol = Color("#ff8da8")
				elif ch == "s":
					fcol = Color("#8f2242") if y < 11 else Color("#701833")
				else:
					if y <= 3:
						fcol = Color("#ff7094")
					elif y <= 7:
						fcol = Color("#e3426b")
					elif y <= 11:
						fcol = Color("#c73056")
					else:
						fcol = Color("#a32447")
				full_img.set_pixel(x, y, fcol)

				# Empty heart socket: clearly visible muted steel-indigo rim + dimmed berry crack inside
				var ecol: Color
				if crack.has(Vector2i(x, y)):
					ecol = Color("#120e1c")
				elif crack.has(Vector2i(x - 1, y)):
					ecol = Color("#54293d")
				elif ch == "1":
					ecol = Color("#56669c")
				elif ch == "s":
					ecol = Color("#1f2540")
				elif y <= 3:
					ecol = Color("#3b466e")
				else:
					ecol = Color("#242b47") if x < 10 else Color("#1c223b")
				empty_img.set_pixel(x, y, ecol)

	full_img.save_png("res://assets/ui/px_heart_full.png")
	empty_img.save_png("res://assets/ui/px_heart_empty.png")

	# Upright 14x22 Shotgun Shells (clear & nicely scaled for HUD Bottom-Left)
	var sw_sh: int = 14
	var sh_sh: int = 22
	var sh_full := Image.create(sw_sh, sh_sh, false, Image.FORMAT_RGBA8)
	var sh_empty := Image.create(sw_sh, sh_sh, false, Image.FORMAT_RGBA8)
	for y in range(sh_sh):
		for x in range(sw_sh):
			# Tapered shell tip y=0..2, wider brass rim y=15..21
			var x_min: int = 3
			var x_max: int = 10
			if y == 0 or y == 21:
				x_min = 4; x_max = 9
			elif y >= 15:
				x_min = 2; x_max = 11
			if x < x_min or x > x_max:
				continue
			if x == x_min or x == x_max or y == 0 or y == 21 or (y == 15 and (x == 2 or x == 11)):
				sh_full.set_pixel(x, y, outline_soft)
				sh_empty.set_pixel(x, y, outline_soft)
			elif y == 15:
				sh_full.set_pixel(x, y, outline_soft)
				sh_empty.set_pixel(x, y, outline_soft)
			elif y > 15:
				# Golden-brass head (vs dull weathered bronze when spent)
				var fc: Color = Color("#f5d182") if x <= 5 else (Color("#cf9342") if x <= 8 else Color("#8f5c24"))
				if y == 16:
					fc = Color("#fae0a2") if x <= 6 else fc
				var ec: Color = Color("#70645a") if x <= 5 else Color("#4a413b")
				sh_full.set_pixel(x, y, fc)
				sh_empty.set_pixel(x, y, ec)
			else:
				# Cylindrical crimson shell hull (or dark smoked slate when spent)
				var fc: Color
				if x == 4 or x == 5:
					fc = Color("#ff8299") if y <= 3 else Color("#eb546f")
				elif x <= 8:
					fc = Color("#cc3753") if y % 3 != 1 else Color("#bf2e4a")
				else:
					fc = Color("#8c2038")
				if y == 1:
					fc = Color("#ffa6b8")
				var ec: Color = Color("#545e82") if x <= 5 else Color("#343b57")
				sh_full.set_pixel(x, y, fc)
				sh_empty.set_pixel(x, y, ec)
	sh_full.save_png("res://assets/ui/px_shell_full.png")
	sh_empty.save_png("res://assets/ui/px_shell_empty.png")

func _make_wrecked_car_and_medkit() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/obstacles"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/pickups"))
	var out_col := Color("#0d101f")

	# 1. Stationary Wrecked / Abandoned Ambulance Van (74 x 32) facing left on the highway
	var cw: int = 74
	var ch: int = 32
	var car := Image.create(cw, ch, false, Image.FORMAT_RGBA8)

	# Cohesive softened ambulance palette: pale medical silver-slate + coral-red stripe & cross + rust damage
	var c_roof_hi := Color("#dce6f4")
	var c_body_hi := Color("#c4d2e8")
	var c_body_mid := Color("#a2b4d1")
	var c_body_sh := Color("#6f82a3")
	var c_cab_sh := Color("#546685")
	var c_deep := Color("#14192b")
	var c_rust_dk := Color("#7a372f")
	var c_rust_md := Color("#a84f3b")
	var c_rust_lt := Color("#cc734b")
	var c_glass_dk := Color("#161f38")
	var c_glass_sh := Color("#5bb4c9")
	var c_glass_md := Color("#3b7c96")
	var c_red_hi := Color("#ff7d97")
	var c_red_mid := Color("#db3959")
	var c_red_dk := Color("#991f39")
	var c_tire := Color("#1b2136")
	var c_tire_hi := Color("#323c59")
	var c_rim := Color("#7d8eb3")

	# A. Boxy Rear Ambulance Module (x = 27..70, y = 3..25) with slight roof dent around x = 35..43
	for x in range(27, 71):
		var top_y: int = 4 if (x >= 35 and x <= 43) else 3
		for y in range(top_y, 26):
			var col: Color = c_body_mid
			if y == top_y:
				col = c_roof_hi
			elif y <= top_y + 2:
				col = c_body_hi
			elif y >= 22:
				col = c_body_sh
			if x >= 68 and y > 10:
				col = c_body_sh # rear door shadow panel
			car.set_pixel(x, y, col)

	# B. Forward Van Cab (x = 16..27, y = 5..25)
	for x in range(16, 28):
		var lx: int = x - 16
		var cab_top: int = 5 if lx >= 5 else (5 + (5 - lx) * 2)
		for y in range(cab_top, 26):
			var col: Color = c_body_mid if y < 22 else c_cab_sh
			if y <= cab_top + 1:
				col = c_body_hi
			car.set_pixel(x, y, col)

	# C. Lower Nose / Front Fender (x = 4..16, y = 16..26, slightly nose-sagged)
	for x in range(4, 17):
		var top_y: int = 16 if x >= 8 else 17
		for y in range(top_y, 26):
			var col: Color = c_body_mid if y < 22 else c_cab_sh
			if y == top_y:
				col = c_body_hi
			car.set_pixel(x, y, col)

	# D. Emergency Coral-Crimson Belt Stripe across Cab & Box (y = 17..19)
	for x in range(6, 69):
		if x in [12, 26, 27, 39, 57, 58, 63]:
			continue # chipped/rusted breaks
		var sy0: int = 18 if x <= 16 else 17
		car.set_pixel(x, sy0, c_red_hi if x % 6 == 0 else c_red_mid)
		car.set_pixel(x, sy0 + 1, c_red_mid)
		car.set_pixel(x, sy0 + 2, c_red_dk)

	# E. Unmistakable Bold Medical '+' Cross Emblem on Box Side (x = 42..53, y = 7..15)
	for y in range(7, 16):
		for x in range(42, 54):
			var in_v: bool = (x >= 46 and x <= 49 and y >= 7 and y <= 15)
			var in_h: bool = (x >= 43 and x <= 52 and y >= 10 and y <= 12)
			if in_v or in_h:
				var mcol: Color = c_red_mid
				if (in_v and x == 46 and y <= 11) or (in_h and y == 10 and x <= 48):
					mcol = c_red_hi
				elif x == 49 or y == 15 or (in_h and y == 12):
					mcol = c_red_dk
				car.set_pixel(x, y, mcol)

	# F. Dead Cracked Roof Lightbar on Cab & Box Edge (x = 22..32, y = 1..3)
	for x in range(22, 33):
		var dy: int = 1 if x >= 24 else 2
		if x == 29:
			continue # knocked-out missing shard
		for y in range(dy, 4):
			var lcol: Color = Color("#7d273c") if x <= 25 else (Color("#4c5a7a") if x <= 27 else Color("#285573"))
			if y == dy:
				lcol = Color("#b53c56") if x <= 25 else (Color("#7e8fb5") if x <= 27 else Color("#3c7fa1"))
			car.set_pixel(x, y, lcol)

	# G. Shattered Cab Windshield/Window (x = 18..25) & Barred Medical Box Window (x = 30..37)
	for x in range(18, 26):
		var wt: int = 7 if x >= 21 else 7 + (21 - x) * 2
		for y in range(wt, 15):
			car.set_pixel(x, y, c_glass_dk)
	for gx in [20, 22, 24]:
		_safe_px(car, gx, 7, c_glass_sh)
		_safe_px(car, gx + 1, 8, c_glass_md)
		_safe_px(car, gx, 14, c_glass_md)
	car.fill_rect(Rect2i(30, 8, 8, 5), c_glass_dk)
	for bx in [32, 35]:
		car.fill_rect(Rect2i(bx, 8, 1, 5), Color("#5c6b8c")) # security bars on rear ambulance window
	_safe_px(car, 31, 9, c_glass_sh)
	_safe_px(car, 36, 12, c_glass_md)

	# H. Panel Seams, Ajar Rear Door Crack & Door Handles
	for y in range(6, 25):
		_safe_px(car, 27, y, c_deep)
		if y >= 5:
			_safe_px(car, 60, y, c_deep) # crooked rear box door line
	car.fill_rect(Rect2i(23, 16, 3, 1), Color("#59688a"))
	car.fill_rect(Rect2i(57, 16, 2, 2), Color("#59688a"))

	# I. Rust Corrosion, Cracks & Soot Grime
	for rpt in [
		[12, 20, 4, 2], [22, 21, 5, 3], [29, 22, 6, 3], [35, 3, 7, 2],
		[40, 21, 5, 4], [51, 20, 4, 2], [61, 8, 5, 3], [63, 19, 5, 3]
	]:
		car.fill_rect(Rect2i(rpt[0], rpt[1], rpt[2], rpt[3]), c_rust_dk)
		_safe_px(car, rpt[0] + 1, rpt[1], c_rust_md)
		if rpt[2] >= 4:
			_safe_px(car, rpt[0] + 2, rpt[1] + 1, c_rust_lt)

	# J. Popped Crooked Engine Hood on Front Left (x = 5..16, rising to y=11) + Exposed Engine Block
	for i in range(12):
		var hx: int = 16 - i
		var hy: int = 15 - int(floor(float(i) * 0.34))
		car.fill_rect(Rect2i(hx, hy + 2, 1, maxi(1, 17 - hy)), c_deep)
		car.set_pixel(hx, hy - 1, out_col)
		car.set_pixel(hx, hy, c_roof_hi if i > 3 else c_rust_md)
		car.set_pixel(hx, hy + 1, c_body_mid)
	car.fill_rect(Rect2i(8, 15, 5, 3), Color("#4f5c7a"))
	car.fill_rect(Rect2i(9, 15, 3, 1), Color("#7a8aad"))
	_safe_px(car, 13, 14, c_rust_lt)
	_safe_px(car, 14, 15, Color("#db8d44"))

	# K. Smashed Front Bumper, Dead Hanging Headlight, Rear Step Bumper & Exhaust Pipe
	_draw_rect_outline(car, 1, 21, 5, 4, Color("#495573"), out_col)
	car.fill_rect(Rect2i(2, 22, 3, 1), Color("#7f91b8"))
	_draw_rect_outline(car, 3, 18, 3, 3, Color("#4a3423"), out_col)
	_safe_px(car, 3, 21, Color("#cfa055")) # dangling cracked amber bulb
	_draw_rect_outline(car, 67, 22, 6, 3, Color("#495573"), out_col)
	car.fill_rect(Rect2i(68, 23, 4, 1), Color("#7f91b8"))
	_draw_rect_outline(car, 68, 17, 3, 3, Color("#591c2b"), out_col)
	_safe_px(car, 69, 18, Color("#ab334d")) # dead taillight
	car.fill_rect(Rect2i(68, 25, 5, 2), Color("#5c6887")) # tailpipe

	# L. Deflated Flat Front & Rear Tires sitting flush at y = 31
	for wx in [15, 57]:
		car.fill_rect(Rect2i(wx - 6, 22, 12, 5), c_deep)
		car.fill_rect(Rect2i(wx - 5, 21, 10, 1), out_col)
		for dy in range(22, 32):
			var hw: int = 5
			if dy == 22:
				hw = 3
			elif dy == 23 or dy == 24:
				hw = 4
			elif dy >= 30:
				hw = 6 if wx == 15 else 5 # extra pancaked flat tire
			for dx in range(-hw, hw + 1):
				var tx: int = wx + dx
				var is_rim: bool = (abs(dx) <= 2 and dy >= 25 and dy <= 28)
				var is_edge: bool = (dy == 22 or dy == 31 or abs(dx) == hw)
				if is_edge:
					_safe_px(car, tx, dy, out_col)
				elif is_rim:
					var rc: Color = Color("#94a4c9") if (dx <= 0 and dy <= 26) else (c_rust_md if wx == 57 else c_rim)
					_safe_px(car, tx, dy, rc)
				else:
					_safe_px(car, tx, dy, c_tire_hi if dy <= 24 else c_tire)

	# M. Crisp 1px Outer Silhouette Outline Pass
	var car_copy := car.duplicate() as Image
	for y in range(ch):
		for x in range(cw):
			if car_copy.get_pixel(x, y).a > 0.5:
				continue
			var adj: bool = false
			for off in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var nx: int = x + off.x
				var ny: int = y + off.y
				if nx >= 0 and nx < cw and ny >= 0 and ny < ch and car_copy.get_pixel(nx, ny).a > 0.5:
					adj = true
					break
			if adj:
				car.set_pixel(x, y, out_col)
	car.save_png("res://assets/obstacles/px_wrecked_car.png")

	# 2. Collectible Medical First-Aid Kit (18 x 16)
	var mw: int = 18
	var mh: int = 16
	var med := Image.create(mw, mh, false, Image.FORMAT_RGBA8)
	# Steel top carry handle (x = 5..12, y = 0..3)
	for x in range(5, 13):
		if x >= 6 and x <= 11:
			med.set_pixel(x, 0, out_col)
			med.set_pixel(x, 1, Color("#96a9cc") if x < 10 else Color("#667799"))
		if x == 5 or x == 12:
			med.set_pixel(x, 1, out_col)
			med.set_pixel(x, 2, out_col)
		if x == 6 or x == 11:
			med.set_pixel(x, 2, Color("#667799"))
	# Case shell body (x = 1..16, y = 3..14) with 1px chamfered corners
	for y in range(3, 15):
		for x in range(1, 17):
			var dx: int = mini(x - 1, 16 - x)
			var dy: int = mini(y - 3, 14 - y)
			if dx == 0 and dy == 0:
				continue
			if x == 1 or x == 16 or y == 3 or y == 14 or (dx == 1 and dy == 1):
				med.set_pixel(x, y, out_col)
				continue
			var col: Color
			if y == 4:
				col = Color("#e3ecf7")
			elif y <= 6:
				col = Color("#cad7eb")
			elif y <= 11:
				col = Color("#b3c3db")
			elif y == 12:
				col = Color("#8c9eb8")
			else:
				col = Color("#6b7c96")
			# Warm brass latches at top left/right corners
			if (x in [3, 4, 13, 14]) and y in [4, 5]:
				col = Color("#ebbc6e") if y == 4 else Color("#ab7533")
			elif y == 6:
				col = Color("#7e90ad") # lid seam
			med.set_pixel(x, y, col)
	# Coral-Crimson Medical Cross (+) in center with deep contrast outline
	for y in range(6, 13):
		for x in range(5, 13):
			var in_vert: bool = (x >= 7 and x <= 10 and y >= 6 and y <= 12)
			var in_horz: bool = (x >= 5 and x <= 12 and y >= 8 and y <= 10)
			if in_vert or in_horz:
				var ccol: Color = Color("#e33d5f")
				if (in_vert and x == 7 and y <= 9) or (in_horz and y == 8 and x <= 9):
					ccol = Color("#ff8aa3")
				elif x == 10 or y == 12 or (in_horz and y == 10):
					ccol = Color("#ab203e")
				med.set_pixel(x, y, ccol)
			else:
				# Crisp dark berry halo/shadow under right & bottom of cross
				var adj_l: bool = ((x - 1 >= 7 and x - 1 <= 10 and y >= 6 and y <= 12) or (x - 1 >= 5 and x - 1 <= 12 and y >= 8 and y <= 10))
				var adj_u: bool = ((x >= 7 and x <= 10 and y - 1 >= 6 and y - 1 <= 12) or (x >= 5 and x <= 12 and y - 1 >= 8 and y - 1 <= 10))
				if adj_l or adj_u:
					med.set_pixel(x, y, Color("#6b7c96"))
	med.save_png("res://assets/pickups/px_medkit.png")

func _make_heal_sfx() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/audio"))
	var sr: int = 22050
	var dur: float = 0.28
	var total_samples: int = int(sr * dur)
	var data_bytes: int = total_samples * 2
	var buf := StreamPeerBuffer.new()
	buf.big_endian = false
	buf.put_data("RIFF".to_ascii_buffer())
	buf.put_32(36 + data_bytes)
	buf.put_data("WAVE".to_ascii_buffer())
	buf.put_data("fmt ".to_ascii_buffer())
	buf.put_32(16)
	buf.put_16(1) # PCM
	buf.put_16(1) # Mono
	buf.put_32(sr)
	buf.put_32(sr * 2)
	buf.put_16(2)
	buf.put_16(16)
	buf.put_data("data".to_ascii_buffer())
	buf.put_32(data_bytes)
	for i in range(total_samples):
		var t: float = float(i) / float(sr)
		var is_second: bool = t >= 0.11
		var local_t: float = t - 0.11 if is_second else t
		var f1: float = 783.99 if is_second else 523.25
		var f2: float = 1046.50 if is_second else 659.25
		var env: float = minf(1.0, local_t / 0.008) * exp(-local_t * (12.0 if is_second else 16.0))
		var s: float = (sin(TAU * f1 * t) * 0.58 + sin(TAU * f2 * t) * 0.34) * env
		buf.put_16(int(clampf(s, -1.0, 1.0) * 14500.0))
	var f := FileAccess.open("res://assets/audio/sfx_heal.wav", FileAccess.WRITE)
	if f:
		f.store_buffer(buf.data_array)
		f.close()

func _apply_pixel_outline(img: Image, out_col: Color) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var src := img.duplicate() as Image
	for y in range(h):
		for x in range(w):
			if src.get_pixel(x, y).a > 0.5:
				continue
			for off in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var nx: int = x + off.x
				var ny: int = y + off.y
				if nx >= 0 and nx < w and ny >= 0 and ny < h and src.get_pixel(nx, ny).a > 0.5:
					img.set_pixel(x, y, out_col)
					break

func _draw_flat_tire(img: Image, cx: int, bottom_y: int, is_rusted: bool, extra_flat: bool, out_col: Color) -> void:
	var c_deep := Color("#131829")
	var c_tire := Color("#1b2136")
	var c_tire_hi := Color("#323c59")
	var c_rim := Color("#7d8eb3")
	var c_rust := Color("#a84f3b")
	var top_y: int = bottom_y - 9
	img.fill_rect(Rect2i(cx - 6, top_y, 12, 5), c_deep)
	img.fill_rect(Rect2i(cx - 5, top_y - 1, 10, 1), out_col)
	for dy in range(top_y, bottom_y + 1):
		var rel: int = dy - top_y
		var hw: int = 5
		if rel == 0:
			hw = 3
		elif rel == 1 or rel == 2:
			hw = 4
		elif rel >= 8:
			hw = 6 if extra_flat else 5
		for dx in range(-hw, hw + 1):
			var tx: int = cx + dx
			var is_rim: bool = (abs(dx) <= 2 and rel >= 3 and rel <= 6)
			var is_edge: bool = (rel == 0 or dy == bottom_y or abs(dx) == hw)
			if is_edge:
				_safe_px(img, tx, dy, out_col)
			elif is_rim:
				var rc: Color = Color("#94a4c9") if (dx <= 0 and rel <= 4) else (c_rust if is_rusted else c_rim)
				_safe_px(img, tx, dy, rc)
			else:
				_safe_px(img, tx, dy, c_tire_hi if rel <= 2 else c_tire)

func _make_vehicle_varieties_and_barrier() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/obstacles"))
	var out_col := Color("#0d101f")
	var c_deep := Color("#131829")
	var c_rust_dk := Color("#7a372f")
	var c_rust_md := Color("#a84f3b")
	var c_rust_lt := Color("#cc734b")
	var c_glass_dk := Color("#161f38")
	var c_glass_sh := Color("#5bb4c9")
	var c_glass_md := Color("#3b7c96")

	# ------------------------------------------------------------------
	# 1. Beat-Up Rusted Scrap Sedan (68 x 28) — dusty olive-teal wreck
	# ------------------------------------------------------------------
	var sw: int = 68
	var sh: int = 28
	var sed := Image.create(sw, sh, false, Image.FORMAT_RGBA8)
	var s_roof := Color("#7a948e")
	var s_hi := Color("#5b7573")
	var s_mid := Color("#3f5459")
	var s_sh := Color("#2a3942")
	for x in range(4, 64):
		var top_y: int = 13 if x >= 22 else (14 if x >= 8 else 15)
		var bot_y: int = 23 if x <= 20 else 22
		for y in range(top_y, bot_y + 1):
			sed.set_pixel(x, y, s_hi if y == top_y else (s_sh if y >= bot_y - 2 else s_mid))
	# Cabin + crooked caved roof (x = 20..53)
	for x in range(20, 54):
		var lx: int = x - 20
		var rx: int = 53 - x
		var ry: int = 2
		if lx < 5:
			ry = 2 + (5 - lx) * 2
		elif rx < 5:
			ry = 2 + (5 - rx) * 2
		elif x >= 32 and x <= 40:
			ry = 3
		for y in range(ry, 14):
			sed.set_pixel(x, y, s_roof if y == ry else (s_hi if y == ry + 1 else s_mid))
	# Windows + jagged cyan glass shards
	for x in range(22, 51):
		if x >= 37 and x <= 39:
			continue
		var wt: int = 5 + ((26 - x) * 2 if x < 26 else ((x - 47) * 2 if x > 47 else 0))
		for y in range(wt, 13):
			sed.set_pixel(x, y, c_glass_dk)
	for gx in [26, 28, 32, 35, 42, 46]:
		_safe_px(sed, gx, 5, c_glass_sh)
		_safe_px(sed, gx + 1, 6, c_glass_md)
		_safe_px(sed, gx, 11, c_glass_sh)
	# Heavy rust corrosion, exposed primer door & dented trunk
	sed.fill_rect(Rect2i(27, 13, 12, 9), Color("#634039")) # mismatched replacement rusty door
	for y in range(13, 22):
		_safe_px(sed, 26, y, c_deep)
		_safe_px(sed, 39, y, c_deep)
		_safe_px(sed, 51, y, c_deep)
	for rpt in [[7, 16, 5, 2], [20, 19, 6, 3], [30, 15, 7, 3], [43, 19, 6, 3], [54, 14, 7, 3], [32, 3, 7, 2]]:
		sed.fill_rect(Rect2i(rpt[0], rpt[1], rpt[2], rpt[3]), c_rust_dk)
		_safe_px(sed, rpt[0] + 1, rpt[1], c_rust_md)
		_safe_px(sed, rpt[0] + 3, rpt[1] + 1, c_rust_lt)
	# Popped hood + exposed engine on front left
	for i in range(16):
		var hx: int = 21 - i
		var hy: int = 12 - int(floor(float(i) * 0.25))
		sed.fill_rect(Rect2i(hx, hy + 2, 1, maxi(1, 14 - hy)), c_deep)
		sed.set_pixel(hx, hy - 1, out_col)
		sed.set_pixel(hx, hy, s_roof if i > 3 else c_rust_md)
		sed.set_pixel(hx, hy + 1, s_mid)
	sed.fill_rect(Rect2i(9, 12, 6, 3), Color("#4f5c7a"))
	sed.fill_rect(Rect2i(10, 12, 3, 1), Color("#7a8aad"))
	_safe_px(sed, 14, 11, c_rust_lt)
	_draw_rect_outline(sed, 1, 19, 5, 4, Color("#495573"), out_col)
	_draw_rect_outline(sed, 61, 19, 6, 3, Color("#495573"), out_col)
	_draw_rect_outline(sed, 61, 15, 3, 3, Color("#591c2b"), out_col)
	sed.fill_rect(Rect2i(62, 22, 5, 2), Color("#5c6887"))
	_draw_flat_tire(sed, 16, 27, false, true, out_col)
	_draw_flat_tire(sed, 52, 27, true, false, out_col)
	_apply_pixel_outline(sed, out_col)
	sed.save_png("res://assets/obstacles/px_wrecked_sedan.png")

	# ------------------------------------------------------------------
	# 2. Wrecked Police Cruiser (68 x 29) — navy hood/trunk + silver doors + dead lightbar
	# ------------------------------------------------------------------
	var pw: int = 68
	var ph: int = 29
	var pol := Image.create(pw, ph, false, Image.FORMAT_RGBA8)
	var p_navy_hi := Color("#3e5078")
	var p_navy := Color("#233052")
	var p_navy_sh := Color("#172038")
	var p_wht_hi := Color("#dce6f4")
	var p_wht_md := Color("#b8c8e0")
	var p_wht_sh := Color("#7c8fae")
	# Body base (+1 row offset y = 1..28 for roof lightbar at y = 0..3)
	for x in range(4, 64):
		var is_door: bool = (x >= 24 and x <= 48)
		var top_y: int = 14 if x >= 22 else (15 if x >= 8 else 16)
		var bot_y: int = 24 if x <= 20 else 23
		for y in range(top_y, bot_y + 1):
			var col: Color
			if is_door:
				col = p_wht_hi if y == top_y else (p_wht_sh if y >= bot_y - 2 else p_wht_md)
			else:
				col = p_navy_hi if y == top_y else (p_navy_sh if y >= bot_y - 2 else p_navy)
			pol.set_pixel(x, y, col)
	# Cruiser cabin (pale silver-white roof & dark pillars, x = 20..53, y = 3..14)
	for x in range(20, 54):
		var lx: int = x - 20
		var rx: int = 53 - x
		var ry: int = 3
		if lx < 5:
			ry = 3 + (5 - lx) * 2
		elif rx < 5:
			ry = 3 + (5 - rx) * 2
		elif x >= 34 and x <= 39:
			ry = 4
		for y in range(ry, 15):
			pol.set_pixel(x, y, p_wht_hi if y == ry else (p_wht_md if y <= ry + 2 else p_navy))
	for x in range(22, 51):
		if x >= 37 and x <= 39:
			continue
		var wt: int = 6 + ((26 - x) * 2 if x < 26 else ((x - 47) * 2 if x > 47 else 0))
		for y in range(wt, 14):
			pol.set_pixel(x, y, c_glass_dk)
	for gx in [27, 30, 34, 42, 47]:
		_safe_px(pol, gx, 6, c_glass_sh)
		_safe_px(pol, gx, 13, c_glass_md)
	# Police door gold shield badge + cruiser blue/gold stripe
	for x in range(25, 48):
		pol.set_pixel(x, 19, Color("#2f639e") if x % 5 != 0 else Color("#d9a24c"))
	pol.fill_rect(Rect2i(32, 16, 4, 3), Color("#ebbc63"))
	_safe_px(pol, 33, 17, Color("#996426"))
	for y in range(14, 23):
		_safe_px(pol, 24, y, c_deep)
		_safe_px(pol, 38, y, c_deep)
		_safe_px(pol, 49, y, c_deep)
	# Dead cracked red/blue roof lightbar (y = 0..3, x = 31..43)
	for x in range(31, 44):
		if x == 37:
			continue # busted center dome gap
		for y in range(1, 4):
			var rc: Color = Color("#8f2940") if x < 37 else (Color("#5e6e94") if x == 36 else Color("#285578"))
			if y == 1:
				rc = Color("#bf3b59") if x < 37 else Color("#3c7ea6")
			pol.set_pixel(x, y, rc)
	# Bent front push bullbar + popped hood + rust & bullet marks
	for rpt in [[18, 20, 5, 3], [28, 20, 4, 2], [44, 17, 5, 3], [55, 16, 5, 2], [33, 4, 4, 2]]:
		pol.fill_rect(Rect2i(rpt[0], rpt[1], rpt[2], rpt[3]), c_rust_dk)
		_safe_px(pol, rpt[0] + 1, rpt[1], c_rust_md)
	for i in range(15):
		var hx: int = 21 - i
		var hy: int = 13 - int(floor(float(i) * 0.25))
		pol.fill_rect(Rect2i(hx, hy + 2, 1, maxi(1, 15 - hy)), c_deep)
		pol.set_pixel(hx, hy - 1, out_col)
		pol.set_pixel(hx, hy, p_navy_hi if i > 3 else c_rust_md)
		pol.set_pixel(hx, hy + 1, p_navy)
	pol.fill_rect(Rect2i(9, 13, 6, 3), Color("#4f5c7a"))
	# Police steel ram bullbar on left nose (x = 0..5, y = 16..24)
	_draw_rect_outline(pol, 1, 20, 5, 4, Color("#566385"), out_col)
	pol.fill_rect(Rect2i(1, 16, 2, 5), Color("#6d7da3"))
	pol.fill_rect(Rect2i(2, 17, 3, 2), Color("#3d4863"))
	_draw_rect_outline(pol, 61, 20, 6, 3, Color("#495573"), out_col)
	_draw_rect_outline(pol, 61, 16, 3, 3, Color("#591c2b"), out_col)
	_draw_flat_tire(pol, 16, 28, false, true, out_col)
	_draw_flat_tire(pol, 52, 28, false, false, out_col)
	_apply_pixel_outline(pol, out_col)
	pol.save_png("res://assets/obstacles/px_wrecked_police.png")

	# ------------------------------------------------------------------
	# 3. Wrecked Abandoned City Bus (94 x 34) — long climbable roof & shattered window row
	# ------------------------------------------------------------------
	var bw: int = 94
	var bh: int = 34
	var bus := Image.create(bw, bh, false, Image.FORMAT_RGBA8)
	var b_top := Color("#d9e1ed")
	var b_hi := Color("#b7c4d9")
	var b_mid := Color("#8898b5")
	var b_sh := Color("#54627d")
	var b_stripe_hi := Color("#e8ae54")
	var b_stripe_md := Color("#c77b36")
	var b_teal := Color("#39617a")
	# Main elongated transit bus hull (x = 3..90, y = 3..27) with sloped front windshield nose
	for x in range(3, 91):
		var top_y: int = 3
		if x < 9:
			top_y = 3 + (9 - x) * 2
		elif x >= 44 and x <= 58:
			top_y = 4 # sagged center bus roof panel
		for y in range(top_y, 28):
			var col: Color = b_mid
			if y == top_y:
				col = b_top
			elif y <= top_y + 2:
				col = b_hi
			elif y >= 17 and y <= 20:
				col = b_stripe_md if y >= 19 else b_stripe_hi
			elif y >= 21 and y <= 24:
				col = b_teal
			elif y >= 25:
				col = b_sh
			bus.set_pixel(x, y, col)
	# Roof AC vents & destination board header (x = 8..17, y = 5..7)
	bus.fill_rect(Rect2i(31, 1, 11, 2), Color("#596682"))
	bus.fill_rect(Rect2i(67, 1, 12, 2), Color("#596682"))
	bus.fill_rect(Rect2i(8, 5, 9, 3), Color("#181e30"))
	_safe_px(bus, 10, 6, Color("#ab6433"))
	_safe_px(bus, 12, 6, Color("#ab6433"))
	# 5 Shattered Bus Windows along passenger side (x = 7..84, y = 7..15)
	var win_ranges := [[6, 15], [27, 38], [41, 52], [55, 66], [69, 80]]
	for wr in win_ranges:
		var wx0: int = wr[0]
		var wx1: int = wr[1]
		for x in range(wx0, wx1 + 1):
			var yt: int = 8 if x < 9 else 7
			for y in range(yt, 16):
				bus.set_pixel(x, y, c_glass_dk)
		# Crooked seat silhouette inside + broken cyan glass fangs
		bus.fill_rect(Rect2i(wx0 + 3, 12, 3, 4), Color("#283452"))
		_safe_px(bus, wx0 + 2, 8, c_glass_sh)
		_safe_px(bus, wx1 - 2, 14, c_glass_md)
		_safe_px(bus, wx0 + 6, 7, c_glass_sh)
	# Bent busted folding accordion front transit door (x = 17..24, y = 8..26)
	bus.fill_rect(Rect2i(17, 8, 8, 19), Color("#14192b"))
	bus.fill_rect(Rect2i(18, 9, 3, 17), Color("#637291"))
	bus.fill_rect(Rect2i(22, 11, 2, 14), Color("#3e4a66"))
	bus.fill_rect(Rect2i(18, 10, 2, 5), c_glass_md)
	# Heavy rust streaks, busted rear engine grille & bumpers
	bus.fill_rect(Rect2i(82, 12, 7, 12), Color("#3b4661"))
	for gy in [14, 17, 20]:
		bus.fill_rect(Rect2i(83, gy, 5, 1), c_deep)
	for rpt in [[10, 22, 5, 3], [32, 21, 7, 4], [48, 22, 8, 4], [62, 19, 6, 3], [73, 22, 7, 3], [46, 4, 9, 2]]:
		bus.fill_rect(Rect2i(rpt[0], rpt[1], rpt[2], rpt[3]), c_rust_dk)
		_safe_px(bus, rpt[0] + 1, rpt[1], c_rust_md)
		_safe_px(bus, rpt[0] + 3, rpt[1] + 1, c_rust_lt)
	# Popped rear engine flap / smoked panel at left grille
	_draw_rect_outline(bus, 1, 22, 5, 4, Color("#495573"), out_col)
	_draw_rect_outline(bus, 88, 23, 5, 4, Color("#495573"), out_col)
	_draw_rect_outline(bus, 2, 19, 3, 3, Color("#4a3423"), out_col)
	_draw_flat_tire(bus, 15, 33, false, true, out_col)
	_draw_flat_tire(bus, 74, 33, true, true, out_col)
	_apply_pixel_outline(bus, out_col)
	bus.save_png("res://assets/obstacles/px_wrecked_bus.png")

	# ------------------------------------------------------------------
	# 4. Precast Concrete Jersey Highway Barrier (32 x 26) — replacing ugly red cones!
	# Matches real stepped Jersey barrier silhouette: top bevel, vertical neck,
	# flared concrete base skirt, central slab joint & two bottom drainage notches.
	# ------------------------------------------------------------------
	var bw_j: int = 32
	var bh_j: int = 26
	var bar := Image.create(bw_j, bh_j, false, Image.FORMAT_RGBA8)
	var j_top := Color("#cfd7e3")
	var j_hi := Color("#b3bdc9")
	var j_mid := Color("#8e99aa")
	var j_sh := Color("#6b7687")
	var j_dk := Color("#454e5e")
	var j_seam := Color("#232938")

	for y in range(1, 25):
		# Precast Jersey cross-section profile (tapers inward at top, flares wide at foot y=15..24)
		var inset: int = 5
		if y <= 2:
			inset = 6
		elif y <= 13:
			inset = 5
		elif y <= 18:
			inset = 5 - (y - 13) / 2 # sloped Jersey shoulder flare!
		else:
			inset = 2 # wide sturdy lower foot
		var x0: int = inset
		var x1: int = bw_j - 1 - inset
		for x in range(x0, x1 + 1):
			# Two iconic square forklift/drainage cutouts along bottom foot (y = 22..24)
			var in_pocket: bool = (y >= 22 and ((x >= 6 and x <= 9) or (x >= 22 and x <= 25)))
			if in_pocket:
				continue
			var col: Color
			if y == 1 or y == 2:
				col = j_top if x <= bw_j - 9 else j_hi
			elif y <= 13:
				col = j_hi if x == x0 + 1 else (j_dk if x >= x1 - 1 else j_mid)
			elif y <= 18:
				# Bright angled concrete shoulder catching sunset sky light!
				col = j_top if y <= 15 else j_hi
				if x >= x1 - 2:
					col = j_sh
			else:
				col = j_mid if y <= 21 else j_sh
			# Subtle pixel concrete speckle/aggregate
			if ((x * 7 + y * 13) % 19 == 0) and y > 2 and y < 23:
				col = j_sh if col == j_mid else j_hi
			bar.set_pixel(x, y, col)

	# Vertical precast joint seam splitting two coupled barrier blocks + subtle hairline cracks
	for y in range(1, 25):
		bar.set_pixel(15, y, j_seam)
		bar.set_pixel(16, y, j_dk)
	# Weathering water streaks & chipped edge details
	for sx in [8, 21, 24]:
		bar.fill_rect(Rect2i(sx, 3, 1, 6), j_sh)
	_safe_px(bar, 15, 2, out_col)
	_safe_px(bar, 10, 8, j_dk)
	_safe_px(bar, 11, 9, j_dk)
	_safe_px(bar, 20, 10, j_dk)
	_safe_px(bar, 21, 11, j_dk)
	# Crisp dark interior pocket ceilings
	bar.fill_rect(Rect2i(6, 21, 4, 1), out_col)
	bar.fill_rect(Rect2i(22, 21, 4, 1), out_col)

	_apply_pixel_outline(bar, out_col)
	bar.save_png("res://assets/obstacles/px_concrete_barrier.png")

func _make_tactical_shield_assets() -> void:
	var out_col := Color("#0f1224")

	# 1. Pickup Item Sprite (18 x 18): glowing tactical cobalt/cyan armor shield crate
	var sw: int = 18
	var sh: int = 18
	var item := Image.create(sw, sh, false, Image.FORMAT_RGBA8)
	var s_rim := Color("#9cf9ff")
	var s_hi := Color("#4ec7ff")
	var s_mid := Color("#2378e8")
	var s_sh := Color("#164694")
	var s_core := Color("#ecfeff")

	for y in range(2, 16):
		var half_w: int = 6
		if y <= 3:
			half_w = 5
		elif y <= 9:
			half_w = 6
		elif y == 10 or y == 11:
			half_w = 5
		elif y == 12 or y == 13:
			half_w = 3
		else:
			half_w = 1
		var x0: int = 9 - half_w
		var x1: int = 8 + half_w
		for x in range(x0, x1 + 1):
			var col: Color = s_mid
			if y == 2 or x == x0:
				col = s_rim
			elif y <= 5 or x <= x0 + 2:
				col = s_hi
			elif x >= x1 - 1 or y >= 12:
				col = s_sh
			item.set_pixel(x, y, col)
	# Glowing vertical diamond core inside shield face (distinct from Medkit '+' cross)
	item.fill_rect(Rect2i(8, 4, 2, 8), s_rim)
	item.fill_rect(Rect2i(7, 6, 4, 4), s_rim)
	item.fill_rect(Rect2i(8, 6, 2, 4), s_core)
	_apply_pixel_outline(item, out_col)
	item.save_png("res://assets/pickups/px_shield.png")

	# 2. HUD Tactical Shield Full & Empty Icons (17 x 17) matching px_heart style
	var iw: int = 17
	var ih: int = 17
	var ui_full := Image.create(iw, ih, false, Image.FORMAT_RGBA8)
	var ui_empty := Image.create(iw, ih, false, Image.FORMAT_RGBA8)

	var e_rim := Color("#4d5a82")
	var e_mid := Color("#252d47")
	var e_sh := Color("#151929")

	for y in range(1, 15):
		var half_w: int = 6
		if y == 1:
			half_w = 4
		elif y == 2:
			half_w = 5
		elif y <= 8:
			half_w = 6
		elif y <= 10:
			half_w = 5
		elif y <= 12:
			half_w = 3
		else:
			half_w = 1
		var x0: int = 8 - half_w
		var x1: int = 8 + half_w
		for x in range(x0, x1 + 1):
			var col_f: Color = s_mid
			if y <= 2 or x == x0:
				col_f = s_rim
			elif y <= 6 and x <= 7:
				col_f = s_hi
			elif x >= x1 - 1 or y >= 11:
				col_f = s_sh
			ui_full.set_pixel(x, y, col_f)

			var col_e: Color = e_mid
			if y == 1 or x == x0:
				col_e = e_rim
			elif x >= x1 - 1 or y >= 11:
				col_e = e_sh
			ui_empty.set_pixel(x, y, col_e)

	# Crisp diamond specular core on full icon; subtle diagonal crack on empty
	ui_full.fill_rect(Rect2i(8, 3, 1, 9), s_rim)
	ui_full.fill_rect(Rect2i(7, 5, 3, 5), s_rim)
	ui_full.fill_rect(Rect2i(8, 6, 1, 3), s_core)
	ui_full.fill_rect(Rect2i(6, 7, 5, 1), s_core)
	for c in [[5, 4], [6, 5], [7, 6], [8, 7], [8, 8], [9, 9], [10, 10]]:
		_safe_px(ui_empty, c[0], c[1], out_col)

	_apply_pixel_outline(ui_full, out_col)
	_apply_pixel_outline(ui_empty, out_col)
	ui_full.save_png("res://assets/ui/px_shield_full.png")
	ui_empty.save_png("res://assets/ui/px_shield_empty.png")





