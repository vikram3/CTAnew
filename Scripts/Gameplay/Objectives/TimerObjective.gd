extends ObjectiveBase
class_name TimerObjective

@export var duration: float = 30.0
@export var completes_on_timeout: bool = false

var time_remaining: float = 0.0


func activate() -> void:
	super.activate()
	time_remaining = duration
	set_process(true)
	report_progress(time_remaining, duration)


func deactivate() -> void:
	set_process(false)
	super.deactivate()


func _process(delta: float) -> void:
	if not is_active or is_complete or is_failed:
		return
	time_remaining = maxf(time_remaining - delta, 0.0)
	report_progress(time_remaining, duration)
	if time_remaining <= 0.0:
		if completes_on_timeout:
			complete()
		else:
			fail()
