extends Node
class_name Dash

@export var dash_time:float = 0.2
@export var dash_force:float = 550.0

@export var delay:float = 0.1
@export var anim_speed:float = 1.3

@export var starting_anim_name:StringName
@export var endng_anim_name:StringName

var dash_timer:float = 0.0

func _ready():
	dash_timer = dash_time

func _on_dash_state_entered():
	get_parent().parent.velocity = Vector2.ZERO
	get_parent().anim.play(starting_anim_name,-1,anim_speed)
	await get_tree().create_timer(delay).timeout
	get_parent().parent.cam_root.screen_shake(1,0.1)
	get_parent().parent.velocity.x = dash_force * get_parent().parent.body.scale.x

func _on_dash_state_physics_processing(delta):
	dash_timer -= delta
	dash_timer = clamp(dash_timer, 0.0, dash_time)
	
	if dash_timer <= 0.0:
		get_parent().parent.velocity.x = 0.0
		get_parent().anim.play(endng_anim_name)

func _on_dash_state_exited():
	dash_timer = dash_time
