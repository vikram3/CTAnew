extends Node


func _on_double_jump_state_entered():
	get_parent().anim.play("Double_Jump")


func _on_double_jump_state_physics_processing(delta: float) -> void:
	pass
