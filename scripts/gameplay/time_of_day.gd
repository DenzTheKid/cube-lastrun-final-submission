extends Node
class_name TimeOfDay

# Self-contained Day-to-Night controller for CUBE: LAST RUN.
# Drives only the background sky shader and atmospheric depth layer tints.
# Does not touch or feed into any gameplay logic.

const PALETTE = preload("res://scripts/ui/theme_palette.gd")

@export var start_at_day: bool = true
@export var day_hold_seconds: float = 75.0
@export var transition_seconds: float = 14.0
@export var loop_cycle: bool = false

var current_phase_t: float = 0.0 # 0.0 = Day, 0.35 = Late Afternoon, 0.65 = Dusk, 1.0 = Night
var _elapsed_seconds: float = 0.0
var _debug_override_active: bool = false
var _debug_override_t: float = 0.0

var _sky_material: ShaderMaterial = null
var _distant_node: CanvasItem = null
var _mid_node: CanvasItem = null
var _fore_node: CanvasItem = null

# DEBUG SCREENSHOT CAPTURE FLAG (disabled in production after verification)
const DEBUG_CAPTURE_ENABLED: bool = false
var _debug_capture_file: String = ""

func _ready() -> void:
	_check_cmdline_override()
	if _debug_override_active:
		current_phase_t = _debug_override_t
	else:
		current_phase_t = 0.0 if start_at_day else 1.0
	_apply_phase(current_phase_t)
	if DEBUG_CAPTURE_ENABLED and _debug_capture_file != "":
		_run_debug_capture()

func _run_debug_capture() -> void:
	for i in range(6):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	if img:
		var out_path: String = ProjectSettings.globalize_path("res://documentation/screenshots/" + _debug_capture_file)
		img.save_png(out_path)
		print("[DEBUG_TOD_CAPTURE] Saved " + _debug_capture_file)
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
		elif arg.begins_with("--capture-tod="):
			_debug_capture_file = arg.trim_prefix("--capture-tod=")

func _process(delta: float) -> void:
	if _debug_override_active:
		return

	if not start_at_day:
		current_phase_t = 1.0
		_apply_phase(current_phase_t)
		return

	_elapsed_seconds += delta
	var total_one_way: float = day_hold_seconds + maxf(transition_seconds, 0.01)

	if not loop_cycle:
		if _elapsed_seconds <= day_hold_seconds:
			# Subtle drift during daylight hold (0.0 -> 0.15) so the sun gently arcs
			current_phase_t = clampf((_elapsed_seconds / maxf(day_hold_seconds, 0.01)) * 0.15, 0.0, 0.15)
		else:
			var trans_elapsed: float = _elapsed_seconds - day_hold_seconds
			var trans_ratio: float = clampf(trans_elapsed / maxf(transition_seconds, 0.01), 0.0, 1.0)
			current_phase_t = lerpf(0.15, 1.0, smoothstep(0.0, 1.0, trans_ratio))
	else:
		var full_period: float = total_one_way * 2.0
		var cycle_time: float = fmod(_elapsed_seconds, full_period)
		if cycle_time <= day_hold_seconds:
			current_phase_t = (cycle_time / maxf(day_hold_seconds, 0.01)) * 0.15
		elif cycle_time <= total_one_way:
			var tr: float = (cycle_time - day_hold_seconds) / maxf(transition_seconds, 0.01)
			current_phase_t = lerpf(0.15, 1.0, smoothstep(0.0, 1.0, clampf(tr, 0.0, 1.0)))
		elif cycle_time <= total_one_way + day_hold_seconds:
			current_phase_t = 1.0
		else:
			var tr_back: float = (cycle_time - total_one_way - day_hold_seconds) / maxf(transition_seconds, 0.01)
			current_phase_t = lerpf(1.0, 0.0, smoothstep(0.0, 1.0, clampf(tr_back, 0.0, 1.0)))

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

	# Interpolate smoothly across the 4 keyframes:
	# 0.0 (Day) -> 0.35 (Late Afternoon) -> 0.65 (Dusk) -> 1.0 (Night)
	if t < 0.35:
		var k: float = smoothstep(0.0, 0.35, t)
		zenith = PALETTE.DAY_ZENITH.lerp(PALETTE.AFTERNOON_ZENITH, k)
		upper = PALETTE.DAY_UPPER.lerp(PALETTE.AFTERNOON_UPPER, k)
		lower = PALETTE.DAY_LOWER.lerp(PALETTE.AFTERNOON_LOWER, k)
		horizon = PALETTE.DAY_HORIZON.lerp(PALETTE.AFTERNOON_HORIZON, k)
		dist_tint = PALETTE.DAY_DISTANT_TINT.lerp(PALETTE.AFTERNOON_DISTANT_TINT, k)
		mid_tint = PALETTE.DAY_MID_TINT.lerp(PALETTE.AFTERNOON_MID_TINT, k)
		fore_tint = PALETTE.DAY_FORE_TINT.lerp(PALETTE.AFTERNOON_FORE_TINT, k)
	elif t < 0.65:
		var k: float = smoothstep(0.35, 0.65, t)
		zenith = PALETTE.AFTERNOON_ZENITH.lerp(PALETTE.DUSK_ZENITH, k)
		upper = PALETTE.AFTERNOON_UPPER.lerp(PALETTE.DUSK_UPPER, k)
		lower = PALETTE.AFTERNOON_LOWER.lerp(PALETTE.DUSK_LOWER, k)
		horizon = PALETTE.AFTERNOON_HORIZON.lerp(PALETTE.DUSK_HORIZON, k)
		dist_tint = PALETTE.AFTERNOON_DISTANT_TINT.lerp(PALETTE.DUSK_DISTANT_TINT, k)
		mid_tint = PALETTE.AFTERNOON_MID_TINT.lerp(PALETTE.DUSK_MID_TINT, k)
		fore_tint = PALETTE.AFTERNOON_FORE_TINT.lerp(PALETTE.DUSK_FORE_TINT, k)
	else:
		var k: float = smoothstep(0.65, 1.0, t)
		zenith = PALETTE.DUSK_ZENITH.lerp(PALETTE.NIGHT_ZENITH, k)
		upper = PALETTE.DUSK_UPPER.lerp(PALETTE.NIGHT_UPPER, k)
		lower = PALETTE.DUSK_LOWER.lerp(PALETTE.NIGHT_LOWER, k)
		horizon = PALETTE.DUSK_HORIZON.lerp(PALETTE.NIGHT_HORIZON, k)
		dist_tint = PALETTE.DUSK_DISTANT_TINT.lerp(PALETTE.NIGHT_DISTANT_TINT, k)
		mid_tint = PALETTE.DUSK_MID_TINT.lerp(PALETTE.NIGHT_MID_TINT, k)
		fore_tint = PALETTE.DUSK_FORE_TINT.lerp(PALETTE.NIGHT_FORE_TINT, k)

	# Sun trajectory: shallow arc from high open sky (0.62, 0.23) to below skyline (0.74, 0.66)
	var sun_x: float = lerpf(0.62, 0.74, t)
	var sun_y: float = lerpf(0.23, 0.66, pow(t, 1.15))
	var sun_alpha: float = 1.0 - smoothstep(0.72, 0.92, t)

	# Crescent moon trajectory: rises gently in open upper sky clear of HUD and tall roofs
	var moon_alpha: float = smoothstep(0.68, 0.95, t)
	var moon_y: float = lerpf(0.24, 0.17, moon_alpha)
	var star_alpha: float = smoothstep(0.62, 0.95, t)
	var cloud_opacity: float = lerpf(0.38, 0.12, smoothstep(0.65, 1.0, t))

	if _sky_material:
		_sky_material.set_shader_parameter("zenith_color", zenith)
		_sky_material.set_shader_parameter("upper_mid_color", upper)
		_sky_material.set_shader_parameter("lower_mid_color", lower)
		_sky_material.set_shader_parameter("horizon_color", horizon)
		_sky_material.set_shader_parameter("sun_uv_pos", Vector2(sun_x, sun_y))
		_sky_material.set_shader_parameter("sun_alpha", sun_alpha)
		_sky_material.set_shader_parameter("moon_uv_pos", Vector2(0.63, moon_y))
		_sky_material.set_shader_parameter("moon_alpha", moon_alpha)
		_sky_material.set_shader_parameter("star_alpha", star_alpha)
		_sky_material.set_shader_parameter("cloud_opacity", cloud_opacity)

	if is_instance_valid(_distant_node):
		_distant_node.modulate = dist_tint
	if is_instance_valid(_mid_node):
		_mid_node.modulate = mid_tint
	if is_instance_valid(_fore_node):
		_fore_node.modulate = fore_tint
