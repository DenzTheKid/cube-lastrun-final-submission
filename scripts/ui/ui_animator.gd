extends RefCounted
class_name UIAnimator

# Shared UI interaction helper for CUBE: LAST RUN.
# Relies on res://assets/ui/game_theme.tres for fonts & 9-slice keycap StyleBoxes
# and attaches crisp nearest-filtered 12x12 pixel icons.

const PALETTE = preload("res://scripts/ui/theme_palette.gd")
const ICON_SFX_ON: Texture2D = preload("res://assets/ui/px_icon_sfx_on.png")
const ICON_SFX_OFF: Texture2D = preload("res://assets/ui/px_icon_sfx_off.png")
const ICON_MUSIC_ON: Texture2D = preload("res://assets/ui/px_icon_music_on.png")
const ICON_MUSIC_OFF: Texture2D = preload("res://assets/ui/px_icon_music_off.png")
static var _cached_empty_icon: Texture2D = null

static func _get_empty_icon() -> Texture2D:
	if not _cached_empty_icon:
		_cached_empty_icon = ImageTexture.create_from_image(Image.create(1, 1, false, Image.FORMAT_RGBA8))
	return _cached_empty_icon

static func style_button(btn: Button, is_primary: bool = false) -> void:
	if not btn:
		return
	if btn.has_meta("styled_btn"):
		return
	btn.set_meta("styled_btn", true)

	var raw_text: String = btn.text.strip_edges().trim_prefix("> ").trim_prefix("▶ ")
	btn.set_meta("base_text", raw_text)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.expand_icon = false
	btn.theme_type_variation = &"PrimaryButton" if is_primary else &"Button"
	btn.text = raw_text
	btn.mouse_entered.connect(func():
		var am = Engine.get_main_loop().root.get_node_or_null("AudioManager") if Engine.get_main_loop() else null
		if am:
			am.play_sfx("ui_hover", 0.04)
	)
	btn.focus_entered.connect(func():
		var am = Engine.get_main_loop().root.get_node_or_null("AudioManager") if Engine.get_main_loop() else null
		if am:
			am.play_sfx("ui_hover", 0.04)
	)

static func style_toggle_button(btn: Button, label_prefix: String) -> void:
	if not btn:
		return
	if btn.has_meta("styled_toggle"):
		return
	btn.set_meta("styled_toggle", true)

	btn.set_meta("toggle_prefix", label_prefix)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var empty_tex := _get_empty_icon()
	btn.add_theme_icon_override("checked", empty_tex)
	btn.add_theme_icon_override("unchecked", empty_tex)
	btn.add_theme_icon_override("checked_disabled", empty_tex)
	btn.add_theme_icon_override("unchecked_disabled", empty_tex)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.expand_icon = false
	btn.theme_type_variation = &"Button"
	_update_toggle_visual(btn, btn.button_pressed, false)
	btn.toggled.connect(func(on: bool):
		_update_toggle_visual(btn, on, btn.has_focus())
		var am = Engine.get_main_loop().root.get_node_or_null("AudioManager") if Engine.get_main_loop() else null
		if am:
			am.play_sfx("ui_toggle", 0.04)
	)
	btn.focus_entered.connect(func():
		_update_toggle_visual(btn, btn.button_pressed, true)
		var am = Engine.get_main_loop().root.get_node_or_null("AudioManager") if Engine.get_main_loop() else null
		if am:
			am.play_sfx("ui_hover", 0.04)
	)
	btn.focus_exited.connect(func(): _update_toggle_visual(btn, btn.button_pressed, false))
	btn.mouse_entered.connect(func():
		_update_toggle_visual(btn, btn.button_pressed, true)
		var am = Engine.get_main_loop().root.get_node_or_null("AudioManager") if Engine.get_main_loop() else null
		if am:
			am.play_sfx("ui_hover", 0.04)
	)
	btn.mouse_exited.connect(func(): _update_toggle_visual(btn, btn.button_pressed, btn.has_focus()))

static func _update_toggle_visual(btn: Button, is_on: bool, is_focused: bool) -> void:
	if not is_instance_valid(btn):
		return
	var prefix: String = str(btn.get_meta("toggle_prefix", "SFX"))
	if prefix == "SFX":
		btn.icon = ICON_SFX_ON if is_on else ICON_SFX_OFF
	else:
		btn.icon = ICON_MUSIC_ON if is_on else ICON_MUSIC_OFF
	btn.text = "%s:%s" % [prefix, "ON" if is_on else "OFF"]

	var col: Color = PALETTE.ACCENT_CYAN if is_on else PALETTE.TEXT_DIM
	btn.add_theme_color_override("font_color", col)
	btn.add_theme_color_override("font_hover_color", PALETTE.ACCENT_AMBER if is_focused else col)
	btn.add_theme_color_override("font_hover_pressed_color", PALETTE.ACCENT_AMBER if is_focused else col)
	btn.add_theme_color_override("font_pressed_color", col)
	btn.add_theme_color_override("font_focus_color", PALETTE.ACCENT_AMBER)
