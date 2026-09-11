extends Area2D
class_name SandSlowArea

@export_range(0.1, 1.0, 0.05) var speed_multiplier: float = 0.55


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.set_meta("sand_speed_multiplier", speed_multiplier)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.remove_meta("sand_speed_multiplier")
