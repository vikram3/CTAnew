extends Area2D

@export var hidden_message: String = "Hidden"


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.set_hidden_state(true)


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.set_hidden_state(false)
