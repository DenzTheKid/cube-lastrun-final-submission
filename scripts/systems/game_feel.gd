extends Node

# Autoload Singleton: GameFeel
# Centralizes AAA-indie tactile "juice" and audio-visual feedback:
# - Real-time hitstop (freeze-frames) safe against scene reloads
# - Trauma-based camera shake routing
# - Floating pixel damage / score / combo popups
# - Physical bouncing brass shell casings & spent reload shells
# - Bouncing 2.5D voxel debris chunks & road splatter decals on enemy death
# - Air-ring shockwave bursts for jump / shotgun recoil vaults

signal trauma_requested(amount: float)

var _hitstop_end_usec: int = 0
var _is_in_hitstop: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if _is_in_hitstop:
		if Time.get_ticks_usec() >= _hitstop_end_usec:
			_is_in_hitstop = false
			Engine.time_scale = 1.0

func hitstop(duration: float = 0.035, target_time_scale: float = 0.05) -> void:
	# Skip hitstop if tree is paused or running headless automated unit tests
	if get_tree().paused:
		return
	var root: Node = get_tree().current_scene
	if root and root.name == "TestRunner":
		return
	Engine.time_scale = clampf(target_time_scale, 0.01, 1.0)
	var duration_usec: int = int(duration * 1000000.0)
	var new_end: int = Time.get_ticks_usec() + duration_usec
	if new_end > _hitstop_end_usec:
		_hitstop_end_usec = new_end
	_is_in_hitstop = true

func camera_shake(amount: float) -> void:
	trauma_requested.emit(amount)
	var root: Node = get_tree().current_scene
	if root and root.has_method("add_shake"):
		root.add_shake(amount)

func _get_effect_parent() -> Node:
	var root: Node = get_tree().current_scene
	if not root or root.name == "TestRunner":
		return null
	return root

func spawn_floating_text(world_pos: Vector2, text_str: String, color: Color = Color(1.0, 0.88, 0.28), scale_mult: float = 1.0) -> void:
	var root: Node = _get_effect_parent()
	if not root:
		return
	var holder := Node2D.new()
	holder.global_position = world_pos + Vector2(randf_range(-6.0, 6.0), -10.0)
	holder.z_index = 25
	holder.scale = Vector2.ONE * (0.4 * scale_mult)

	var lbl := Label.new()
	lbl.text = text_str
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-40.0, -8.0)
	lbl.custom_minimum_size = Vector2(80.0, 16.0)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0.05, 0.04, 0.08, 1.0))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.add_theme_color_override("font_outline_color", Color(0.06, 0.06, 0.1, 1.0))
	lbl.add_theme_constant_override("outline_size", 2)
	holder.add_child(lbl)
	root.add_child(holder)

	var tw: Tween = holder.create_tween()
	tw.set_parallel(true)
	tw.tween_property(holder, "scale", Vector2.ONE * scale_mult, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(holder, "global_position:y", holder.global_position.y - 24.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(holder, "modulate:a", 0.0, 0.25).set_delay(0.30)
	tw.chain().tween_callback(holder.queue_free)

func spawn_shell_casing(world_pos: Vector2, eject_dir: Vector2, ground_y: float = 224.0) -> void:
	var root: Node = _get_effect_parent()
	if not root:
		return
	var casing := PhysicalParticle2D.new()
	casing.global_position = world_pos
	casing.velocity = Vector2(eject_dir.x * randf_range(55.0, 95.0), randf_range(-135.0, -90.0))
	casing.angular_velocity = randf_range(-18.0, 18.0)
	casing.ground_y = ground_y
	casing.particle_size = Vector2(4.0, 2.0)
	casing.primary_color = Color(0.95, 0.78, 0.22, 1.0) # Brass
	casing.secondary_color = Color(0.85, 0.18, 0.18, 1.0) # Red hull tip
	casing.lifetime = 0.75
	root.add_child(casing)

func spawn_voxel_debris(world_pos: Vector2, base_color: Color, count: int = 7, ground_y: float = 224.0) -> void:
	var root: Node = _get_effect_parent()
	if not root:
		return

	# Spawn road splatter decal on the highway surface
	var decal := RoadSplatterDecal.new()
	decal.global_position = Vector2(world_pos.x, ground_y + 2.0)
	root.add_child(decal)

	for i in range(count):
		var chunk := PhysicalParticle2D.new()
		chunk.global_position = world_pos + Vector2(randf_range(-5.0, 5.0), randf_range(-6.0, 4.0))
		var angle: float = randf_range(-PI * 0.92, -PI * 0.08)
		var spd: float = randf_range(65.0, 175.0)
		chunk.velocity = Vector2(cos(angle) * spd + 35.0, sin(angle) * spd - 40.0)
		chunk.angular_velocity = randf_range(-16.0, 16.0)
		chunk.ground_y = ground_y
		var sz: float = randf_range(2.5, 4.5)
		chunk.particle_size = Vector2(sz, sz)
		chunk.primary_color = base_color.lightened(randf_range(-0.15, 0.20))
		chunk.secondary_color = base_color.darkened(0.35)
		chunk.lifetime = randf_range(0.55, 0.90)
		root.add_child(chunk)

func spawn_shockwave_ring(world_pos: Vector2, ring_color: Color = Color(0.45, 0.95, 1.0, 0.85)) -> void:
	var root: Node = _get_effect_parent()
	if not root:
		return
	var ring := ShockwaveRing2D.new()
	ring.global_position = world_pos
	ring.ring_color = ring_color
	root.add_child(ring)

# ------------------------------------------------------------------------------
# Lightweight Custom Physics Particle for Shell Casings & Voxel Debris Chunks
# ------------------------------------------------------------------------------
class PhysicalParticle2D extends Node2D:
	var velocity: Vector2 = Vector2.ZERO
	var angular_velocity: float = 10.0
	var gravity: float = 560.0
	var ground_y: float = 224.0
	var particle_size: Vector2 = Vector2(3.0, 3.0)
	var primary_color: Color = Color.WHITE
	var secondary_color: Color = Color.GRAY
	var lifetime: float = 0.75
	var _elapsed: float = 0.0
	var _bounces: int = 0

	func _process(delta: float) -> void:
		_elapsed += delta
		if _elapsed >= lifetime:
			queue_free()
			return

		velocity.y += gravity * delta
		global_position += velocity * delta
		rotation += angular_velocity * delta

		if global_position.y >= ground_y:
			global_position.y = ground_y
			velocity.y = - absf(velocity.y) * 0.42
			velocity.x *= 0.68
			angular_velocity *= 0.55
			_bounces += 1

		if _elapsed > lifetime * 0.65:
			modulate.a = 1.0 - ((_elapsed - lifetime * 0.65) / (lifetime * 0.35))
		queue_redraw()

	func _draw() -> void:
		var half: Vector2 = particle_size * 0.5
		draw_rect(Rect2(-half, particle_size), primary_color, true)
		draw_rect(Rect2(-half, Vector2(particle_size.x * 0.45, particle_size.y)), secondary_color, true)

# ------------------------------------------------------------------------------
# Temporary Dark Splatter Decal on Road Surface
# ------------------------------------------------------------------------------
class RoadSplatterDecal extends Node2D:
	var _elapsed: float = 0.0
	var _lifetime: float = 2.8

	func _ready() -> void:
		z_index = 1

	func _process(delta: float) -> void:
		_elapsed += delta
		if _elapsed >= _lifetime:
			queue_free()
			return
		if _elapsed > _lifetime * 0.7:
			modulate.a = 1.0 - ((_elapsed - _lifetime * 0.7) / (_lifetime * 0.3))

	func _draw() -> void:
		draw_rect(Rect2(-7.0, -1.0, 14.0, 3.0), Color(0.32, 0.05, 0.08, 0.75), true)
		draw_rect(Rect2(-4.0, 0.0, 9.0, 2.0), Color(0.55, 0.08, 0.12, 0.85), true)

# ------------------------------------------------------------------------------
# Expanding Air-Ring Shockwave for Jump / Shotgun Recoil Vault
# ------------------------------------------------------------------------------
class ShockwaveRing2D extends Node2D:
	var ring_color: Color = Color(0.45, 0.95, 1.0, 0.85)
	var _elapsed: float = 0.0
	var _duration: float = 0.22

	func _process(delta: float) -> void:
		_elapsed += delta
		if _elapsed >= _duration:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var t: float = clampf(_elapsed / _duration, 0.0, 1.0)
		var rx: float = lerpf(4.0, 18.0, t)
		var ry: float = lerpf(1.5, 5.5, t)
		var col: Color = ring_color
		col.a = (1.0 - t) * ring_color.a
		var pts := PackedVector2Array()
		for i in range(17):
			var ang: float = (float(i) / 16.0) * TAU
			pts.append(Vector2(cos(ang) * rx, sin(ang) * ry))
		draw_polyline(pts, col, 1.5)
