extends RefCounted
class_name UIAnimator

# AAA-indie UI styling and reactive Tween animation utility for CUBE: LAST RUN.
# Uses custom chamfered pixel-art tactical plates (StyleBoxTexture) with diagonal
# 45-degree cut corners, hazard warning stripes, corner rivets, and crisp pixel-art
# arcade typography (non-antialiased bitmap-rendered SystemFont).

const TEX_PRI_NORM: Texture2D = preload("res://assets/ui/btn_primary_normal.png")
const TEX_PRI_HOV: Texture2D = preload("res://assets/ui/btn_primary_hover.png")
const TEX_SEC_NORM: Texture2D = preload("res://assets/ui/btn_secondary_normal.png")
const TEX_SEC_HOV: Texture2D = preload("res://assets/ui/btn_secondary_hover.png")
const TEX_TOG_ON: Texture2D = preload("res://assets/ui/btn_toggle_on.png")
const TEX_TOG_OFF: Texture2D = preload("res://assets/ui/btn_toggle_off.png")

static var _arcade_title_font: Font = null
static var _tactical_ui_font: Font = null

static func get_title_font() -> Font:
	if not _arcade_title_font:
		var sys := SystemFont.new()
		sys.font_names = PackedStringArray(["Impact", "Bahnschrift", "Arial Black"])
		sys.font_weight = 900
		sys.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		sys.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		var fv := FontVariation.new()
		fv.base_font = sys
		fv.spacing_glyph = 2
		_arcade_title_font = fv
	return _arcade_title_font

static func get_ui_font() -> Font:
	if not _tactical_ui_font:
		var sys := SystemFont.new()
		sys.font_names = PackedStringArray(["Consolas", "Bahnschrift", "Lucida Console"])
		sys.font_weight = 700
		sys.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		sys.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		var fv := FontVariation.new()
		fv.base_font = sys
		fv.spacing_glyph = 1
		_tactical_ui_font = fv
	return _tactical_ui_font

static func apply_label_font(lbl: Label, is_title: bool = false, font_sz: int = 11) -> void:
	if not lbl:
		return
	lbl.add_theme_font_override("font", get_title_font() if is_title else get_ui_font())
	lbl.add_theme_font_size_override("font_size", font_sz)

static func style_button(btn: Button, is_primary: bool = false) -> void:
	if not btn:
		return

	var base_text: String = btn.text.strip_edges().trim_prefix("▶ ")
	btn.set_meta("base_text", base_text)

	var normal_box := StyleBoxTexture.new()
	normal_box.texture = TEX_PRI_NORM if is_primary else TEX_SEC_NORM
	normal_box.texture_margin_left = 16
	normal_box.texture_margin_right = 12
	normal_box.texture_margin_top = 6
	normal_box.texture_margin_bottom = 6
	normal_box.content_margin_left = 18
	normal_box.content_margin_right = 14
	normal_box.content_margin_top = 4
	normal_box.content_margin_bottom = 4

	var hover_box := StyleBoxTexture.new()
	hover_box.texture = TEX_PRI_HOV if is_primary else TEX_SEC_HOV
	hover_box.texture_margin_left = 16
	hover_box.texture_margin_right = 12
	hover_box.texture_margin_top = 6
	hover_box.texture_margin_bottom = 6
	hover_box.content_margin_left = 18
	hover_box.content_margin_right = 14
	hover_box.content_margin_top = 4
	hover_box.content_margin_bottom = 4

	btn.add_theme_stylebox_override("normal", normal_box)
	btn.add_theme_stylebox_override("hover", hover_box)
	btn.add_theme_stylebox_override("focus", hover_box)
	btn.add_theme_stylebox_override("pressed", hover_box)

	btn.add_theme_font_override("font", get_ui_font())
	btn.add_theme_font_size_override("font_size", 12 if is_primary else 10)
	btn.add_theme_color_override("font_color", Color(0.96, 0.96, 1.0, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.35, 1.0))
	btn.add_theme_color_override("font_focus_color", Color(1.0, 0.92, 0.35, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.09, 1.0))
	btn.add_theme_constant_override("outline_size", 2)

	btn.mouse_entered.connect(func(): _on_btn_hover(btn, true))
	btn.mouse_exited.connect(func(): _on_btn_hover(btn, false))
	btn.focus_entered.connect(func(): _on_btn_hover(btn, true))
	btn.focus_exited.connect(func(): _on_btn_hover(btn, false))

static func style_toggle_button(btn: Button, label_prefix: String) -> void:
	if not btn:
		return
	btn.set_meta("toggle_prefix", label_prefix)
	# Hide default CheckButton toggle icon so it looks like a custom tactical badge
	var empty_tex := ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))
	btn.add_theme_icon_override("checked", empty_tex)
	btn.add_theme_icon_override("unchecked", empty_tex)
	btn.add_theme_icon_override("checked_disabled", empty_tex)
	btn.add_theme_icon_override("unchecked_disabled", empty_tex)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_font_override("font", get_ui_font())
	btn.add_theme_font_size_override("font_size", 9)
	btn.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.09, 1.0))
	btn.add_theme_constant_override("outline_size", 2)
	_update_toggle_visual(btn, btn.button_pressed)
	btn.toggled.connect(func(on: bool): _update_toggle_visual(btn, on))

static func _update_toggle_visual(btn: Button, is_on: bool) -> void:
	var prefix: String = str(btn.get_meta("toggle_prefix", "AUDIO"))
	btn.text = "%s: %s" % [prefix, "ON" if is_on else "OFF"]
	var box := StyleBoxTexture.new()
	box.texture = TEX_TOG_ON if is_on else TEX_TOG_OFF
	box.texture_margin_left = 14
	box.texture_margin_right = 10
	box.texture_margin_top = 4
	box.texture_margin_bottom = 4
	box.content_margin_left = 14
	box.content_margin_right = 8
	box.content_margin_top = 3
	box.content_margin_bottom = 3
	btn.add_theme_stylebox_override("normal", box)
	btn.add_theme_stylebox_override("hover", box)
	btn.add_theme_stylebox_override("pressed", box)
	btn.add_theme_stylebox_override("focus", box)
	var col := Color(0.45, 1.0, 0.78, 1.0) if is_on else Color(0.75, 0.55, 0.62, 1.0)
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", col.lightened(0.2))
	btn.add_theme_color_override("font_pressed_color", col)
	btn.add_theme_color_override("font_focus_color", col.lightened(0.2))

static func _on_btn_hover(btn: Button, hovered: bool) -> void:
	if not is_instance_valid(btn) or not btn.is_inside_tree():
		return
	var base_text: String = str(btn.get_meta("base_text", btn.text))
	btn.pivot_offset = btn.size * 0.5
	var tw: Tween = btn.create_tween()
	if hovered:
		btn.text = "▶ " + base_text
		tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		btn.text = base_text
		tw.tween_property(btn, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
