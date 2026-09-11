extends Node2D
class_name AttackTelegraph

@export var duration: float = 0.8
@export var horizontal: bool = true
@export var size: Vector2 = Vector2(600, 64)

var _elapsed: float = 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()
	if _elapsed >= duration:
		queue_free()


func _draw() -> void:
	var alpha := 0.2 + 0.45 * absf(sin(_elapsed * 16.0))
	if horizontal:
		draw_rect(Rect2(-size * 0.5, size), Color(1.0, 0.2, 0.08, alpha), true)
	else:
		draw_arc(Vector2.ZERO, size.x * 0.5, 0.0, TAU, 48, Color(1.0, 0.2, 0.08, alpha), 4.0)
