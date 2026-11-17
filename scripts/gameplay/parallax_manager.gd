extends Node2D
class_name ParallaxManager

# Multi-layer atmospheric environment, dynamic city lighting, WorldEnvironment
# post-processing, and ambient ember/ash particle controller for CUBE: LAST RUN.

const SKY_SHADER: Shader = preload("res://shaders/dusk_sky_gradient.gdshader")
const FORE_TEXTURE: Texture2D = preload("res://assets/environment/parallax_overpass_fore.png")
const LIGHT_TEXTURE: Texture2D = preload("res://assets/environment/point_light_radial.png")

var _sky_layer: Parallax2D = null
var _distant_layer: Parallax2D = null
var _mid_layer: Parallax2D = null
var _fore_layer: Parallax2D = null
var _beacon_lights: Array[PointLight2D] = []
var _ember_particles: CPUParticles2D = null
var _time_accum: float = 0.0

func setup_environment(world: Node2D, camera: Camera2D) -> void:
	_sky_layer = world.get_node_or_null("ParallaxSky") as Parallax2D
	_distant_layer = world.get_node_or_null("ParallaxDistant") as Parallax2D
	_mid_layer = world.get_node_or_null("ParallaxMid") as Parallax2D

	# 1. Layer 1: Sky & Celestial Layer (Parallax 0.02) + Dusk Gradient & Sun Shader
	if _sky_layer:
		_sky_layer.scroll_scale = Vector2(0.02, 0.0)
		var sky_spr := _sky_layer.get_node_or_null("Sprite2D") as Sprite2D
		if sky_spr:
			var smat := ShaderMaterial.new()
			smat.shader = SKY_SHADER
			sky_spr.material = smat

	# 2. Layer 2: Distant Mega-City Silhouette Layer (Parallax 0.10) + Aviation Beacons
	if _distant_layer:
		_distant_layer.scroll_scale = Vector2(0.10, 0.0)
		for bx: float in [95.0, 245.0, 395.0]:
			var beacon := PointLight2D.new()
			beacon.texture = LIGHT_TEXTURE
			beacon.texture_scale = 0.45
			beacon.color = Color(1.0, 0.18, 0.22, 1.0)
			beacon.energy = 0.8
			beacon.position = Vector2(bx, 72.0)
			_distant_layer.add_child(beacon)
			_beacon_lights.append(beacon)

	# 3. Layer 3: Mid-Ground Urban Skyline Layer (Parallax 0.25)
	if _mid_layer:
		_mid_layer.scroll_scale = Vector2(0.25, 0.0)

	# 4. Layer 4: Foreground Overpass / Street-Level Details Layer (Parallax 0.60)
	_fore_layer = world.get_node_or_null("ParallaxFore") as Parallax2D
	if not _fore_layer:
		_fore_layer = Parallax2D.new()
		_fore_layer.name = "ParallaxFore"
		_fore_layer.scroll_scale = Vector2(0.60, 0.0)
		_fore_layer.repeat_size = Vector2(480.0, 0.0)
		_fore_layer.repeat_times = 3
		var fore_spr := Sprite2D.new()
		fore_spr.name = "Sprite2D"
		fore_spr.texture = FORE_TEXTURE
		fore_spr.centered = false
		_fore_layer.add_child(fore_spr)
		world.add_child(_fore_layer)
		if _mid_layer:
			world.move_child(_fore_layer, _mid_layer.get_index() + 1)

	# 5. WorldEnvironment Post-Processing (Glow/Bloom & Color Grading)
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.65
	env.glow_strength = 0.95
	env.glow_bloom = 0.12
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.12
	world_env.environment = env
	world.add_child(world_env)

	# 6. Ambient Atmospheric Drifting Embers & Ash Motes attached to Camera2D
	if camera:
		_ember_particles = CPUParticles2D.new()
		_ember_particles.name = "AmbientEmbers"
		_ember_particles.position = Vector2(260.0, -20.0)
		_ember_particles.amount = 28
		_ember_particles.lifetime = 3.2
		_ember_particles.preprocess = 1.5
		_ember_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		_ember_particles.emission_rect_extents = Vector2(60.0, 145.0)
		_ember_particles.direction = Vector2(-1.0, 0.18)
		_ember_particles.spread = 18.0
		_ember_particles.gravity = Vector2(-12.0, 8.0)
		_ember_particles.initial_velocity_min = 65.0
		_ember_particles.initial_velocity_max = 135.0
		_ember_particles.scale_amount_min = 1.0
		_ember_particles.scale_amount_max = 2.0
		_ember_particles.color = Color(1.0, 0.58, 0.18, 0.80)
		var grad := Gradient.new()
		grad.set_color(0, Color(1.0, 0.68, 0.22, 0.85))
		grad.set_color(1, Color(0.95, 0.25, 0.12, 0.0))
		_ember_particles.color_ramp = grad
		camera.add_child(_ember_particles)

func _process(delta: float) -> void:
	_time_accum += delta
	# Blink distant radio tower aviation warning beacons rhythmically
	for i in range(_beacon_lights.size()):
		var b: PointLight2D = _beacon_lights[i]
		if is_instance_valid(b):
			b.energy = 0.45 + 0.55 * sin(_time_accum * 4.2 + float(i) * 1.7)
