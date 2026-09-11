extends Dash


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Dash_End":
		get_parent().parent.can_ground_dash = true
