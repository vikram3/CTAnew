extends Area2D
class_name FallDeathHazard

@export var level_controller: LevelController


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and level_controller:
		level_controller.fail("CT fell from the cliff.")
