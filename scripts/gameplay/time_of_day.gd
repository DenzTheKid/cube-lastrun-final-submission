extends Node
class_name TimeOfDay

# Self-contained Day-to-Night cycle controller for CUBE: LAST RUN.
# Drives only the background sky shader and atmospheric depth layer tints.
# Does not touch or feed into any gameplay logic.

const PALETTE = preload("res://scripts/ui/theme_palette.gd")

@export var start_at_day: bool = true
@export var day_hold_seconds: float = 60.0
@export var sun_set_seconds: float = 14.0
@export var night_hold_and_moon_rise_seconds: float = 8.0
@export var loop_cycle: bool = false

# DEBUG SCREENSHOT CAPTURE FLAG (disabled in production after verification)
const DEBUG_CAPTURE_ENABLED: bool = false

var current_phase_t: float = 0.0
var _elapsed_seconds: float = 0.0
var _debug_override_active: bool = false
var _debug_override_t: float = 0.0
var _debug_shot_name: String = ""

var _sky_material: ShaderMaterial = null
var _distant_node: CanvasItem = null
var _mid_node: CanvasItem = null
var _fore_node: CanvasItem = null

func _ready() -> void:
	_check_cmdline_override()
	if _debug_override_active:
		current_phase_t = _debug_override_t
	else:
		current_phase_t = 0.0 if start_at_day else 1.0
	_apply_phase(current_phase_t)
	if DEBUG_CAPTURE_ENABLED and _debug_shot_name != "":
		_run_debug_capture()

func _run_debug_capture() -> void:
	for i in range(6):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	if img:
		var fname: String = _debug_shot_name if _debug_shot_name.ends_with(".png") else (_debug_shot_name + ".png")
		var out_path: String = ProjectSettings.globalize_path("res://documentation/screenshots/" + fname)
		img.save_png(out_path)
		print("[DEBUG_SHOT] Saved " + fname)
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(0)

func bind_layers(sky_mat: ShaderMaterial, distant: CanvasItem, mid: CanvasItem, fore: CanvasItem) -> void:
	_sky_material = sky_mat
	_distant_node = distant
	_mid_node = mid
	_fore_node = fore
	_apply_phase(current_phase_t)

func set_fixed_time(t_val: float) -> void:
	_debug_override_active = true
	_debug_override_t = clampf(t_val, 0.0, 1.0)
	current_phase_t = _debug_override_t
	_apply_phase(current_phase_t)

func _check_cmdline_override() -> void:
	var all_args: PackedStringArray = OS.get_cmdline_args()
	all_args.append_array(OS.get_cmdline_user_args())
	for arg: String in all_args:
		if arg.begins_with("--tod="):
			var val_str: String = arg.trim_prefix("--tod=")
			if val_str.is_valid_float():
				_debug_override_active = true
				_debug_override_t = clampf(val_str.to_float(), 0.0, 1.0)
		elif arg.begins_with("--shot="):
			_debug_shot_name = arg.trim_prefix("--shot=")

func _process(delta: float) -> void:
	if _debug_override_active:
		return

	if not start_at_day:
		current_phase_t = 1.0
		_apply_phase(current_phase_t)
		return

	_elapsed_seconds += delta
	var sunset_end: float = day_hold_seconds + maxf(sun_set_seconds, 0.01)
	var total_cycle: float = sunset_end + maxf(night_hold_and_moon_rise_seconds, 0.01)

	var t_sec: float = _elapsed_seconds
	if loop_cycle:
		t_sec = fmod(_elapsed_seconds, total_cycle)

	if t_sec <= day_hold_seconds:
		# During day_hold_seconds: sun gently descends from high sky (0.0) toward mid-afternoon (0.28)
		current_phase_t = (t_sec / maxf(day_hold_seconds, 0.01)) * 0.28
	elif t_sec <= sunset_end:
		# During sun_set_seconds: sun sinks downward behind the skyline (0.28 -> 0.72) as dusk settles
		var sr: float = (t_sec - day_hold_seconds) / maxf(sun_set_seconds, 0.01)
		current_phase_t = lerpf(0.28, 0.72, smoothstep(0.0, 1.0, clampf(sr, 0.0, 1.0)))
	else:
		# During night_hold_and_moon_rise_seconds: dusk deepens to full night and crescent moon rises (0.72 -> 1.0)
		var mr: float = (t_sec - sunset_end) / maxf(night_hold_and_moon_rise_seconds, 0.01)
		current_phase_t = lerpf(0.72, 1.0, smoothstep(0.0, 1.0, clampf(mr, 0.0, 1.0)))

	_apply_phase(current_phase_t)

func _apply_phase(t: float) -> void:
	t = clampf(t, 0.0, 1.0)

	var zenith: Color
	var upper: Color
	var lower: Color
	var horizon: Color
	var dist_tint: Color
	var mid_tint: Color
	var fore_tint: Color

	# Phase keyframes:
	# 0.00 = Day Start
	# 0.30 = Mid-Afternoon
	# 0.52 = Sun Touching Skyline
	# 0.70 = Dusk (sun set behind skyline)
	# 0.82 = Moment Crescent Moon Appears
	# 1.00 = Full Night
	if t < 0.35:
		var k: float = smoothstep(0.0, 0.35, t)
		zenith = PALETTE.DAY_ZENITH.lerp(PALETTE.AFTERNOON_ZENITH, k)
		upper = PALETTE.DAY_UPPER.lerp(PALETTE.AFTERNOON_UPPER, k)
		lower = PALETTE.DAY_LOWER.lerp(PALETTE.AFTERNOON_LOWER, k)
		horizon = PALETTE.DAY_HORIZON.lerp(PALETTE.AFTERNOON_HORIZON, k)
		dist_tint = PALETTE.DAY_DISTANT_TINT.lerp(PALETTE.AFTERNOON_DISTANT_TINT, k)
		mid_tint = PALETTE.DAY_MID_TINT.lerp(PALETTE.AFTERNOON_MID_TINT, k)
		fore_tint = PALETTE.DAY_FORE_TINT.lerp(PALETTE.AFTERNOON_FORE_TINT, k)
	elif t < 0.70:
		var k: float = smoothstep(0.35, 0.70, t)
		zenith = PALETTE.AFTERNOON_ZENITH.lerp(PALETTE.DUSK_ZENITH, k)
		upper = PALETTE.AFTERNOON_UPPER.lerp(PALETTE.DUSK_UPPER, k)
		lower = PALETTE.AFTERNOON_LOWER.lerp(PALETTE.DUSK_LOWER, k)
		horizon = PALETTE.AFTERNOON_HORIZON.lerp(PALETTE.DUSK_HORIZON, k)
		dist_tint = PALETTE.AFTERNOON_DISTANT_TINT.lerp(PALETTE.DUSK_DISTANT_TINT, k)
		mid_tint = PALETTE.AFTERNOON_MID_TINT.lerp(PALETTE.DUSK_MID_TINT, k)
		fore_tint = PALETTE.AFTERNOON_FORE_TINT.lerp(PALETTE.DUSK_FORE_TINT, k)
	else:
		var k: float = smoothstep(0.70, 1.0, t)
		zenith = PALETTE.DUSK_ZENITH.lerp(PALETTE.NIGHT_ZENITH, k)
		upper = PALETTE.DUSK_UPPER.lerp(PALETTE.NIGHT_UPPER, k)
		lower = PALETTE.DUSK_LOWER.lerp(PALETTE.NIGHT_LOWER, k)
		horizon = PALETTE.DUSK_HORIZON.lerp(PALETTE.NIGHT_HORIZON, k)
		dist_tint = PALETTE.DUSK_DISTANT_TINT.lerp(PALETTE.NIGHT_DISTANT_TINT, k)
		mid_tint = PALETTE.DUSK_MID_TINT.lerp(PALETTE.NIGHT_MID_TINT, k)
		fore_tint = PALETTE.DUSK_FORE_TINT.lerp(PALETTE.NIGHT_FORE_TINT, k)

	# Downward sun trajectory: starts high right-of-center (0.65, 0.20) and sinks
	# steadily downward on a shallow arc (x: 0.65 -> 0.67, y: 0.20 -> 0.62)
	# touching the skyline canyon around t=0.45..0.52 and setting behind it by t=0.68.
	var sun_progress: float = clampf(t / 0.68, 0.0, 1.0)
	var sun_x: float = lerpf(0.65, 0.67, sun_progress)
	var sun_y: float = lerpf(0.20, 0.62, sun_progress)
	var sun_alpha: float = 1.0 - smoothstep(0.60, 0.70, t)

	# Crescent moon rises from behind the skyline (y: 0.48 -> 0.18) after the sun sets (t: 0.72 -> 1.0)
	var moon_progress: float = clampf((t - 0.72) / 0.28, 0.0, 1.0)
	var moon_eased: float = smoothstep(0.0, 1.0, moon_progress)
	var moon_y: float = lerpf(0.48, 0.18, moon_eased)
	var moon_alpha: float = smoothstep(0.72, 0.80, t)
	var star_alpha: float = smoothstep(0.72, 0.95, t)

	if _sky_material:
		_sky_material.set_shader_parameter("zenith_color", zenith)
		_sky_material.set_shader_parameter("upper_mid_color", upper)
		_sky_material.set_shader_parameter("lower_mid_color", lower)
		_sky_material.set_shader_parameter("horizon_color", horizon)
		_sky_material.set_shader_parameter("sun_uv_pos", Vector2(sun_x, sun_y))
		_sky_material.set_shader_parameter("sun_alpha", sun_alpha)
		_sky_material.set_shader_parameter("moon_uv_pos", Vector2(0.66, moon_y))
		_sky_material.set_shader_parameter("moon_alpha", moon_alpha)
		_sky_material.set_shader_parameter("star_alpha", star_alpha)

	if is_instance_valid(_distant_node):
		_distant_node.modulate = dist_tint
	if is_instance_valid(_mid_node):
		_mid_node.modulate = mid_tint
	if is_instance_valid(_fore_node):
		_fore_node.modulate = fore_tint
