extends Node


func _on_fall_state_entered():
	get_parent().parent.can_ground_dash = true
	get_parent().anim.play("Fall")


func _on_fall_state_physics_processing(delta: float) -> void:
	pass
