extends Node2D
class_name BackgroundDuel

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse := sin(_time * 4.0) * 8.0
	draw_circle(Vector2(-46, -30), 16.0, Color(0.95, 0.3, 0.5, 1.0))
	draw_rect(Rect2(-59, -14, 26, 54), Color(0.85, 0.16, 0.36, 1.0))
	draw_line(Vector2(-33, 0), Vector2(-5, pulse), Color(1.0, 0.8, 0.85, 1.0), 5.0)
	draw_circle(Vector2(44, -38), 24.0, Color(0.12, 0.1, 0.12, 1.0))
	draw_rect(Rect2(18, -15, 52, 68), Color(0.2, 0.18, 0.2, 1.0))
	draw_line(Vector2(18, -2), Vector2(-2, -34 + pulse), Color(0.95, 0.7, 0.35, 1.0), 7.0)
