extends ObjectiveBase
class_name HazardLimitObjective

@export var allowed_hits: int = 4

var hit_count: int = 0


func _ready() -> void:
	counts_towards_completion = false


func register_hit() -> void:
	if not is_active:
		return
	hit_count += 1
	report_progress(hit_count, allowed_hits + 1)
	if hit_count > allowed_hits:
		fail()
