extends CharacterBody2D

@export var stats:Stats

@export var body:Node2D
@export var coin:AnimatedSprite2D
@export var fireball:AnimatedSprite2D
@export var hit:AnimatedSprite2D

@export var speed:float = 150.0

var dir:int

func _ready() -> void:
	dir = Global.player.body.scale.x
	body.scale.x = dir

func _physics_process(delta: float) -> void:
	velocity.x = speed * dir
	move_and_slide()

func _on_hit_box_body_entered(body) -> void:
	dir = 0
	coin.queue_free()
	fireball.queue_free()
	hit.play("hit")
	await hit.animation_finished
	queue_free()
