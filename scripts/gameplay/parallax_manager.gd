extends Node2D
class_name ParallaxManager

# Multi-layer atmospheric background manager for CUBE: LAST RUN.
# Connects the 4 background layers (ParallaxSky, ParallaxDistant, ParallaxMid, ParallaxFore)
# to the self-contained TimeOfDay cycle controller with static city lighting.

const SKY_SHADER: Shader = preload("res://shaders/dusk_sky_gradient.gdshader")
const FORE_TEXTURE: Texture2D = preload("res://assets/environment/parallax_overpass_fore.png")
const AIRPLANE_CRASH_TEXTURE: Texture2D = preload("res://assets/environment/airplane_crash_overlay.png")
const SIDE_BLAST_TEXTURE: Texture2D = preload("res://assets/environment/side_blast_overlay.png")
const TIME_OF_DAY_SCRIPT = preload("res://scripts/gameplay/time_of_day.gd")
const ANIMATED_FIRE_SCRIPT = preload("res://scripts/effects/animated_fire_node.gd")

const RARE_LANDMARK_CYCLE_WIDTH: float = 2880.0 # 6 full mid-ground blocks (6 * 480px) so the crashed airplane is genuinely rare

var _sky_layer: Parallax2D = null
var _distant_layer: Parallax2D = null
var _mid_layer: Parallax2D = null
var _rare_mid_layer: Parallax2D = null
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

	# 2. Layer 2: Distant Skyline Layer (Parallax 0.10) — classic moody dark city silhouettes
	if _distant_layer:
		_distant_layer.scroll_scale = Vector2(0.10, 0.0)

	# 3. Layer 3: Mid-Ground Urban Skyline Layer (Parallax 0.25) — 100% classic dark skyscrapers with sparse lit rooms
	if _mid_layer:
		_mid_layer.scroll_scale = Vector2(0.25, 0.0)
		if not _mid_layer.has_node("ApocalypseEmbers"):
			var embers := CPUParticles2D.new()
			embers.name = "ApocalypseEmbers"
			embers.position = Vector2(240.0, 145.0)
			embers.amount = 4
			embers.lifetime = 2.4
			embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			embers.emission_rect_extents = Vector2(240.0, 48.0)
			embers.direction = Vector2(-0.3, -1.0)
			embers.spread = 30.0
			embers.gravity = Vector2(-4.0, -14.0)
			embers.initial_velocity_min = 8.0
			embers.initial_velocity_max = 20.0
			var grad := Gradient.new()
			grad.set_color(0, Color(1.0, 0.85, 0.3, 0.85))
			grad.set_color(1, Color(1.0, 0.25, 0.08, 0.0))
			embers.color_ramp = grad
			_mid_layer.add_child(embers)

	# 3B. Rare Mid-Ground Disasters Layer (Parallax 0.25 locked 1:1 with ParallaxMid, repeats every 6 blocks = 2880px!)
	# Keeps the crashed airplane (1 per 6 blocks) & burning side-blast craters genuinely sparse across the city.
	_rare_mid_layer = world.get_node_or_null("ParallaxRareLandmarks") as Parallax2D
	if not _rare_mid_layer:
		_rare_mid_layer = Parallax2D.new()
		_rare_mid_layer.name = "ParallaxRareLandmarks"
		_rare_mid_layer.scroll_scale = Vector2(0.25, 0.0)
		_rare_mid_layer.repeat_size = Vector2(RARE_LANDMARK_CYCLE_WIDTH, 0.0)
		_rare_mid_layer.repeat_times = 1
		world.add_child(_rare_mid_layer)
		if _mid_layer:
			world.move_child(_rare_mid_layer, _mid_layer.get_index() + 1)
		_populate_rare_landmarks(_rare_mid_layer)

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
		if _rare_mid_layer:
			world.move_child(_fore_layer, _rare_mid_layer.get_index() + 1)
		elif _mid_layer:
			world.move_child(_fore_layer, _mid_layer.get_index() + 1)

	# 5. Attach TimeOfDay controller to drive sky phases & atmospheric perspective layer tints
	time_of_day = TIME_OF_DAY_SCRIPT.new()
	time_of_day.name = "TimeOfDay"
	add_child(time_of_day)
	time_of_day.bind_layers(sky_mat, _distant_layer, _mid_layer, _fore_layer)
	if _rare_mid_layer and time_of_day.has_method("add_mid_layer"):
		time_of_day.add_mid_layer(_rare_mid_layer)


func _populate_rare_landmarks(layer: Node2D) -> void:
	if layer.has_node("RareLandmarksRoot"):
		return
	var root := Node2D.new()
	root.name = "RareLandmarksRoot"
	layer.add_child(root)

	# 6-block cycle (2880px = 6 * 480px):
	# - Block 0 (x = 0):    1 side-blast crater + 1 steady fire
	# - Block 1 (x = 480):  100% normal classic dark buildings
	# - Block 2 (x = 960):  RARE crashed commercial airplane + 2 steady fires (appears only once per 6 blocks!)
	# - Block 3 (x = 1440): 100% normal classic dark buildings
	# - Block 4 (x = 1920): 1 side-blast crater + 1 steady fire
	# - Block 5 (x = 2400): 100% normal classic dark buildings

	for block_offset_x: float in [0.0, 1920.0]:
		var blast_spr := Sprite2D.new()
		blast_spr.texture = SIDE_BLAST_TEXTURE
		blast_spr.centered = false
		blast_spr.position = Vector2(block_offset_x, 0.0)
		root.add_child(blast_spr)

		var blast_fire: Sprite2D = ANIMATED_FIRE_SCRIPT.new()
		blast_fire.position = Vector2(block_offset_x + 405.0, 131.0)
		blast_fire.base_scale = Vector2(0.90, 0.85)
		root.add_child(blast_fire)

	var plane_block_x: float = 960.0
	var plane_spr := Sprite2D.new()
	plane_spr.name = "RareAirplaneCrash"
	plane_spr.texture = AIRPLANE_CRASH_TEXTURE
	plane_spr.centered = false
	plane_spr.position = Vector2(plane_block_x, 0.0)
	root.add_child(plane_spr)

	var plane_fires: Array[ Array ] = [
		[plane_block_x + 148.0, 114.0, 1.15, 1.10], # Airplane impact crater fire
		[plane_block_x + 123.0, 120.0, 0.72, 0.72]  # Burning jet engine / wing fire
	]
	for fp: Array in plane_fires:
		var fire: Sprite2D = ANIMATED_FIRE_SCRIPT.new()
		fire.position = Vector2(float(fp[0]), float(fp[1]))
		fire.base_scale = Vector2(float(fp[2]), float(fp[3]))
		root.add_child(fire)

