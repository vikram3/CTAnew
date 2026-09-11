extends RigidBody2D

@export var ray:RayCast2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	freeze = true

func _physics_process(delta: float) -> void:
	if ray.is_colliding():
		freeze = false
