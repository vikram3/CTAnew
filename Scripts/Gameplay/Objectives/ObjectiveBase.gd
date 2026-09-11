extends Node
class_name ObjectiveBase

signal completed(objective: ObjectiveBase)
signal failed(objective: ObjectiveBase)
signal progress_changed(objective: ObjectiveBase, current: float, target: float)

@export var objective_id: StringName
@export_multiline var failure_message: String
@export var counts_towards_completion: bool = true

var is_active: bool = false
var is_complete: bool = false
var is_failed: bool = false


func activate() -> void:
	is_active = true


func deactivate() -> void:
	is_active = false


func complete() -> void:
	if not is_active or is_complete or is_failed:
		return
	is_complete = true
	completed.emit(self)


func fail() -> void:
	if not is_active or is_complete or is_failed:
		return
	is_failed = true
	failed.emit(self)


func report_progress(current: float, target: float) -> void:
	progress_changed.emit(self, current, target)
