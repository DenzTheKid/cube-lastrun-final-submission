extends RefCounted
class_name UIAnimator

# Shared UI interaction helper for CUBE: LAST RUN.
# Relies on res://assets/ui/game_theme.tres for all fonts and StyleBox definitions
# so fonts and styles are defined in one place rather than per-label by hand.

const PALETTE = preload("res://scripts/ui/theme_palette.gd")

static func style_button(btn: Button, is_primary: bool = false) -> void:
	if not btn:
		return

	var raw_text: String = btn.text.strip_edges().trim_prefix("> ").trim_prefix("▶ ")
	btn.set_meta("base_text", raw_text)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.theme_type_variation = &"PrimaryButton" if is_primary else &"Button"

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
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.theme_type_variation = &"Button"
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
	var sq: String = "■" if is_on else "□"
	var arrow: String = "> " if is_focused else "  "
	btn.text = "%s%s %s:%s" % [arrow, sq, prefix, "ON" if is_on else "OFF"]

	var col: Color = PALETTE.ACCENT_CYAN if is_on else PALETTE.TEXT_DIM
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", PALETTE.ACCENT_AMBER if is_focused else col)
	btn.add_theme_color_override("font_pressed_color", col)
	btn.add_theme_color_override("font_focus_color", PALETTE.ACCENT_AMBER)
