extends CharacterBody2D

@export var fall_gravity:float = 800.0
@export var player_detector:ShapeCast2D

var fall:bool = false

func _physics_process(delta: float) -> void:
	move_and_slide()
	if player_detector.is_colliding():
		fall = true
	
	
	if fall:
		velocity.y += fall_gravity * delta
	
	if is_on_floor():
		queue_free()
