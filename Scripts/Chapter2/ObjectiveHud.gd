extends CanvasLayer
class_name ObjectiveHud

@export var objective_controller: ObjectiveController
@export var status_label: Label
@export var detail_label: Label
@export var level_controller: LevelController


func _ready() -> void:
	if objective_controller == null:
		objective_controller = get_parent().get_node_or_null("ObjectiveController") as ObjectiveController
	if level_controller == null:
		level_controller = get_parent().get_node_or_null("LevelController") as LevelController
	if status_label == null:
		status_label = get_node_or_null("Status") as Label
	if detail_label == null:
		detail_label = get_node_or_null("Detail") as Label
	if objective_controller:
		objective_controller.objective_progress_changed.connect(_on_objective_progress_changed)
	if level_controller:
		level_controller.level_finished.connect(_on_level_finished)
	if objective_controller:
		for objective in objective_controller.objectives:
			if objective is CoinObjective:
				_on_objective_progress_changed(objective, CollectedItems.coins_amount, objective.required_coins)
			elif objective is TimerObjective or objective is SurvivalObjective:
				_on_objective_progress_changed(objective, objective.time_remaining, objective.duration)


func set_status(text: String) -> void:
	if status_label:
		status_label.text = text


func _on_objective_progress_changed(objective: ObjectiveBase, current: float, target: float) -> void:
	if detail_label == null:
		return
	if objective is CoinObjective:
		detail_label.text = "Coins: %d / %d" % [int(current), int(target)]
	elif objective is TimerObjective or objective is SurvivalObjective:
		detail_label.text = "Time: %d" % int(ceil(current))
	elif objective is HazardLimitObjective:
		detail_label.text = "Burst hits: %d / %d" % [int(current), int(target)]
	else:
		detail_label.text = "%s: %d / %d" % [str(objective.objective_id), int(current), int(target)]


func _on_level_finished(success: bool, message: String) -> void:
	if status_label and message != "":
		status_label.text = message
	elif status_label:
		status_label.text = "Complete" if success else "Failed"
