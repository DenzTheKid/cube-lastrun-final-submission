extends Node2D
class_name ParallaxManager

# Multi-layer atmospheric background manager for CUBE: LAST RUN.
# Connects the 4 background layers (ParallaxSky, ParallaxDistant, ParallaxMid, ParallaxFore)
# to the self-contained TimeOfDay cycle controller with static city lighting.

const SKY_SHADER: Shader = preload("res://shaders/dusk_sky_gradient.gdshader")
const FORE_TEXTURE: Texture2D = preload("res://assets/environment/parallax_overpass_fore.png")
const TIME_OF_DAY_SCRIPT = preload("res://scripts/gameplay/time_of_day.gd")
const ANIMATED_FIRE_SCRIPT = preload("res://scripts/effects/animated_fire_node.gd")

var _sky_layer: Parallax2D = null
var _distant_layer: Parallax2D = null
var _mid_layer: Parallax2D = null
var _fore_layer: Parallax2D = null
var time_of_day: Node = null

func setup_environment(world: Node2D, _camera: Camera2D) -> void:
	_sky_layer = world.get_node_or_null("ParallaxSky") as Parallax2D
	_distant_layer = world.get_node_or_null("ParallaxDistant") as Parallax2D
	_mid_layer = world.get_node_or_null("ParallaxMid") as Parallax2D

	var sky_mat: ShaderMaterial = null

	# 1. Layer 1: Sky & Celestial Layer (Parallax 0.02)
	if _sky_layer:
		_sky_layer.scroll_scale = Vector2(0.02, 0.0)
		var sky_spr := _sky_layer.get_node_or_null("Sprite2D") as Sprite2D
		if sky_spr:
			sky_mat = ShaderMaterial.new()
			sky_mat.shader = SKY_SHADER
			sky_spr.material = sky_mat

	# 2. Layer 2: Distant Skyline Layer (Parallax 0.10) — ruined distant towers with live animated fires
	if _distant_layer:
		_distant_layer.scroll_scale = Vector2(0.10, 0.0)
		_spawn_distant_animated_fires(_distant_layer)

	# 3. Layer 3: Mid-Ground Urban Skyline Layer (Parallax 0.25) — apocalyptic burning city & airplane crash
	if _mid_layer:
		_mid_layer.scroll_scale = Vector2(0.25, 0.0)
		_spawn_midground_animated_fires(_mid_layer)
		if not _mid_layer.has_node("ApocalypseEmbers"):
			var embers := CPUParticles2D.new()
			embers.name = "ApocalypseEmbers"
			embers.position = Vector2(240.0, 145.0)
			embers.amount = 18
			embers.lifetime = 2.4
			embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			embers.emission_rect_extents = Vector2(240.0, 48.0)
			embers.direction = Vector2(-0.3, -1.0)
			embers.spread = 30.0
			embers.gravity = Vector2(-4.0, -14.0)
			embers.initial_velocity_min = 8.0
			embers.initial_velocity_max = 20.0
			var grad := Gradient.new()
			grad.set_color(0, Color(1.0, 0.85, 0.3, 0.9))
			grad.set_color(1, Color(1.0, 0.25, 0.08, 0.0))
			embers.color_ramp = grad
			_mid_layer.add_child(embers)

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

	# 5. Attach TimeOfDay controller to drive sky phases & atmospheric perspective layer tints
	time_of_day = TIME_OF_DAY_SCRIPT.new()
	time_of_day.name = "TimeOfDay"
	add_child(time_of_day)
	time_of_day.bind_layers(sky_mat, _distant_layer, _mid_layer, _fore_layer)


func _spawn_distant_animated_fires(layer: Node2D) -> void:
	if layer.has_node("DistantFiresContainer"):
		return
	var container := Node2D.new()
	container.name = "DistantFiresContainer"
	layer.add_child(container)

	var spots: Array[Vector3] = [
		Vector3(60.0, 128.0, 0.65),
		Vector3(104.0, 92.0, 0.72),
		Vector3(190.0, 102.0, 0.65),
		Vector3(278.0, 90.0, 0.75),
		Vector3(364.0, 106.0, 0.65),
		Vector3(454.0, 98.0, 0.72)
	]
	for sp in spots:
		var fire: Sprite2D = ANIMATED_FIRE_SCRIPT.new()
		fire.position = Vector2(sp.x, sp.y)
		fire.base_scale = Vector2(sp.z, sp.z)
		fire.modulate = Color(1.0, 0.82, 0.68, 0.85)
		container.add_child(fire)


func _spawn_midground_animated_fires(layer: Node2D) -> void:
	if layer.has_node("MidFiresContainer"):
		return
	var container := Node2D.new()
	container.name = "MidFiresContainer"
	layer.add_child(container)

	# [x, y, scale_x, scale_y] positioned on ruined rooftops, blown-out floors, and the airplane crash crater!
	var fire_placements: Array[ Array ] = [
		[28.0, 96.0, 1.35, 1.25],   # Building 1: Inferno Tower roof blaze
		[24.0, 134.0, 0.95, 0.95],  # Building 1: Middle floor fire
		[34.0, 172.0, 0.90, 0.90],  # Building 1: Lower floor fire
		[100.0, 118.0, 1.05, 1.05], # Building 2: Collapsed half crater fire
		[150.0, 110.0, 1.30, 1.25], # Building 3: AIRPLANE CRASH MAIN IMPACT CRATER FIRE!
		[123.0, 122.0, 0.85, 0.85], # Building 3: Burning airplane wing & jet engine!
		[174.0, 68.0, 0.95, 0.95],  # Building 3: Rooftop fire above airplane crash
		[219.0, 150.0, 0.95, 0.95], # Building 4: Skeletal bomb ruin core fire
		[270.0, 84.0, 1.15, 1.10],  # Building 5: Ruined tower rooftop fire
		[256.0, 132.0, 0.85, 0.85], # Building 5: Side blast notch fire
		[320.0, 132.0, 0.95, 0.95], # Building 6: Collapsed crane roof fire
		[374.0, 64.0, 1.10, 1.05],  # Building 7: Burning neon billboard on roof
		[398.0, 122.0, 1.00, 1.00], # Building 7: Side explosion crater fire
		[430.0, 74.0, 0.75, 0.80],  # Building 8: Burning industrial smokestack
		[450.0, 124.0, 1.10, 1.05]  # Building 8: Industrial inferno floor
	]
	for fp: Array in fire_placements:
		var fire: Sprite2D = ANIMATED_FIRE_SCRIPT.new()
		fire.position = Vector2(float(fp[0]), float(fp[1]))
		fire.base_scale = Vector2(float(fp[2]), float(fp[3]))
		container.add_child(fire)

