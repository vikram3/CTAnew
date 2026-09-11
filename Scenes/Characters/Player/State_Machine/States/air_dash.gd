extends Dash


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Air_Dash_End":
		get_parent().parent.can_air_dash = true
