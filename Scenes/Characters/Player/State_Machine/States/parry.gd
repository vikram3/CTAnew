extends Node

@export var impact_effect: AnimatedSprite2D

func _on_parry_state_entered() -> void:
	impact_effect.stop()
	impact_effect.play("Counter", 5)
	get_parent().parent.apply_force(Vector2(-get_parent().parent.body.scale.x, 0), 10)
	Global._freeze(0.1, 0.4)
	Global.cam.screen_shake(10, 0.2)
	

func _on_parry_state_physics_processing(delta: float) -> void:
	if Input.is_action_pressed("Attack"):
		get_parent().parent.doing_counter = true
		get_parent().parent.parried = false
		return
	
	if !impact_effect.is_playing():
		get_parent().parent.can_block = true
		get_parent().parent.parried = false

func _on_parry_state_exited() -> void:
	get_parent().parent.can_block = true
	get_parent().check_hit.disabled = true
	get_parent().hurt_box.disabled = false
