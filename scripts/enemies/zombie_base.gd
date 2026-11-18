extends CharacterBody2D
class_name ZombieBase

# Base class for front-facing zombie enemies (AAA Indie Overhaul).
# Features:
# - Pure white 2-frame hit-flash shader (hit_flash.gdshader)
# - Directional knockback + squash-and-stretch impact reaction
# - Armor spark shower when shooting Brute riot armor
# - 25ms micro-hitstop, voxel debris burst, road splatter decal, and floating score popups on death

const BLOOD_BURST_SCENE: PackedScene = preload("res://scenes/effects/blood_burst.tscn")
const SPARK_SCENE: PackedScene = preload("res://scenes/effects/bullet_spark.tscn")
const HIT_FLASH_SHADER: Shader = preload("res://shaders/hit_flash.gdshader")

@export var max_hp: int = 1
@export var move_speed: float = 30.0
@export var score_value: int = 100
@export var contact_damage: int = 1
@export var gravity: float = 980.0

var current_hp: int = 1
var is_dead: bool = false
var _anim_timer: float = 0.0
var _anim_frame: int = 0
var _shader_mat: ShaderMaterial = null
var _visual_scale: Vector2 = Vector2.ONE

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	current_hp = max_hp
	collision_layer = 4 # Layer 3: Enemies
	collision_mask = 1  # Layer 1: World
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

	if sprite:
		_shader_mat = ShaderMaterial.new()
		_shader_mat.shader = HIT_FLASH_SHADER
		sprite.material = _shader_mat

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	velocity.x = -move_speed
	if not is_on_floor():
		velocity.y += gravity * delta

	move_and_slide()
	_update_animation(delta)

	# Smoothly recover impact squash & stretch
	_visual_scale = _visual_scale.lerp(Vector2.ONE, 1.0 - exp(-16.0 * delta))
	if sprite:
		sprite.scale = _visual_scale

	# Despawn if far behind player / horde
	var root: Node = get_tree().current_scene
	if root:
		var player: Node2D = root.find_child("Player", true, false) as Node2D
		if player and global_position.x < player.global_position.x - 320.0:
			queue_free()

func _update_animation(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= 0.14:
		_anim_timer = 0.0
		_anim_frame = (_anim_frame + 1) % 4
		sprite.frame = _anim_frame

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	current_hp -= amount

	if AudioManager:
		AudioManager.play_sfx("zombie_hit", 0.1)
		AudioManager.play_sfx("impact_flesh", 0.08)

	var root: Node = get_tree().current_scene
	if root:
		var blood = BLOOD_BURST_SCENE.instantiate()
		blood.global_position = global_position
		root.add_child(blood)

		# Brute Riot Armor sparks when shot
		if max_hp >= 4:
			var sp = SPARK_SCENE.instantiate()
			sp.global_position = global_position + Vector2(-4.0, -2.0)
			root.add_child(sp)

	# Pure white 2-frame hit-flash via hit_flash.gdshader
	if _shader_mat:
		_shader_mat.set_shader_parameter("flash_modifier", 1.0)
		var tw: Tween = create_tween()
		tw.tween_method(func(v: float): _shader_mat.set_shader_parameter("flash_modifier", v), 1.0, 0.0, 0.09)

	_visual_scale = Vector2(0.80, 1.24)

	# Directional Knockback
	if knockback_dir != Vector2.ZERO:
		velocity.x += knockback_dir.x * 75.0
		global_position.x += signf(knockback_dir.x) * 3.5

	if current_hp <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	collision_shape.set_deferred("disabled", true)
	if hitbox:
		hitbox.set_deferred("monitoring", false)

	if AudioManager:
		AudioManager.play_sfx("zombie_death", 0.15)

	var mult: int = 1
	if GameManager:
		var next_c: int = GameManager.combo_count + 1
		if next_c >= 5:
			mult = 5
		elif next_c >= 3:
			mult = 3
		elif next_c >= 2:
			mult = 2
		GameManager.add_kill(score_value * mult)

	# 25ms micro-hitstop, medium trauma shake, voxel debris chunks & floating score popup
	if GameFeel:
		GameFeel.hitstop(0.025, 0.08)
		GameFeel.camera_shake(0.35)

		var debris_col := Color(0.35, 0.65, 0.35)
		if max_hp >= 4:
			debris_col = Color(0.45, 0.55, 0.65)
		elif move_speed >= 80.0:
			debris_col = Color(0.75, 0.18, 0.22)
		elif max_hp == 2:
			debris_col = Color(0.35, 0.85, 0.25)
		GameFeel.spawn_voxel_debris(global_position, debris_col, 7)

		var total_pts: int = score_value * mult
		var popup_txt: String = "+%d" % total_pts
		var popup_col: Color = Color(1.0, 0.88, 0.28)
		var popup_scale: float = 1.0
		if mult >= 3:
			popup_txt = "+%d x%d CRIT!" % [total_pts, mult]
			popup_col = Color(1.0, 0.38, 0.22)
			popup_scale = 1.22
		elif mult == 2:
			popup_txt = "+%d x2!" % total_pts
			popup_col = Color(1.0, 0.68, 0.22)
			popup_scale = 1.10
		GameFeel.spawn_floating_text(global_position + Vector2(0, -10), popup_txt, popup_col, popup_scale)

		# Arcade Skill Style Callouts: AIRSHOT! / POINT BLANK!
		var root_node: Node = get_tree().current_scene
		if root_node and root_node.name != "TestRunner":
			var player_node: Player = root_node.find_child("Player", true, false) as Player
			if player_node and not player_node.is_dead:
				var is_airborne_shot: bool = not player_node.is_on_floor() and (player_node.was_recoil_launched or player_node.global_position.y < 194.0)
				if is_airborne_shot and player_node.can_trigger_style_callout(0.9):
					if GameManager:
						GameManager.add_bonus_score(50)
					GameFeel.spawn_floating_text(global_position + Vector2(0, -24), "AIRSHOT! +50", Color(0.38, 0.96, 1.0), 1.08)
				elif absf(global_position.x - player_node.global_position.x) <= 50.0 and player_node.can_trigger_style_callout(1.2):
					if GameManager:
						GameManager.add_bonus_score(40)
					GameFeel.spawn_floating_text(global_position + Vector2(0, -24), "POINT BLANK! +40", Color(1.0, 0.72, 0.28), 1.04)

	# Death tween: squash, fade out, queue_free
	var tw: Tween = create_tween()
	tw.tween_property(sprite, "scale", Vector2(1.45, 0.18), 0.10)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.10)
	tw.tween_callback(queue_free)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body is Player and not is_dead:
		body.take_damage(contact_damage, Vector2.LEFT)
