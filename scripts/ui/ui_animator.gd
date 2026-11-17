extends RefCounted
class_name UIAnimator

# AAA-indie UI styling and reactive Tween animation utility for CUBE: LAST RUN.
# Provides beveled dark-slate StyleBox containers with glowing amber/crimson borders,
# hover scale/slide transitions, chevron indicators, and HP pip shatter effects.

static func style_button(btn: Button, is_primary: bool = false) -> void:
	if not btn:
		return

	var base_text: String = btn.text.strip_edges().trim_prefix("▶ ")
	btn.set_meta("base_text", base_text)
	btn.pivot_offset = btn.custom_minimum_size * 0.5
	if btn.pivot_offset == Vector2.ZERO:
		btn.pivot_offset = Vector2(70.0, 13.0)

	# Normal StyleBox: sleek dark-slate beveled container
	var normal_box := StyleBoxFlat.new()
	normal_box.bg_color = Color(0.08, 0.09, 0.15, 0.92)
	normal_box.border_width_left = 3 if is_primary else 2
	normal_box.border_width_top = 1
	normal_box.border_width_right = 1
	normal_box.border_width_bottom = 2
	normal_box.border_color = Color(0.92, 0.32, 0.22, 0.95) if is_primary else Color(0.38, 0.44, 0.62, 0.85)
	normal_box.corner_radius_top_left = 4
	normal_box.corner_radius_top_right = 4
	normal_box.corner_radius_bottom_right = 4
	normal_box.corner_radius_bottom_left = 4
	normal_box.content_margin_left = 10
	normal_box.content_margin_right = 10
	normal_box.content_margin_top = 4
	normal_box.content_margin_bottom = 4

	# Hover / Focus StyleBox: glowing amber/crimson border
	var hover_box := normal_box.duplicate() as StyleBoxFlat
	hover_box.bg_color = Color(0.16, 0.12, 0.22, 0.98)
	hover_box.border_width_left = 4
	hover_box.border_color = Color(1.0, 0.72, 0.22, 1.0)

	# Pressed StyleBox
	var pressed_box := normal_box.duplicate() as StyleBoxFlat
	pressed_box.bg_color = Color(0.28, 0.14, 0.18, 1.0)
	pressed_box.border_color = Color(1.0, 0.92, 0.45, 1.0)

	btn.add_theme_stylebox_override("normal", normal_box)
	btn.add_theme_stylebox_override("hover", hover_box)
	btn.add_theme_stylebox_override("focus", hover_box)
	btn.add_theme_stylebox_override("pressed", pressed_box)
	btn.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.88, 0.35, 1.0))
	btn.add_theme_color_override("font_focus_color", Color(1.0, 0.88, 0.35, 1.0))
	btn.add_theme_font_size_override("font_size", 11 if is_primary else 10)

	btn.mouse_entered.connect(func(): _on_btn_hover(btn, true))
	btn.mouse_exited.connect(func(): _on_btn_hover(btn, false))
	btn.focus_entered.connect(func(): _on_btn_hover(btn, true))
	btn.focus_exited.connect(func(): _on_btn_hover(btn, false))

static func _on_btn_hover(btn: Button, hovered: bool) -> void:
	if not is_instance_valid(btn) or not btn.is_inside_tree():
		return
	var base_text: String = str(btn.get_meta("base_text", btn.text))
	btn.pivot_offset = btn.size * 0.5
	var tw: Tween = btn.create_tween()
	if hovered:
		btn.text = "▶ " + base_text
		tw.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		btn.text = base_text
		tw.tween_property(btn, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

static func create_hud_pill_style(border_col: Color = Color(0.35, 0.42, 0.58, 0.65)) -> StyleBoxFlat:
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(0.06, 0.07, 0.12, 0.78)
	pill.border_width_left = 2
	pill.border_width_top = 1
	pill.border_width_right = 1
	pill.border_width_bottom = 1
	pill.border_color = border_col
	pill.corner_radius_top_left = 4
	pill.corner_radius_top_right = 4
	pill.corner_radius_bottom_right = 4
	pill.corner_radius_bottom_left = 4
	pill.content_margin_left = 6
	pill.content_margin_right = 6
	pill.content_margin_top = 2
	pill.content_margin_bottom = 2
	return pill
