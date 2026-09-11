extends Area2D
class_name ForestProjectile

@export var speed: float = 280.0
@export var damage: int = 16
@export var direction: Vector2 = Vector2.LEFT


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _process(delta: float) -> void:
	position += direction.normalized() * speed * delta
	if absf(position.x) > 2400.0:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 9.0, Color(1.0, 0.52, 0.12, 1.0))


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_level_damage(damage, global_position)
		queue_free()
