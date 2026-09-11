extends ObjectiveBase
class_name CompositeObjective

@export var objectives: Array[ObjectiveBase] = []
@export var require_all: bool = true

var _completed_objectives: Dictionary = {}


func activate() -> void:
	super.activate()
	_completed_objectives.clear()
	for objective in objectives:
		if objective == null:
			continue
		if not objective.completed.is_connected(_on_objective_completed):
			objective.completed.connect(_on_objective_completed)
		if not objective.failed.is_connected(_on_objective_failed):
			objective.failed.connect(_on_objective_failed)
		objective.activate()


func deactivate() -> void:
	for objective in objectives:
		if objective:
			objective.deactivate()
	super.deactivate()


func _on_objective_completed(objective: ObjectiveBase) -> void:
	_completed_objectives[objective] = true
	if not require_all or _completed_objectives.size() >= _valid_objective_count():
		complete()


func _on_objective_failed(_objective: ObjectiveBase) -> void:
	fail()


func _valid_objective_count() -> int:
	var count: int = 0
	for objective in objectives:
		if objective:
			count += 1
	return count
