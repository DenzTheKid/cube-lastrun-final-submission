extends Area2D
class_name RearHorde

# The pursuing rear zombie horde that chases the player from the left.
# Monitors distance, applies pressure, signals proximity to HUD,
# and catches the player if they fall behind.

@export var max_safe_distance: float = 230.0
@export var catch_threshold: float = 16.0 # distance at which player is grabbed
@export var base_catchup_speed: float = 135.0 # slightly less than player base speed

var target_player: Player = null
var current_x_offset: float = 220.0
var _pushback_stun_timer: float = 0.0
var _flash_timer: float = 0.0
var _last_pushback_callout_usec: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	collision_layer = 32 # Layer 6: Horde
	collision_mask = 2   # Layer 2: Player
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func set_player(player: Player) -> void:
	target_player = player

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target_player) or target_player.is_dead:
		return

	# Horde speed dynamically catches up based on difficulty and player progression
	var diff: float = GameManager.difficulty_factor if GameManager else 1.0
	var current_catchup_speed: float = (base_catchup_speed + (diff - 1.0) * 15.0)
	if _pushback_stun_timer > 0.0:
		_pushback_stun_timer -= delta
		current_catchup_speed *= 0.40
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0 and sprite:
			sprite.modulate = Color.WHITE

	# If player is moving fast, offset increases toward max_safe_distance
	# If player slows or stops, offset shrinks rapidly!
	var player_x: float = target_player.global_position.x
	var target_x: float = global_position.x + current_catchup_speed * delta

	# Never get further than max_safe_distance behind the player
	var min_horde_x: float = player_x - max_safe_distance
	target_x = maxf(target_x, min_horde_x)

	# Never overshoot past the player
	target_x = minf(target_x, player_x + 10.0)

	global_position.x = target_x
	# Keep Y aligned with camera / player floor level
	global_position.y = target_player.global_position.y

	# Calculate proximity (0.0 = safely distant, 1.0 = right on top of player)
	var distance_to_player: float = player_x - global_position.x
	var proximity: float = 1.0 - clampf((distance_to_player - catch_threshold) / (max_safe_distance - catch_threshold), 0.0, 1.0)

	if GameManager:
		GameManager.update_horde_proximity(proximity)

	# Check catch condition
	if distance_to_player <= catch_threshold:
		_catch_player()

func _catch_player() -> void:
	if is_instance_valid(target_player) and not target_player.is_dead and not target_player.is_transforming:
		target_player.trigger_horde_catch()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_catch_player()

func _on_area_entered(area: Area2D) -> void:
	var body: Node = area.get_parent()
	if body is Player:
		_catch_player()

func take_damage(_amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if not is_instance_valid(target_player) or target_player.is_dead or target_player.is_transforming:
		return
	if knockback_dir.x >= -0.2:
		return

	var min_horde_x: float = target_player.global_position.x - max_safe_distance
	global_position.x = maxf(global_position.x - 10.0, min_horde_x)
	_pushback_stun_timer = 0.55
	_flash_timer = 0.09
	if sprite:
		sprite.modulate = Color(1.45, 0.65, 0.50, 1.0)

	if AudioManager:
		AudioManager.play_sfx("zombie_hit", 0.12)

	var dist_to_player: float = target_player.global_position.x - global_position.x
	var now: int = Time.get_ticks_usec()
	if dist_to_player <= 165.0 and (now - _last_pushback_callout_usec) >= 1500000:
		_last_pushback_callout_usec = now
		if GameManager:
			GameManager.add_bonus_score(50)
		if GameFeel:
			GameFeel.camera_shake(0.28)
			GameFeel.spawn_voxel_debris(Vector2(global_position.x + 12.0, global_position.y), Color(0.75, 0.18, 0.22), 5)
			GameFeel.spawn_floating_text(Vector2(target_player.global_position.x - 32.0, target_player.global_position.y - 24.0), "HORDE PUSHBACK! +50", Color(1.0, 0.58, 0.22), 1.06)
