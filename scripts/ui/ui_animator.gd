extends RefCounted
class_name UIAnimator

# Cohesive pixel-art UI styling utility for CUBE: LAST RUN.
# Uses ThemePalette constants, flat fills, crisp 2px borders, 0px corner radius,
# a 2px hover/focus offset, and a clean pixel arrow indicator (>).

const PALETTE = preload("res://scripts/ui/theme_palette.gd")

static var _ui_font: Font = null

static func get_ui_font() -> Font:
	if not _ui_font:
		var sys := SystemFont.new()
		sys.font_names = PackedStringArray(["Consolas", "Lucida Console", "monospace"])
		sys.font_weight = 700
		sys.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		sys.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		sys.hinting = TextServer.HINTING_NONE
		_ui_font = sys
	return _ui_font

static func apply_label_font(lbl: Label, _is_title: bool = false, font_sz: int = 10) -> void:
	if not lbl:
		return
	lbl.add_theme_font_override("font", get_ui_font())
	lbl.add_theme_font_size_override("font_size", font_sz)
	lbl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

static func create_plate_style(border_col: Color = PALETTE.BORDER_IDLE, bg_col: Color = PALETTE.PLATE_BG_ALPHA) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg_col
	box.border_width_left = 2
	box.border_width_top = 2
	box.border_width_right = 2
	box.border_width_bottom = 2
	box.border_color = border_col
	box.corner_radius_top_left = 0
	box.corner_radius_top_right = 0
	box.corner_radius_bottom_right = 0
	box.corner_radius_bottom_left = 0
	box.anti_aliasing = false
	return box

static func style_button(btn: Button, is_primary: bool = false) -> void:
	if not btn:
		return

	var raw_text: String = btn.text.strip_edges().trim_prefix("> ").trim_prefix("▶ ")
	btn.set_meta("base_text", raw_text)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

	var idle_box := StyleBoxFlat.new()
	idle_box.bg_color = PALETTE.PLATE_BG_PRIMARY if is_primary else PALETTE.PLATE_BG
	idle_box.border_width_left = 2
	idle_box.border_width_top = 2
	idle_box.border_width_right = 2
	idle_box.border_width_bottom = 2
	idle_box.border_color = PALETTE.ACCENT_AMBER if is_primary else PALETTE.BORDER_IDLE
	idle_box.content_margin_left = 10
	idle_box.content_margin_right = 10
	idle_box.content_margin_top = 4
	idle_box.content_margin_bottom = 4
	idle_box.anti_aliasing = false

	# Hover & Focus: palette swap + 2px right content offset
	var active_box := idle_box.duplicate() as StyleBoxFlat
	active_box.bg_color = PALETTE.PLATE_BG_PRIMARY_HOVER if is_primary else PALETTE.PLATE_BG_HOVER
	active_box.border_color = PALETTE.ACCENT_AMBER
	active_box.content_margin_left = 12
	active_box.content_margin_right = 8

	# Pressed: 1px downward offset + deeper fill
	var pressed_box := active_box.duplicate() as StyleBoxFlat
	pressed_box.bg_color = PALETTE.PLATE_BG_PRESSED
	pressed_box.border_color = PALETTE.ACCENT_CYAN
	pressed_box.content_margin_top = 5
	pressed_box.content_margin_bottom = 3

	# Disabled
	var disabled_box := idle_box.duplicate() as StyleBoxFlat
	disabled_box.bg_color = Color(0.06, 0.06, 0.10, 0.65)
	disabled_box.border_color = PALETTE.BORDER_SUBTLE

	btn.add_theme_stylebox_override("normal", idle_box)
	btn.add_theme_stylebox_override("hover", active_box)
	btn.add_theme_stylebox_override("focus", active_box)
	btn.add_theme_stylebox_override("pressed", pressed_box)
	btn.add_theme_stylebox_override("disabled", disabled_box)

	btn.add_theme_font_override("font", get_ui_font())
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", PALETTE.ACCENT_AMBER if is_primary else PALETTE.TEXT_PRIMARY)
	btn.add_theme_color_override("font_hover_color", PALETTE.ACCENT_AMBER)
	btn.add_theme_color_override("font_focus_color", PALETTE.ACCENT_AMBER)
	btn.add_theme_color_override("font_pressed_color", PALETTE.ACCENT_CYAN)
	btn.add_theme_color_override("font_disabled_color", PALETTE.TEXT_DIM)
	btn.add_theme_color_override("font_outline_color", PALETTE.BORDER_OUTLINE)
	btn.add_theme_constant_override("outline_size", 2)

	btn.text = "  " + raw_text
	btn.mouse_entered.connect(func(): _set_btn_active(btn, true))
	btn.mouse_exited.connect(func(): _set_btn_active(btn, btn.has_focus()))
	btn.focus_entered.connect(func(): _set_btn_active(btn, true))
	btn.focus_exited.connect(func(): _set_btn_active(btn, false))

static func _set_btn_active(btn: Button, active: bool) -> void:
	if not is_instance_valid(btn):
		return
	var base_text: String = str(btn.get_meta("base_text", btn.text))
	btn.text = ("> " if active else "  ") + base_text

static func style_toggle_button(btn: Button, label_prefix: String) -> void:
	if not btn:
		return
	btn.set_meta("toggle_prefix", label_prefix)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var empty_tex := ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))
	btn.add_theme_icon_override("checked", empty_tex)
	btn.add_theme_icon_override("unchecked", empty_tex)
	btn.add_theme_icon_override("checked_disabled", empty_tex)
	btn.add_theme_icon_override("unchecked_disabled", empty_tex)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_font_override("font", get_ui_font())
	btn.add_theme_font_size_override("font_size", 9)
	btn.add_theme_color_override("font_outline_color", PALETTE.BORDER_OUTLINE)
	btn.add_theme_constant_override("outline_size", 2)
	_update_toggle_visual(btn, btn.button_pressed, false)
	btn.toggled.connect(func(on: bool): _update_toggle_visual(btn, on, btn.has_focus()))
	btn.focus_entered.connect(func(): _update_toggle_visual(btn, btn.button_pressed, true))
	btn.focus_exited.connect(func(): _update_toggle_visual(btn, btn.button_pressed, false))
	btn.mouse_entered.connect(func(): _update_toggle_visual(btn, btn.button_pressed, true))
	btn.mouse_exited.connect(func(): _update_toggle_visual(btn, btn.button_pressed, btn.has_focus()))

static func _update_toggle_visual(btn: Button, is_on: bool, is_focused: bool) -> void:
	if not is_instance_valid(btn):
		return
	var prefix: String = str(btn.get_meta("toggle_prefix", "SFX"))
	# Small indicator square + clear state text
	var sq: String = "■" if is_on else "□"
	btn.text = "%s %s: %s" % [sq, prefix, "ON" if is_on else "OFF"]

	var idle_box := StyleBoxFlat.new()
	idle_box.bg_color = PALETTE.PLATE_BG_HOVER if is_focused else PALETTE.PLATE_BG
	idle_box.border_width_left = 2
	idle_box.border_width_top = 2
	idle_box.border_width_right = 2
	idle_box.border_width_bottom = 2
	if is_focused:
		idle_box.border_color = PALETTE.ACCENT_AMBER
	else:
		idle_box.border_color = PALETTE.ACCENT_CYAN if is_on else PALETTE.BORDER_IDLE
	idle_box.content_margin_left = 7 if is_focused else 6
	idle_box.content_margin_right = 5 if is_focused else 6
	idle_box.content_margin_top = 3
	idle_box.content_margin_bottom = 3
	idle_box.anti_aliasing = false

	btn.add_theme_stylebox_override("normal", idle_box)
	btn.add_theme_stylebox_override("hover", idle_box)
	btn.add_theme_stylebox_override("pressed", idle_box)
	btn.add_theme_stylebox_override("focus", idle_box)

	var col: Color = PALETTE.ACCENT_CYAN if is_on else PALETTE.TEXT_MUTED
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", PALETTE.ACCENT_AMBER if is_focused else col)
	btn.add_theme_color_override("font_pressed_color", col)
	btn.add_theme_color_override("font_focus_color", PALETTE.ACCENT_AMBER)
