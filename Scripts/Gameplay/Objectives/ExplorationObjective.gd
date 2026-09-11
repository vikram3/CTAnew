extends ObjectiveBase
class_name ExplorationObjective

@export_range(0.0, 1.0, 0.01) var required_percent: float = 1.0

var explored_percent: float = 0.0


func report_exploration(percent: float) -> void:
	if not is_active:
		return
	explored_percent = clampf(percent, 0.0, 1.0)
	report_progress(explored_percent, required_percent)
	if explored_percent >= required_percent:
		complete()
