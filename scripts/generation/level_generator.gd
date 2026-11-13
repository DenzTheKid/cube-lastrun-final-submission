extends Node2D
class_name LevelGenerator

# Modular procedural endless runner level generator.
# Generates continuous terrain chunks, obstacles, and enemy encounters ahead of the player.
# Automatically validates pattern fairness and frees retired chunks behind the horde.

@export var chunk_width: float = 384.0
@export var ground_y: float = 224.0
@export var spawn_ahead_distance: float = 850.0
@export var despawn_behind_distance: float = 450.0

var target_player: Player = null
var next_chunk_x: float = 0.0
var _active_chunks: Array[Node2D] = []

# Preloaded obstacle and enemy scenes
const SPIKES_SCENE: PackedScene = preload("res://scenes/obstacles/spikes.tscn")
const BARRICADE_SCENE: PackedScene = preload("res://scenes/obstacles/barricade.tscn")
const PLATFORM_SCENE: PackedScene = preload("res://scenes/obstacles/platform.tscn")
const PIT_SCENE: PackedScene = preload("res://scenes/obstacles/pit_killzone.tscn")

const WALKER_SCENE: PackedScene = preload("res://scenes/enemies/zombie_walker.tscn")
const RUNNER_SCENE: PackedScene = preload("res://scenes/enemies/zombie_runner.tscn")
const BRUTE_SCENE: PackedScene = preload("res://scenes/enemies/zombie_brute.tscn")
const MUTANT_SCENE: PackedScene = preload("res://scenes/enemies/zombie_mutant.tscn")

const URBAN_TILES: Texture2D = preload("res://assets/environment/urban_tiles.png")

enum PatternType {
	FLAT_START,
	WALKER_PATROL,
	RUNNER_RUSH,
	SPIKE_JUMP,
	PIT_CROSSING,
	BARRICADE_BRUTE,
	PLATFORM_OVER_HAZARD,
	MUTANT_AMBUSH,
	RECOIL_DOUBLE_CHALLENGE
}

var _last_pattern: PatternType = PatternType.FLAT_START
var _chunks_spawned: int = 0

func setup(player: Player) -> void:
	target_player = player
	next_chunk_x = -192.0 # Start slightly behind player
	# Spawn initial safe chunks
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
	var chunk: Node2D = Node2D.new()
	chunk.name = "Chunk_%d" % _chunks_spawned
	chunk.position = Vector2(next_chunk_x, 0)
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
	var choices: Array[PatternType] = [
		PatternType.WALKER_PATROL,
		PatternType.RUNNER_RUSH,
		PatternType.SPIKE_JUMP,
		PatternType.PIT_CROSSING,
		PatternType.PLATFORM_OVER_HAZARD
	]

	# At higher difficulty, unlock Brutes, Mutants, and complex recoil challenges
	if diff > 1.25:
		choices.append(PatternType.BARRICADE_BRUTE)
		choices.append(PatternType.MUTANT_AMBUSH)
	if diff > 1.5:
		choices.append(PatternType.RECOIL_DOUBLE_CHALLENGE)

	# Rule: Never spawn two consecutive pit crossings or barricade brutes (prevents unfair bottlenecks)
	var candidate: PatternType = choices.pick_random()
	if candidate == _last_pattern and (candidate == PatternType.PIT_CROSSING or candidate == PatternType.BARRICADE_BRUTE):
		candidate = PatternType.WALKER_PATROL

	return candidate

func _build_chunk_content(chunk: Node2D, pattern: PatternType) -> void:
	match pattern:
		PatternType.FLAT_START:
			_create_solid_ground(chunk, 0.0, chunk_width)

		PatternType.WALKER_PATROL:
			_create_solid_ground(chunk, 0.0, chunk_width)
			_spawn_enemy(chunk, WALKER_SCENE, 180.0, ground_y - 12.0)
			if randf() > 0.4:
				_spawn_enemy(chunk, WALKER_SCENE, 270.0, ground_y - 12.0)

		PatternType.RUNNER_RUSH:
			_create_solid_ground(chunk, 0.0, chunk_width)
			_spawn_enemy(chunk, RUNNER_SCENE, 300.0, ground_y - 12.0)

		PatternType.SPIKE_JUMP:
			_create_solid_ground(chunk, 0.0, chunk_width)
			_spawn_hazard(chunk, SPIKES_SCENE, 180.0, ground_y)
			if randf() > 0.5:
				_spawn_enemy(chunk, WALKER_SCENE, 310.0, ground_y - 12.0)

		PatternType.PIT_CROSSING:
			# 128px ground -> 80px pit -> 176px ground
			_create_solid_ground(chunk, 0.0, 128.0)
			# Pit hazard at bottom
			_spawn_hazard(chunk, PIT_SCENE, 168.0, ground_y + 40.0)
			_create_solid_ground(chunk, 208.0, 176.0)

		PatternType.PLATFORM_OVER_HAZARD:
			_create_solid_ground(chunk, 0.0, chunk_width)
			# Spikes on floor
			_spawn_hazard(chunk, SPIKES_SCENE, 180.0, ground_y)
			# Elevated bridge above spikes
			_spawn_platform(chunk, 180.0, ground_y - 50.0)
			_spawn_enemy(chunk, WALKER_SCENE, 320.0, ground_y - 12.0)

		PatternType.BARRICADE_BRUTE:
			_create_solid_ground(chunk, 0.0, chunk_width)
			_spawn_hazard(chunk, BARRICADE_SCENE, 160.0, ground_y)
			_spawn_enemy(chunk, BRUTE_SCENE, 260.0, ground_y - 18.0)

		PatternType.MUTANT_AMBUSH:
			_create_solid_ground(chunk, 0.0, chunk_width)
			_spawn_hazard(chunk, SPIKES_SCENE, 140.0, ground_y)
			_spawn_enemy(chunk, MUTANT_SCENE, 280.0, ground_y - 14.0)

		PatternType.RECOIL_DOUBLE_CHALLENGE:
			# High barricade with pit behind it, rewarding a shotgun recoil jump!
			_create_solid_ground(chunk, 0.0, 140.0)
			_spawn_hazard(chunk, BARRICADE_SCENE, 120.0, ground_y)
			_spawn_hazard(chunk, PIT_SCENE, 180.0, ground_y + 40.0)
			_create_solid_ground(chunk, 220.0, 164.0)
			_spawn_platform(chunk, 180.0, ground_y - 65.0)

func _create_solid_ground(chunk: Node2D, start_x: float, width: float) -> void:
	var sb: StaticBody2D = StaticBody2D.new()
	sb.collision_layer = 1 # World
	sb.collision_mask = 6  # Player + Enemies

	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	var height: float = 46.0
	rect.size = Vector2(width, height)
	shape.shape = rect
	shape.position = Vector2(start_x + width * 0.5, ground_y + height * 0.5)
	sb.add_child(shape)

	# Render road tiles across width
	var tile_count: int = int(ceil(width / 16.0))
	for i in range(tile_count):
		var sp: Sprite2D = Sprite2D.new()
		sp.texture = URBAN_TILES
		sp.region_enabled = true
		# Alternating road tiles (dash line or plain curb)
		if (i % 4) == 2:
			sp.region_rect = Rect2(16, 0, 16, 16) # yellow dash
		else:
			sp.region_rect = Rect2(0, 0, 16, 16)  # plain road curb
		sp.position = Vector2(start_x + i * 16.0 + 8.0, ground_y + 8.0)
		sb.add_child(sp)

		# Ground fill underneath
		for fy in [24.0, 40.0]:
			var fill_sp: Sprite2D = Sprite2D.new()
			fill_sp.texture = URBAN_TILES
			fill_sp.region_enabled = true
			fill_sp.region_rect = Rect2(32, 0, 16, 16) # dirt/concrete fill
			fill_sp.position = Vector2(start_x + i * 16.0 + 8.0, ground_y + fy)
			sb.add_child(fill_sp)

	chunk.add_child(sb)

func _spawn_hazard(chunk: Node2D, scene: PackedScene, x_offset: float, y_pos: float) -> void:
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
