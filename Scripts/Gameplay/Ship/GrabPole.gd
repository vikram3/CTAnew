extends Area2D
class_name GrabPole

signal grabbed(player: Node2D)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		grabbed.emit(body)
