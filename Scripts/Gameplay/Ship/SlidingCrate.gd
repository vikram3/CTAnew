extends CharacterBody2D
class_name SlidingCrate

@export var slide_direction: Vector2 = Vector2.LEFT
@export var speed: float = 140.0


func _physics_process(_delta: float) -> void:
	velocity = slide_direction.normalized() * speed
	move_and_slide()
