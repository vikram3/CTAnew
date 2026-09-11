extends Node


func _on_player_stats_health_depleated():
	get_parent().parent.is_dead = true

func _on_dead_state_entered():
	get_parent().anim.play("Dead")

func _on_dead_state_physics_processing(delta):
	get_parent().parent.velocity = Vector2.ZERO
#
