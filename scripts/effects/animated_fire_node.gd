extends Sprite2D
class_name AnimatedFireNode

# Steady, grounded 8-frame pixel-art fire node (stays firmly planted in place with zero vertical bouncing).

const FIRE_SHEET: Texture2D = preload("res://assets/effects/fire_animated_sheet.png")

@export var fps: float = 9.0
@export var base_scale: Vector2 = Vector2.ONE

var _time: float = 0.0


func _ready() -> void:
	texture = FIRE_SHEET
	hframes = 8
	vframes = 1
	_time = randf() * 8.0
	frame = int(_time * fps) % 8
	scale = base_scale


func _process(delta: float) -> void:
	_time += delta
	frame = int(_time * fps) % 8
