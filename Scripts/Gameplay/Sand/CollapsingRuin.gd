extends StaticBody2D
class_name CollapsingRuin

@export var collapse_delay: float = 0.8

var _collapsing := false


func trigger_collapse() -> void:
	if _collapsing:
		return
	_collapsing = true
	await get_tree().create_timer(collapse_delay).timeout
	queue_free()
