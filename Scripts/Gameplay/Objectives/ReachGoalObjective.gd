extends ObjectiveBase
class_name ReachGoalObjective

@export var goal_controller: GoalController


func activate() -> void:
	super.activate()
	if goal_controller and not goal_controller.goal_reached.is_connected(_on_goal_reached):
		goal_controller.goal_reached.connect(_on_goal_reached)


func deactivate() -> void:
	if goal_controller and goal_controller.goal_reached.is_connected(_on_goal_reached):
		goal_controller.goal_reached.disconnect(_on_goal_reached)
	super.deactivate()


func _on_goal_reached(_body: Node2D) -> void:
	complete()
