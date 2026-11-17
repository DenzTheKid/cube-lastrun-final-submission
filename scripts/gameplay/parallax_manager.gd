extends Node2D
class_name ParallaxManager

# Multi-layer atmospheric background manager for CUBE: LAST RUN.
# Connects the 4 background layers (ParallaxSky, ParallaxDistant, ParallaxMid, ParallaxFore)
# to the self-contained TimeOfDay cycle controller with static city lighting.

const SKY_SHADER: Shader = preload("res://shaders/dusk_sky_gradient.gdshader")
const FORE_TEXTURE: Texture2D = preload("res://assets/environment/parallax_overpass_fore.png")
const TIME_OF_DAY_SCRIPT = preload("res://scripts/gameplay/time_of_day.gd")

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

	# 2. Layer 2: Distant Skyline Layer (Parallax 0.10) — static lights, no blinking beacons
	if _distant_layer:
		_distant_layer.scroll_scale = Vector2(0.10, 0.0)

	# 3. Layer 3: Mid-Ground Urban Skyline Layer (Parallax 0.25) — static lit windows & signs
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

	# 5. Attach TimeOfDay controller to drive sky phases & atmospheric perspective layer tints
	time_of_day = TIME_OF_DAY_SCRIPT.new()
	time_of_day.name = "TimeOfDay"
	add_child(time_of_day)
	time_of_day.bind_layers(sky_mat, _distant_layer, _mid_layer, _fore_layer)
