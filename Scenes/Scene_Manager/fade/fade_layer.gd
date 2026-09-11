extends CanvasLayer

@export var fade_time := 0.3
@export var rect:ColorRect

func fade_in() -> void:
	rect.visible = true
	var tween := rect.create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, fade_time)
	await tween.finished

func fade_out() -> void:
	var tween := rect.create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, fade_time)
	await tween.finished
