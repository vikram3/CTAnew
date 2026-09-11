extends Node

func _on_counter_state_entered() -> void:
	get_parent().parent.velocity = Vector2.ZERO
	get_parent().hurt_box.disabled = true
	get_parent().anim.play("Counter")

func _reset():
	get_parent().parent.doing_counter = false
	get_parent().hurt_box.disabled = false
