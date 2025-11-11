extends RayCast3D

signal is_focusing_enemy

func _process(delta: float) -> void:
	var is_enabled = enabled
	if is_enabled:
		if is_colliding():
			var hit = get_collider()
			is_focusing_enemy.emit(true)
		else:
			is_focusing_enemy.emit(false)
