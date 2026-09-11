extends ObjectiveBase
class_name WaveObjective

@export var wave_controller: WaveController


func activate() -> void:
	super.activate()
	if wave_controller and not wave_controller.all_waves_completed.is_connected(_on_all_waves_completed):
		wave_controller.all_waves_completed.connect(_on_all_waves_completed)


func deactivate() -> void:
	if wave_controller and wave_controller.all_waves_completed.is_connected(_on_all_waves_completed):
		wave_controller.all_waves_completed.disconnect(_on_all_waves_completed)
	super.deactivate()


func _on_all_waves_completed() -> void:
	complete()
