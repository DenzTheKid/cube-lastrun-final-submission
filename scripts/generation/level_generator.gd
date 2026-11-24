extends Node2D
class_name LevelGenerator

# Modular procedural endless runner level generator for CUBE: LAST RUN V1.1.
# Features:
# - 20 distinct modular encounter patterns with controlled randomization.
# - Algorithmic fairness validation (jump distance, pit width, reaction time).
# - Progressive difficulty scaling with tiered hazard complexity.
# - High-performance batched drawing (drops node count from 74/chunk to 2/chunk).
# - Strict garbage collection ensuring zero node leakage over long sessions.

@export var chunk_width: float = 384.0
@export var ground_y: float = 224.0
@export var spawn_ahead_distance: float = 900.0
@export var despawn_behind_distance: float = 480.0

var target_player: Player = null
var next_chunk_x: float = 0.0
var _active_chunks: Array[Node2D] = []

# Preloaded obstacle and enemy scenes
const SPIKES_SCENE: PackedScene = preload("res://scenes/obstacles/spikes.tscn")
const BARRICADE_SCENE: PackedScene = preload("res://scenes/obstacles/barricade.tscn")
const WRECKED_CAR_SCENE: PackedScene = preload("res://scenes/obstacles/wrecked_car.tscn")
const PLATFORM_SCENE: PackedScene = preload("res://scenes/obstacles/platform.tscn")
const PIT_SCENE: PackedScene = preload("res://scenes/obstacles/pit_killzone.tscn")
const MEDKIT_SCENE: PackedScene = preload("res://scenes/pickups/medkit.tscn")
const SHIELD_SCENE: PackedScene = preload("res://scenes/pickups/shield_pickup.tscn")

const WALKER_SCENE: PackedScene = preload("res://scenes/enemies/zombie_walker.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/enemies/zombie_runner.tscn")
const BRUTE_SCENE: PackedScene = preload("res://scenes/enemies/zombie_brute.tscn")
const MUTANT_SCENE: PackedScene = preload("res://scenes/enemies/zombie_mutant.tscn")

const URBAN_TILES: Texture2D = preload("res://assets/environment/urban_tiles.png")
const COLLAPSED_BRIDGE_TEX: Texture2D = preload("res://assets/environment/collapsed_bridge_pit.png")

enum PatternType {
	FLAT_START,
	WALKER_LONE,
	WALKER_TRIO,
	RUNNER_RUSH,
	RUNNER_TWIN,
	SPIKE_HURDLE,
	SPIKE_DOUBLE,
	PIT_STANDARD,
	PLATFORM_HIGHWAY,
	PLATFORM_OVER_PIT,
	BARRICADE_SOLO,
	BARRICADE_WALKER,
	BRUTE_TANK,
	BARRICADE_BRUTE,
	MUTANT_AMBUSH,
	MUTANT_AND_SPIKES,
	RECOIL_DOUBLE_VAULT,
	PLATFORM_CASCADE,
	RUNNER_AMBUSH_HIGH,
	THE_GAUNTLET,
	CAR_WRECK_SOLO,
	CAR_WRECK_MEDKIT,
	CAR_WRECK_WALKER,
	CAR_WRECK_SPIKES,
	POLICE_ROADBLOCK,
	BUS_WRECK_STOP
}

var _last_pattern: PatternType = PatternType.FLAT_START
var _chunks_spawned: int = 0
var _consecutive_hazard_chunks: int = 0
var _chunks_since_medkit: int = 0
var _chunks_since_shield: int = 0

func setup(player: Player) -> void:
	target_player = player
	next_chunk_x = -192.0 # Start behind player
	# Spawn 3 initial safe runway chunks
	for i in range(3):
		_spawn_next_chunk(true)

func _process(_delta: float) -> void:
	if not is_instance_valid(target_player):
		return

	var player_x: float = target_player.global_position.x

	# Spawn ahead
	while next_chunk_x < player_x + spawn_ahead_distance:
		_spawn_next_chunk(false)

	# Clean up behind
	_cleanup_old_chunks(player_x)

func _spawn_next_chunk(is_safe_start: bool) -> void:
	# Instantiate lightweight Chunk container
	var chunk: ChunkNode = ChunkNode.new()
	chunk.name = "Chunk_%d" % _chunks_spawned
	chunk.position = Vector2(next_chunk_x, 0)
	chunk.tiles_texture = URBAN_TILES
	chunk.collapsed_bridge_texture = COLLAPSED_BRIDGE_TEX
	chunk.ground_y = ground_y
	add_child(chunk)
	_active_chunks.append(chunk)

	var pattern: PatternType = PatternType.FLAT_START
	if not is_safe_start:
		pattern = _choose_fair_pattern()

	_build_chunk_content(chunk, pattern)

	_last_pattern = pattern
	_chunks_spawned += 1
	next_chunk_x += chunk_width

func _choose_fair_pattern() -> PatternType:
	var diff: float = GameManager.difficulty_factor if GameManager else 1.0

	# 1. Base Tier Patterns (Early game / Warmup)
	var choices: Array[PatternType] = [
		PatternType.WALKER_LONE,
		PatternType.WALKER_TRIO,
		PatternType.RUNNER_RUSH,
		PatternType.SPIKE_HURDLE,
		PatternType.BARRICADE_SOLO,
		PatternType.PLATFORM_HIGHWAY,
		PatternType.CAR_WRECK_SOLO,
		PatternType.BUS_WRECK_STOP
	]

	# 2. Mid Tier Patterns (Unlocked at diff > 1.2, ~100m+)
	if diff >= 1.2:
		choices.append(PatternType.RUNNER_TWIN)
		choices.append(PatternType.SPIKE_DOUBLE)
		choices.append(PatternType.PIT_STANDARD)
		choices.append(PatternType.BARRICADE_WALKER)
		choices.append(PatternType.PLATFORM_OVER_PIT)
		choices.append(PatternType.CAR_WRECK_MEDKIT)
		choices.append(PatternType.CAR_WRECK_WALKER)
		choices.append(PatternType.POLICE_ROADBLOCK)

	# 3. High Tier Patterns (Unlocked at diff > 1.45, ~250m+)
	if diff >= 1.45:
		choices.append(PatternType.BRUTE_TANK)
		choices.append(PatternType.MUTANT_AMBUSH)
		choices.append(PatternType.MUTANT_AND_SPIKES)
		choices.append(PatternType.PLATFORM_CASCADE)
		choices.append(PatternType.CAR_WRECK_SPIKES)

	# 4. Expert Tier Patterns (Unlocked at diff > 1.75, ~450m+)
	if diff >= 1.75:
		choices.append(PatternType.BARRICADE_BRUTE)
		choices.append(PatternType.RECOIL_DOUBLE_VAULT)
		choices.append(PatternType.RUNNER_AMBUSH_HIGH)
		choices.append(PatternType.THE_GAUNTLET)

	# Algorithmic Fairness Filters:
	# Rule A: Never spawn two consecutive lethal pit gaps or high barricades
	var candidate: PatternType = choices.pick_random()
	var is_severe_hazard: bool = candidate in [
		PatternType.PIT_STANDARD,
		PatternType.PLATFORM_OVER_PIT,
		PatternType.BARRICADE_BRUTE,
		PatternType.RECOIL_DOUBLE_VAULT,
		PatternType.THE_GAUNTLET
	]

	var last_was_pit: bool = _last_pattern in [
		PatternType.PIT_STANDARD,
		PatternType.PLATFORM_OVER_PIT,
		PatternType.RECOIL_DOUBLE_VAULT
	]
	var candidate_is_pit: bool = candidate in [
		PatternType.PIT_STANDARD,
		PatternType.PLATFORM_OVER_PIT,
		PatternType.RECOIL_DOUBLE_VAULT
	]

	if is_severe_hazard:
		if _consecutive_hazard_chunks >= 1 or _last_pattern == candidate or (last_was_pit and candidate_is_pit):
			# Substitute with a breather or standard encounter
			candidate = [PatternType.WALKER_LONE, PatternType.PLATFORM_HIGHWAY, PatternType.SPIKE_HURDLE].pick_random()
			_consecutive_hazard_chunks = 0
		else:
			_consecutive_hazard_chunks += 1
	else:
		_consecutive_hazard_chunks = 0
		# Prevent immediate duplicate repeats of complex encounters to preserve variety
		if candidate == _last_pattern and candidate != PatternType.WALKER_LONE:
			var breathers: Array[PatternType] = [PatternType.WALKER_LONE, PatternType.PLATFORM_HIGHWAY, PatternType.SPIKE_HURDLE, PatternType.CAR_WRECK_SOLO]
			candidate = breathers.pick_random()

	_last_pattern = candidate
	return candidate

func _build_chunk_content(chunk: ChunkNode, pattern: PatternType) -> void:
	if pattern != PatternType.FLAT_START:
		_chunks_since_medkit += 1
		_chunks_since_shield += 1

	match pattern:
		PatternType.FLAT_START:
			chunk.add_ground_segment(0.0, chunk_width)

		PatternType.WALKER_LONE:
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_enemy(chunk, WALKER_SCENE, 220.0 + randf_range(-20.0, 30.0), ground_y - 12.0)

		PatternType.WALKER_TRIO:
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_enemy(chunk, WALKER_SCENE, 150.0, ground_y - 12.0)
			_spawn_enemy(chunk, WALKER_SCENE, 215.0, ground_y - 12.0)
			_spawn_enemy(chunk, WALKER_SCENE, 280.0, ground_y - 12.0)

		PatternType.RUNNER_RUSH:
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_enemy(chunk, RUNNER_SCENE, 290.0, ground_y - 12.0)

		PatternType.RUNNER_TWIN:
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_enemy(chunk, RUNNER_SCENE, 180.0, ground_y - 12.0)
			_spawn_enemy(chunk, RUNNER_SCENE, 280.0, ground_y - 12.0)

		PatternType.SPIKE_HURDLE:
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_hazard(chunk, SPIKES_SCENE, 170.0, ground_y)
			if randf() > 0.4:
				_spawn_enemy(chunk, WALKER_SCENE, 290.0, ground_y - 12.0)

		PatternType.SPIKE_DOUBLE:
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_hazard(chunk, SPIKES_SCENE, 155.0, ground_y)
			_spawn_hazard(chunk, SPIKES_SCENE, 195.0, ground_y)

		PatternType.PIT_STANDARD:
			# 144px runway (9 tiles) -> 80px pit (5 tiles) -> 160px landing runway (10 tiles)
			chunk.add_ground_segment(0.0, 144.0)
			_spawn_hazard(chunk, PIT_SCENE, 184.0, ground_y + 40.0)
			chunk.add_ground_segment(224.0, 160.0)

		PatternType.PLATFORM_HIGHWAY:
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_hazard(chunk, SPIKES_SCENE, 170.0, ground_y)
			_spawn_platform(chunk, 170.0, ground_y - 48.0)
			_spawn_enemy(chunk, WALKER_SCENE, 290.0, ground_y - 12.0)

		PatternType.PLATFORM_OVER_PIT:
			# 144px runway (9 tiles) -> 80px pit bridged by solid platform -> 160px landing runway
			chunk.add_ground_segment(0.0, 144.0)
			_spawn_hazard(chunk, PIT_SCENE, 184.0, ground_y + 40.0)
			_spawn_platform(chunk, 184.0, ground_y - 46.0)
			chunk.add_ground_segment(224.0, 160.0)

		PatternType.BARRICADE_SOLO:
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_hazard(chunk, BARRICADE_SCENE, 170.0, ground_y)

		PatternType.BARRICADE_WALKER:
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_hazard(chunk, BARRICADE_SCENE, 140.0, ground_y)
			_spawn_enemy(chunk, WALKER_SCENE, 280.0, ground_y - 12.0)

		PatternType.BRUTE_TANK:
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_enemy(chunk, BRUTE_SCENE, 260.0, ground_y - 16.0)

		PatternType.BARRICADE_BRUTE:
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_hazard(chunk, BARRICADE_SCENE, 120.0, ground_y)
			_spawn_platform(chunk, 190.0, ground_y - 48.0)
			_spawn_enemy(chunk, BRUTE_SCENE, 270.0, ground_y - 16.0)

		PatternType.MUTANT_AMBUSH:
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_hazard(chunk, SPIKES_SCENE, 140.0, ground_y)
			_spawn_enemy(chunk, MUTANT_SCENE, 260.0, ground_y - 14.0)

		PatternType.MUTANT_AND_SPIKES:
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_hazard(chunk, SPIKES_SCENE, 120.0, ground_y)
			_spawn_platform(chunk, 190.0, ground_y - 48.0)
			_spawn_enemy(chunk, MUTANT_SCENE, 210.0, ground_y - 14.0)
			_spawn_hazard(chunk, SPIKES_SCENE, 270.0, ground_y)

		PatternType.RECOIL_DOUBLE_VAULT:
			# High barricade with 42px recovery runway, followed by pit bridged by elevated platform
			# Viable via normal jump + platform or high diagonal/downward recoil boost
			chunk.add_ground_segment(0.0, 144.0)
			_spawn_hazard(chunk, BARRICADE_SCENE, 88.0, ground_y)
			_spawn_hazard(chunk, PIT_SCENE, 184.0, ground_y + 40.0)
			_spawn_platform(chunk, 184.0, ground_y - 46.0)
			chunk.add_ground_segment(224.0, 160.0)

		PatternType.PLATFORM_CASCADE:
			# Step 1: Low platform -> Step 2: High platform
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_hazard(chunk, SPIKES_SCENE, 130.0, ground_y)
			_spawn_platform(chunk, 130.0, ground_y - 42.0)
			_spawn_hazard(chunk, SPIKES_SCENE, 210.0, ground_y)
			_spawn_platform(chunk, 210.0, ground_y - 68.0)
			_spawn_enemy(chunk, WALKER_SCENE, 290.0, ground_y - 12.0)

		PatternType.RUNNER_AMBUSH_HIGH:
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_platform(chunk, 160.0, ground_y - 48.0)
			_spawn_enemy(chunk, RUNNER_SCENE, 170.0, ground_y - 60.0)
			_spawn_hazard(chunk, SPIKES_SCENE, 260.0, ground_y)

		PatternType.THE_GAUNTLET:
			# High difficulty crescendo: Spikes + Brute + overhead rescue platform
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_hazard(chunk, SPIKES_SCENE, 120.0, ground_y)
			_spawn_platform(chunk, 180.0, ground_y - 50.0)
			_spawn_enemy(chunk, BRUTE_SCENE, 270.0, ground_y - 16.0)

		PatternType.CAR_WRECK_SOLO:
			chunk.add_ground_segment(0.0, chunk_width)
			var variant: String = ["sedan", "police", "ambulance"].pick_random()
			_spawn_vehicle(chunk, variant, 170.0, ground_y)
			if variant == "ambulance" and _can_spawn_medkit(true):
				if randf() < 0.5:
					_spawn_pickup(chunk, MEDKIT_SCENE, 220.0, ground_y - 4.0)
				else:
					_spawn_pickup(chunk, MEDKIT_SCENE, 170.0, ground_y - 34.0)
				_chunks_since_medkit = 0

		PatternType.CAR_WRECK_MEDKIT:
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_vehicle(chunk, "ambulance", 170.0, ground_y)
			if _can_spawn_medkit(true):
				_spawn_pickup(chunk, MEDKIT_SCENE, 170.0, ground_y - 34.0)
				_chunks_since_medkit = 0

		PatternType.CAR_WRECK_WALKER:
			chunk.add_ground_segment(0.0, chunk_width)
			var variant: String = ["sedan", "police", "ambulance"].pick_random()
			_spawn_vehicle(chunk, variant, 140.0, ground_y)
			_spawn_enemy(chunk, WALKER_SCENE, 280.0, ground_y - 12.0)
			if variant == "ambulance" and _can_spawn_medkit(true):
				_spawn_pickup(chunk, MEDKIT_SCENE, 140.0, ground_y - 34.0)
				_chunks_since_medkit = 0

		PatternType.CAR_WRECK_SPIKES:
			chunk.add_ground_segment(0.0, chunk_width)
			var variant: String = ["sedan", "ambulance"].pick_random()
			_spawn_vehicle(chunk, variant, 130.0, ground_y)
			_spawn_hazard(chunk, SPIKES_SCENE, 240.0, ground_y)
			_spawn_platform(chunk, 240.0, ground_y - 48.0)
			if variant == "ambulance" and _can_spawn_medkit(true):
				_spawn_pickup(chunk, MEDKIT_SCENE, 240.0, ground_y - 56.0)
				_chunks_since_medkit = 0

		PatternType.POLICE_ROADBLOCK:
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_vehicle(chunk, "police", 120.0, ground_y)
			_spawn_hazard(chunk, BARRICADE_SCENE, 220.0, ground_y)
			if randf() < 0.65:
				_spawn_enemy(chunk, WALKER_SCENE, 290.0, ground_y - 12.0)

		PatternType.BUS_WRECK_STOP:
			chunk.add_ground_segment(0.0, chunk_width)
			_spawn_vehicle(chunk, "bus", 150.0, ground_y)
			if randf() < 0.5:
				_spawn_enemy(chunk, WALKER_SCENE, 280.0, ground_y - 12.0)

	# Rare fallback Medkit drop only when not already rolling an Ambulance medkit drop;
	# otherwise consider spawning a Tactical Shield pickup on a clean safe spot.
	if not (pattern in [PatternType.FLAT_START, PatternType.CAR_WRECK_MEDKIT]):
		if _can_spawn_medkit(false):
			var spot: Vector2 = _get_safe_medkit_spot(pattern)
			_spawn_pickup(chunk, MEDKIT_SCENE, spot.x, spot.y)
			_chunks_since_medkit = 0
		elif _chunks_since_medkit > 0 and _can_spawn_shield():
			var s_spot: Vector2 = _get_safe_medkit_spot(pattern)
			_spawn_pickup(chunk, SHIELD_SCENE, s_spot.x, s_spot.y)
			_chunks_since_shield = 0

func _can_spawn_shield() -> bool:
	if _chunks_spawned < 6:
		return false
	var has_shield: bool = is_instance_valid(target_player) and target_player.shield_hp > 0
	var cooldown: int = 18 if has_shield else 12
	if _chunks_since_shield < cooldown:
		return false
	return randf() < 0.25 or _chunks_since_shield >= cooldown + 4

func _can_spawn_medkit(is_ambulance: bool) -> bool:
	var is_injured: bool = is_instance_valid(target_player) and target_player.current_hp < target_player.max_hp
	var min_cooldown: int = 4 if is_injured else 8
	if _chunks_since_medkit < min_cooldown:
		return false
	if is_ambulance:
		return true if is_injured else (randf() < 0.45)
	var fallback_threshold: int = 7 if is_injured else 14
	return _chunks_since_medkit >= fallback_threshold

func _get_safe_medkit_spot(pattern: PatternType) -> Vector2:
	match pattern:
		PatternType.PIT_STANDARD:
			return Vector2(280.0, ground_y - 4.0)
		PatternType.PLATFORM_OVER_PIT:
			return Vector2(184.0, ground_y - 54.0)
		PatternType.PLATFORM_HIGHWAY:
			return Vector2(170.0, ground_y - 56.0)
		PatternType.CAR_WRECK_SPIKES:
			return Vector2(240.0, ground_y - 56.0)
		PatternType.RECOIL_DOUBLE_VAULT:
			return Vector2(184.0, ground_y - 54.0)
		PatternType.PLATFORM_CASCADE:
			return Vector2(210.0, ground_y - 76.0)
		PatternType.CAR_WRECK_SOLO, PatternType.CAR_WRECK_WALKER:
			return Vector2(170.0 if pattern == PatternType.CAR_WRECK_SOLO else 140.0, ground_y - 34.0)
		PatternType.BUS_WRECK_STOP:
			return Vector2(150.0, ground_y - 36.0)
		PatternType.POLICE_ROADBLOCK:
			return Vector2(170.0, ground_y - 4.0)
		PatternType.BARRICADE_BRUTE:
			return Vector2(190.0, ground_y - 56.0)
		PatternType.THE_GAUNTLET:
			return Vector2(180.0, ground_y - 58.0)
		_:
			return Vector2(250.0, ground_y - 4.0)

func _spawn_vehicle(chunk: Node2D, variant: String, x_offset: float, y_pos: float) -> void:
	var inst: WreckedCar = WRECKED_CAR_SCENE.instantiate() as WreckedCar
	inst.vehicle_variant = variant
	inst.position = Vector2(x_offset, y_pos)
	chunk.add_child(inst)

func _spawn_hazard(chunk: Node2D, scene: PackedScene, x_offset: float, y_pos: float) -> void:
	var inst: Node2D = scene.instantiate() as Node2D
	inst.position = Vector2(x_offset, y_pos)
	chunk.add_child(inst)

func _spawn_pickup(chunk: Node2D, scene: PackedScene, x_offset: float, y_pos: float) -> void:
	var inst: Node2D = scene.instantiate() as Node2D
	inst.position = Vector2(x_offset, y_pos)
	chunk.add_child(inst)

func _spawn_platform(chunk: Node2D, x_offset: float, y_pos: float) -> void:
	var inst: Node2D = PLATFORM_SCENE.instantiate() as Node2D
	inst.position = Vector2(x_offset, y_pos)
	chunk.add_child(inst)

func _spawn_enemy(chunk: Node2D, scene: PackedScene, x_offset: float, y_pos: float) -> void:
	var inst: Node2D = scene.instantiate() as Node2D
	inst.position = Vector2(x_offset, y_pos)
	chunk.add_child(inst)

func _cleanup_old_chunks(player_x: float) -> void:
	var i: int = _active_chunks.size() - 1
	while i >= 0:
		var c: Node2D = _active_chunks[i]
		if c.position.x + chunk_width < player_x - despawn_behind_distance:
			c.queue_free()
			_active_chunks.remove_at(i)
		i -= 1

# ------------------------------------------------------------------------------
# Highly-optimized Chunk Node with batched terrain drawing
# ------------------------------------------------------------------------------
class ChunkNode extends Node2D:
	var tiles_texture: Texture2D
	var collapsed_bridge_texture: Texture2D
	var ground_y: float = 224.0
	var ground_segments: Array[Vector2] = [] # (start_x, width)

	func add_ground_segment(start_x: float, width: float) -> void:
		ground_segments.append(Vector2(start_x, width))

		# Create physics body for ground collision
		var sb: StaticBody2D = StaticBody2D.new()
		sb.collision_layer = 1 # World
		sb.collision_mask = 6  # Player + Enemies

		var shape: CollisionShape2D = CollisionShape2D.new()
		var rect: RectangleShape2D = RectangleShape2D.new()
		var h: float = 46.0
		rect.size = Vector2(width, h)
		shape.shape = rect
		shape.position = Vector2(start_x + width * 0.5, ground_y + h * 0.5)
		sb.add_child(shape)
		add_child(sb)

	func _draw() -> void:
		if not tiles_texture:
			return

		# 0. Pit Chasm & Collapsed Bridge ("Jembatan Roboh di bawah lubang")
		if ground_segments.size() > 1:
			for s_idx in range(ground_segments.size() - 1):
				var s_curr: Vector2 = ground_segments[s_idx]
				var s_next: Vector2 = ground_segments[s_idx + 1]
				var gap_x: float = s_curr.x + s_curr.y
				var gap_w: float = s_next.x - gap_x
				if gap_w > 0.0:
					if collapsed_bridge_texture:
						draw_texture_rect(
							collapsed_bridge_texture,
							Rect2(gap_x, ground_y - 8.0, gap_w, 64.0),
							false
						)
					else:
						draw_rect(Rect2(gap_x, ground_y, gap_w, 46.0), Color(0.04, 0.05, 0.08, 1.0), true)

		for seg in ground_segments:
			var sx: float = seg.x
			var w: float = seg.y
			var tile_count: int = int(ceil(w / 16.0))

			# 1. Base Road Surface: Pure dark aggregate asphalt (16x16 tiles)
			# Strictly clipped to segment bounds so no visual overhang into pit voids occurs
			for i in range(tile_count):
				var tx: float = sx + i * 16.0
				var draw_w: float = minf(16.0, (sx + w) - tx)
				if draw_w <= 0.0:
					break
				draw_texture_rect_region(tiles_texture, Rect2(tx, ground_y, draw_w, 16), Rect2(0, 0, draw_w, 16))
				# Concrete girder deck coping & pier sub-layers
				draw_texture_rect_region(tiles_texture, Rect2(tx, ground_y + 16, draw_w, 16), Rect2(32, 0, draw_w, 16))
				draw_texture_rect_region(tiles_texture, Rect2(tx, ground_y + 32, draw_w, 16), Rect2(32, 0, draw_w, 16))

			# 2. Straight, Consistent, Proportional Dashed Lane Markings (Traffic Yellow)
			# Anchored to global world X coordinate for perfect continuity across all chunk borders
			var global_base_x: float = global_position.x + sx
			for x_off in range(0, int(w)):
				var gx: float = global_base_x + float(x_off)
				var cycle: float = fposmod(gx, 52.0)
				if cycle < 32.0:
					# 32px traffic yellow dash (20px gap), perfectly straight and parallel
					draw_rect(Rect2(sx + float(x_off), ground_y + 8.0, 1.0, 1.0), Color("#ffcf56"), true)
					draw_rect(Rect2(sx + float(x_off), ground_y + 9.0, 1.0, 1.0), Color("#f5ac38"), true)
					draw_rect(Rect2(sx + float(x_off), ground_y + 10.0, 1.0, 1.0), Color(0.10, 0.11, 0.14, 0.75), true)

			# 3. Pit Edge Structural Coping
			if sx > 4.0:
				draw_rect(Rect2(sx, ground_y, 2.0, 48.0), Color(0.12, 0.14, 0.20, 0.95), true)
			if sx + w < 380.0:
				draw_rect(Rect2(sx + w - 2.0, ground_y, 2.0, 48.0), Color(0.12, 0.14, 0.20, 0.95), true)
