@tool
extends Node2D

@export var cam_limit_left: float = -200:
	set(value):
		cam_limit_left = value
		_request_redraw()

@export var cam_limit_right: float = 200:
	set(value):
		cam_limit_right = value
		_request_redraw()

@export var cam_limit_top: float = -150:
	set(value):
		cam_limit_top = value
		_request_redraw()

@export var cam_limit_bottom: float = 150:
	set(value):
		cam_limit_bottom = value
		_request_redraw()

@export var color: Color = Color(0, 1, 1, 0.9):
	set(value):
		color = value
		_request_redraw()

func _request_redraw():
	if Engine.is_editor_hint():
		queue_redraw()

func _draw():
	if not Engine.is_editor_hint():
		return

	var rect := Rect2(
		Vector2(cam_limit_left, cam_limit_top),
		Vector2(
			cam_limit_right - cam_limit_left,
			cam_limit_bottom - cam_limit_top
		)
	)

	draw_rect(rect, color, false, 4)
