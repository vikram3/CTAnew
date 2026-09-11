extends Node

@onready var state_chart: StateChart = get_parent().state_chart
@onready var anim: AnimationPlayer = get_parent().anim
@onready var parent: CharacterBody2D = get_parent()
@onready var hurt_box: CollisionShape2D = get_parent().hurt_box
@onready var check_hit: CollisionShape2D = get_parent().check_hit

#func _physics_process(delta: float) -> void:
	#$"../CanvasLayer/Label".text = \
	#"can attack: %s  doing_counter: %s  can block: %s  hurt: %s  Ground Dash: %s  Air_Dash  %s  Parried: %s" % [
		#parent.can_attack,
		#parent.doing_counter,
		#parent.can_block,
		#parent.is_hurt,
		#parent.can_ground_dash,
		#parent.can_air_dash,
		#parent.parried
	#]

func _transition():
	if parent.is_dead:
		state_chart.send_event("dead")
		return
	
	if parent.is_hurt:
		state_chart.send_event("hurt")
		return
	
	if parent.is_on_floor():
		state_chart.send_event("ground")
	else:
		state_chart.send_event("air")

func _on_ground_state_state_physics_processing(delta):
	if parent.doing_counter:
		state_chart.send_event("counter")
		return
	
	if parent.parried:
		state_chart.send_event("parry")
		return
	
	if !parent.can_block:
		state_chart.send_event("block")
		return
	
	if Input.is_action_just_pressed("block"):
		parent.can_block = false
	
	if !parent.can_attack:
		state_chart.send_event("attack")
		return
	
	if Input.is_action_just_pressed("Attack"):
		parent.can_attack = false
	
	if !parent.can_ground_dash:
		state_chart.send_event("dash")
		return
	
	if Input.is_action_just_pressed("dash"):
		parent.can_ground_dash = false
	
	if parent._set_direction().x != 0:
		state_chart.send_event("run")
	else:
		state_chart.send_event("idle")

func _on_air_state_state_physics_processing(delta):
	if !parent.can_attack:
		state_chart.send_event("attack")
		return
	
	if Input.is_action_just_pressed("Attack"):
		parent.can_attack = false
	
	if !parent.can_air_dash:
		state_chart.send_event("dash")
		return
	
	if Input.is_action_just_pressed("dash"):
		parent.can_air_dash = false
	
	if parent.velocity.y >= 0.0:
		state_chart.send_event("fall")
	else:
		if parent.can_double_jump == false:
			state_chart.send_event("double_jump")
		else:
			state_chart.send_event("jump")
