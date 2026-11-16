extends CPUParticles2D

func _ready() -> void:
	emitting = true
	var total_time: float = lifetime + 0.15
	get_tree().create_timer(total_time).timeout.connect(queue_free)
