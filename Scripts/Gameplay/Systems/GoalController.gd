extends Node
class_name GoalController

signal goal_reached(body: Node2D)

@export var goal_area: Area2D
@export var player_group: StringName = &"player"


func _ready() -> void:
	if goal_area and not goal_area.body_entered.is_connected(_on_goal_body_entered):
		goal_area.body_entered.connect(_on_goal_body_entered)


func _on_goal_body_entered(body: Node2D) -> void:
	if body.is_in_group(player_group):
		goal_reached.emit(body)
