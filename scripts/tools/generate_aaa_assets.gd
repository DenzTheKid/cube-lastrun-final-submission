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
	# Primary Action Button Plates (PLAY MISSION / RESUME / TRY AGAIN) — Warm Amber & Crimson 3D cartridge keycap
	var pri_idle := _draw_pixel_keycap_plate(
		72, 26,
		Color("#341b2c"), Color("#221224"),
		Color("#fff3b0"), Color("#6b1e2c"),
		Color("#f28c38"), Color("#fff3b0"), Color("#f28c38"), false, true
	)
	pri_idle.save_png("res://assets/ui/px_btn_primary_idle.png")

	var pri_hover := _draw_pixel_keycap_plate(
		72, 26,
		Color("#4f2433"), Color("#331727"),
		Color("#fff8d6"), Color("#8c2838"),
		Color("#fff3b0"), Color("#fff8d6"), Color("#f28c38"), false, true
	)
	pri_hover.save_png("res://assets/ui/px_btn_primary_hover.png")

	var pri_pressed := _draw_pixel_keycap_plate(
		72, 26,
		Color("#2b1523"), Color("#1b0d1b"),
		Color("#f28c38"), Color("#42121d"),
		Color("#f28c38"), Color("#f28c38"), Color("#a84824"), true, true
	)
	pri_pressed.save_png("res://assets/ui/px_btn_primary_pressed.png")

	# Secondary Action Button Plates (CONTROLS / SFX / BGM / EXIT) — Brushed Steel-Indigo with Cyan clasp
	var sec_idle := _draw_pixel_keycap_plate(
		72, 26,
		Color("#222a4d"), Color("#151a33"),
		Color("#6979b0"), Color("#090b16"),
		Color("#39446e"), Color("#38d8f2"), Color("#1e7e9c"), false, true
	)
	sec_idle.save_png("res://assets/ui/px_btn_secondary_idle.png")

	var sec_hover := _draw_pixel_keycap_plate(
		72, 26,
		Color("#2d3661"), Color("#1d2342"),
		Color("#f2a85c"), Color("#0d101f"),
		Color("#f28c38"), Color("#fff3b0"), Color("#f28c38"), false, true
	)
	sec_hover.save_png("res://assets/ui/px_btn_secondary_hover.png")

	var sec_pressed := _draw_pixel_keycap_plate(
		72, 26,
		Color("#161b33"), Color("#0e1121"),
		Color("#38d8f2"), Color("#06070f"),
		Color("#38d8f2"), Color("#f2f4fa"), Color("#38d8f2"), true, true
	)
	sec_pressed.save_png("res://assets/ui/px_btn_secondary_pressed.png")

	var btn_dis := _draw_pixel_keycap_plate(
		72, 26,
		Color("#141729"), Color("#0e101c"),
		Color("#2b324f"), Color("#080912"),
		Color("#232946"), Color("#3b4466"), Color("#232946"), true, true
	)
	btn_dis.save_png("res://assets/ui/px_btn_disabled.png")

	# Unified Chamfered Panel Plate (Modals, HUD Plates, Controls)
	var panel_plate := _draw_pixel_keycap_plate(
		64, 36,
		Color("#121526"), Color("#0b0d19"),
		Color("#4a588a"), Color("#070810"),
		Color("#2e3659"), Color("#38d8f2"), Color("#1e7e9c"), false, false
	)
	panel_plate.save_png("res://assets/ui/px_panel_plate.png")

	# Survivor Record Armored Plaque (Chamfered Terminal Badge with glowing cyan crest)
	var record_card := _draw_pixel_keycap_plate(
		64, 40,
		Color("#14182b"), Color("#0c0e1a"),
		Color("#38d8f2"), Color("#070810"),
		Color("#39446e"), Color("#fff3b0"), Color("#f28c38"), false, false
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
					col = Color("#fff8d6")
				elif rel_y <= 4:
					col = Color("#fff3b0")
				elif rel_y <= 10:
					col = Color("#f7b267") if rel_y <= 6 else Color("#f28c38")
				elif rel_y <= 16:
					col = Color("#e63962")
				else:
					col = Color("#a8223d")
				if is_bot_edge and not is_top_edge:
					col = Color("#7a2832")
				logo.set_pixel(x, y, col)

	logo.save_png("res://assets/ui/px_title_logo.png")

func _make_empty_and_hero_showcase() -> void:
	# 1x1 transparent placeholder so CheckButton hides Godot's default pill toggle even in Editor preview
	var empty_img := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	empty_img.save_png("res://assets/ui/px_empty.png")

	var sw: int = 158
	var sh: int = 62

	# A. Centered Full-Width (158x62) Chamfered Sunset-Sky Frame Backdrop matching SURVIVOR RECORD width
	# Places a glowing dusk sun corona directly behind the centered Hero so every edge pops clearly.
	var bg := Image.create(sw, sh, false, Image.FORMAT_RGBA8)
	var fx0: int = 0
	var fx1: int = sw - 1
	var fy0: int = 0
	var fy1: int = sh - 1
	var sun_c := Vector2(79.0, 31.0)
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
				var trim_col: Color = Color("#38d8f2") if y < 14 else (Color("#f28c38") if y > 49 else Color("#4a588a"))
				bg.set_pixel(x, y, trim_col)
				continue

			# Dark recessed road deck at bottom behind boots & pedestal
			if y >= 52:
				bg.set_pixel(x, y, Color("#0c0e1b") if y % 2 == 0 else Color("#12162b"))
				continue

			# Base stepped twilight-to-amber dusk sky bands
			var checker: int = (x + y) % 2
			var col: Color
			if y < 12:
				col = Color("#1e183b") if (y < 10 or checker == 0) else Color("#39224d")
			elif y < 22:
				col = Color("#4a234a") if (y < 20 or checker == 0) else Color("#7a2832")
			elif y < 33:
				col = Color("#8f2c38") if (y < 31 or checker == 0) else Color("#c94e36")
			elif y < 44:
				col = Color("#d96a36") if (y < 42 or checker == 0) else Color("#f28c38")
			else:
				col = Color("#f7b267") if y < 49 else Color("#f28c38")

			# Crisp stepped pixel sunset halo centered right behind the Hero (x=79) for high silhouette contrast
			var d_sun: float = Vector2(float(x) - sun_c.x, (float(y) - sun_c.y) * 1.15).length()
			if d_sun < 22.0:
				col = Color("#fff8d6")
			elif d_sun < 27.0:
				col = Color("#fff3b0") if checker == 0 else Color("#f7b267")
			elif d_sun < 33.0:
				col = Color("#f2a85c") if checker == 0 else Color("#f28c38")
			bg.set_pixel(x, y, col)

	# Framing low ruined skyline silhouettes along left/right edges (keeping center sunset halo clear)
	for bld in [[4, 14, 34], [18, 12, 39], [30, 10, 44], [118, 10, 43], [128, 14, 38], [142, 12, 33]]:
		var bx: int = bld[0]
		var bw: int = bld[1]
		var by: int = bld[2]
		for yy in range(by, 52):
			for xx in range(bx, bx + bw):
				bg.set_pixel(xx, yy, Color("#151a30") if yy < 46 else Color("#0f1324"))
		bg.fill_rect(Rect2i(bx, by, bw, 1), Color("#2e3659"))
	# Crisp static mini pixel stars in upper indigo corner sky + golden frame rivets
	for st in [[11, 7], [24, 10], [42, 6], [116, 7], [134, 10], [146, 6]]:
		_safe_px(bg, st[0], st[1], Color("#fff3b0"))
	for rx in [4, sw - 5]:
		_safe_px(bg, rx, 4, Color("#fff3b0"))
		_safe_px(bg, rx, sh - 5, Color("#f28c38"))
	bg.save_png("res://assets/ui/px_hero_backdrop.png")

	# B. Centered Flagship Cube Survivor Hero Showcase (158 x 62 native 1x pixel art, centered at x = 79)
	var hero := Image.create(sw, sh, false, Image.FORMAT_RGBA8)

	# 1. Centered Stepped Asphalt Curb Pedestal at Hero's Feet (y = 51..60, x = 42..116, center = 79)
	for y in range(51, 61):
		var inset: int = 0
		if y == 51 or y == 60:
			inset = 2
		elif y == 52 or y == 59:
			inset = 1
		for x in range(42 + inset, 117 - inset):
			var ex: int = mini(x - (42 + inset), (116 - inset) - x)
			if y == 51 or y == 60 or ex == 0:
				hero.set_pixel(x, y, OUTLINE)
			elif y == 52:
				hero.set_pixel(x, y, Color("#6979b0") if x > 58 else Color("#38d8f2"))
			elif y == 53:
				hero.set_pixel(x, y, Color("#28325c"))
			elif y >= 58:
				hero.set_pixel(x, y, Color("#0a0c18"))
			else:
				hero.set_pixel(x, y, Color("#161c36"))
	hero.fill_rect(Rect2i(72, 54, 14, 3), Color("#f28c38"))
	hero.fill_rect(Rect2i(73, 54, 12, 1), Color("#fff3b0"))

	# Two spent red/brass shotgun shells resting symmetrically on pedestal
	_draw_rect_outline(hero, 51, 49, 6, 3, Color("#e63962"), OUTLINE)
	hero.fill_rect(Rect2i(55, 50, 1, 1), Color("#f28c38"))
	_draw_rect_outline(hero, 102, 49, 6, 3, Color("#e63962"), OUTLINE)
	hero.fill_rect(Rect2i(103, 50, 1, 1), Color("#f28c38"))

	# 2. Striding Action Legs & Combat Boots centered under body (y = 41..51)
	_draw_rect_outline(hero, 66, 42, 7, 9, Color("#22305c"), OUTLINE)
	hero.fill_rect(Rect2i(67, 43, 2, 5), Color("#4e629c"))
	_draw_rect_outline(hero, 64, 47, 9, 5, Color("#121830"), OUTLINE)
	hero.fill_rect(Rect2i(65, 48, 5, 1), Color("#5c6d9e"))
	_draw_rect_outline(hero, 84, 42, 7, 9, Color("#182245"), OUTLINE)
	hero.fill_rect(Rect2i(85, 43, 2, 5), Color("#394980"))
	_draw_rect_outline(hero, 84, 47, 9, 5, Color("#0f1429"), OUTLINE)
	hero.fill_rect(Rect2i(85, 48, 5, 1), Color("#4a588a"))

	# 3. Trailing Headband Ribbon Tails waving dynamically rightward (x = 97..118)
	for dy in range(2):
		for k in range(19):
			var wave_y: int = 16 + dy * 4 + int(sin(float(k) * 0.45 + float(dy)) * 2.0)
			var rx: int = 97 + k
			var rcol: Color = Color("#e63962") if k < 12 else Color("#8f2438")
			if k < 4:
				rcol = Color("#f28c38")
			_safe_px(hero, rx, wave_y - 1, OUTLINE)
			_safe_px(hero, rx, wave_y, Color("#ff85a3") if dy == 0 and k < 8 else rcol)
			_safe_px(hero, rx, wave_y + 1, rcol)
			_safe_px(hero, rx, wave_y + 2, OUTLINE)

	# 4. Main Beveled Heroic Cube Torso/Head centered cleanly at x = 58..99 (center = 78.5, y = 11..43)
	var bx0: int = 58
	var bx1: int = 99
	var by0: int = 11
	var by1: int = 43
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
				hero.set_pixel(x, y, Color("#38d8f2") if y > 22 else Color("#fff3b0"))
			elif x == bx1 - 1:
				hero.set_pixel(x, y, Color("#fff3b0") if y < 29 else Color("#38d8f2"))
			elif y == by0 + 1:
				hero.set_pixel(x, y, Color("#8aa0db"))
			elif x >= 88:
				hero.set_pixel(x, y, Color("#1c294f") if y < 29 else Color("#151e3d"))
			else:
				hero.set_pixel(x, y, Color("#2f4278") if y < 28 else Color("#22325e"))

	# Utility belt + golden buckle
	hero.fill_rect(Rect2i(60, 38, 28, 2), Color("#0a0c18"))
	hero.fill_rect(Rect2i(68, 37, 6, 4), Color("#f28c38"))
	hero.fill_rect(Rect2i(69, 38, 4, 2), Color("#fff3b0"))

	# 5. Signature Crimson Headband Across Forehead (y = 14..19)
	for y in range(14, 20):
		for x in range(bx0, bx1 + 1):
			if y == 14 or y == 19:
				hero.set_pixel(x, y, OUTLINE)
			elif x == bx0 + 1:
				hero.set_pixel(x, y, Color("#fff3b0"))
			elif x >= 88:
				hero.set_pixel(x, y, Color("#8f2438"))
			elif y == 15:
				hero.set_pixel(x, y, Color("#ff85a3"))
			else:
				hero.set_pixel(x, y, Color("#e63962"))
	_draw_rect_outline(hero, 95, 14, 5, 6, Color("#e63962"), OUTLINE)
	hero.fill_rect(Rect2i(96, 15, 2, 2), Color("#ff85a3"))

	# 6. Recessed Dark Visor & Glowing Twin Cyan Eyes (x = 61..83, y = 21..30)
	_draw_rect_outline(hero, 61, 21, 22, 9, Color("#070912"), OUTLINE)
	hero.fill_rect(Rect2i(62, 22, 20, 1), Color("#1e2b54"))
	for ex in [64, 74]:
		hero.fill_rect(Rect2i(ex, 23, 5, 5), Color("#38d8f2"))
		hero.fill_rect(Rect2i(ex + 1, 24, 2, 2), Color("#f2f4fa"))
		_safe_px(hero, ex, 23, Color("#fff8d6"))

	# 7. Heavy Combat Double-Barrel Shotgun held cleanly centered across chest (x = 38..89)
	for i in range(36):
		var gx: int = 38 + i
		var gy: int = 25 + int(float(i) * 0.16)
		_safe_px(hero, gx, gy - 1, OUTLINE)
		_safe_px(hero, gx, gy, Color("#f2f4fa") if i < 26 else Color("#8e9ec7"))
		_safe_px(hero, gx, gy + 1, Color("#8e9ec7"))
		_safe_px(hero, gx, gy + 2, Color("#39446e"))
		_safe_px(hero, gx, gy + 3, OUTLINE)
	for i in range(28):
		var gx: int = 42 + i
		var gy: int = 29 + int(float(i) * 0.16)
		var is_grip: bool = (i >= 10 and i <= 20)
		_safe_px(hero, gx, gy, Color("#a85822") if is_grip else Color("#4a588a"))
		_safe_px(hero, gx, gy + 1, Color("#5e2912") if is_grip else Color("#232946"))
		_safe_px(hero, gx, gy + 2, OUTLINE)
	_safe_px(hero, 39, 23, OUTLINE)
	_safe_px(hero, 39, 24, Color("#f28c38"))
	_draw_rect_outline(hero, 70, 30, 8, 6, Color("#39446e"), OUTLINE)
	hero.fill_rect(Rect2i(72, 31, 3, 2), Color("#fff3b0"))
	for i in range(15):
		var sx: int = 77 + i
		var sy: int = 32 + int(float(i) * 0.35)
		_safe_px(hero, sx, sy - 1, OUTLINE)
		_safe_px(hero, sx, sy, Color("#f28c38"))
		_safe_px(hero, sx, sy + 1, Color("#a85822"))
		_safe_px(hero, sx, sy + 2, Color("#5e2912"))
		_safe_px(hero, sx, sy + 3, OUTLINE)

	_draw_rect_outline(hero, 56, 30, 6, 5, Color("#2c3866"), OUTLINE)
	hero.fill_rect(Rect2i(57, 31, 3, 2), Color("#38d8f2"))
	_draw_rect_outline(hero, 73, 33, 6, 5, Color("#2c3866"), OUTLINE)
	hero.fill_rect(Rect2i(74, 34, 3, 2), Color("#5c6d9e"))

	# Subtle warm barrel gleam spark ahead of muzzle
	_safe_px(hero, 34, 25, Color("#fff3b0"))
	_safe_px(hero, 33, 25, Color("#f28c38"))
	_safe_px(hero, 35, 25, Color("#f28c38"))
	_safe_px(hero, 34, 24, Color("#f28c38"))
	_safe_px(hero, 34, 26, Color("#f28c38"))

	hero.save_png("res://assets/ui/px_hero_showcase.png")

func _make_pixel_hearts() -> void:
	# 14x12 crisp hand-pixelled Heart icons for top-left HUD HP display
	var full_map := {
		"o": OUTLINE,
		"w": Color("#fff8e8"),
		"*": Color("#ff85a3"),
		"#": Color("#e63962"),
		"s": Color("#8f1c37")
	}
	_draw_bitmap_icon(PackedStringArray([
		"..oooo..oooo..",
		".o*##*oo*##*o.",
		"oww###**####so",
		"oww#########so",
		"ow##########so",
		"o*#########sso",
		".o########sso.",
		"..o######sso..",
		"..oo####ssoo..",
		"....o##sso....",
		".....osso.....",
		"......oo......"
	]), full_map).save_png("res://assets/ui/px_heart_full.png")

	var empty_map := {
		"o": OUTLINE,
		"r": Color("#39446e"),
		"e": Color("#12162b"),
		"d": Color("#0b0d19")
	}
	_draw_bitmap_icon(PackedStringArray([
		"..oooo..oooo..",
		".orrrroorrrro.",
		"orreeeooeeeero",
		"oreeeoeeeeedro",
		"oreeoeeeeeedro",
		"oreeoeoeeeedro",
		".oreoeeeeddro.",
		"..oroeeeeddo..",
		"..oooeeddooo..",
		"....oeddoo....",
		".....oooo.....",
		"......oo......"
	]), empty_map).save_png("res://assets/ui/px_heart_empty.png")



