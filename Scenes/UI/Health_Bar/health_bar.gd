# health_bar.gd  –  attach to HealthBar (ProgressBar, child of CanvasLayer)
extends ProgressBar

@export var timer: Timer              # delay timer before damage bar catches up
@export var damage_bar: ProgressBar  # the "lag" bar behind the main bar

var health: float = 0.0

func _set_health(new_health: Variant) -> void:
	var prev = health
	health   = min(float(new_health), max_value)
	value    = health

	if health < prev:
		timer.start()        # damage bar will follow after delay
	else:
		damage_bar.value = health   # heal instantly

func _init_health(max_hp: float) -> void:
	health         = max_hp
	max_value      = max_hp
	value          = max_hp
	damage_bar.max_value = max_hp
	damage_bar.value     = max_hp

func _on_timer_timeout() -> void:
	damage_bar.value = health
