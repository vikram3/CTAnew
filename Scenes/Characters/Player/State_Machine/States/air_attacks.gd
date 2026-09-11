extends Attacks

func _on_combo_1_state_entered():
	_attack_name("Air_Attack_1")

func _on_combo_2_state_entered():
	_attack_name("Air_Attack_2")

func _on_combo_3_state_entered():
	_attack_name("Air_Attack_3")


func _on_combo_3_state_processing(delta: float) -> void:
	get_parent().parent.move_and_slide()
	get_parent().parent.velocity.y += 980
