extends PointLight2D
## Attach directly to a PointLight2D (e.g. a wall lamp) to give it a subtle
## night-time flicker. Doesn't affect exit_light or guard vision lights
## unless you attach it to them too.

@export var flicker_speed: float = 8.0
@export var flicker_amount: float = 0.15
@export var randomize_phase: bool = true

var _base_energy: float
var _phase_offset: float = 0.0


func _ready() -> void:
	_base_energy = energy
	if randomize_phase:
		_phase_offset = randf() * TAU


func set_light_energy(value: float) -> void:
	_base_energy = value
	energy = value


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 * flicker_speed + _phase_offset
	energy = _base_energy + sin(t) * flicker_amount
