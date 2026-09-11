extends Node

@export var hurt_box:Area2D

func _on_hurt_box_area_entered(area):
	get_parent().parent.velocity = Vector2.ZERO
	hurt_box.apply_damage(area.do_damage())
	get_parent().parent.can_block = true
	get_parent().parent.is_hurt = true
	get_parent().parent.apply_force(Vector2(area.get_parent().scale.x, 0.1), 22)
	Global.cam.screen_shake(8,0.1)
	Global._freeze(0.1,0.4)

func _on_hurt_state_entered():
	get_parent().anim.play("Hurt")
	await get_parent().anim.animation_finished
	get_parent().parent.is_hurt = false

func _on_hurt_state_physics_processing(delta):
	get_parent().parent.can_ground_dash = true
	get_parent().parent.can_air_dash = true
	get_parent().parent.can_attack = true
