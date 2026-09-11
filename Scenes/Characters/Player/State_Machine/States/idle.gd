extends Node

@export var de_accel:float = 80.0

var actve:bool = false

func _on_idle_state_entered():
	actve = true
	#if get_parent().anim.current_animation == "Run_End" :
		#return
	get_parent().anim.play("Idle", -1, 1)

func _on_idle_state_physics_processing(delta):
	get_parent().parent.velocity.x = lerp(get_parent().parent.velocity.x,0.0, de_accel * delta)

func _on_idle_state_exited() -> void:
	actve = false

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if !actve:
		return
	
	if anim_name == "Run_End":
		get_parent().anim.play("Idle", -1, 0.5)
