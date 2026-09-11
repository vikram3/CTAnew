extends Area2D
class_name QuicksandArea

@export var damage_per_second: int = 8


func _physics_process(delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_level_damage"):
			body.take_level_damage(maxi(1, roundi(damage_per_second * delta)), global_position)
