extends Area2D
class_name SwordWave

@export var collision_shape: CollisionShape2D
@export var speed: float = 500.0
@export var direction: float = 1.0
@export var damage: int = 22
@export var lifetime: float = 3.0

var _elapsed: float = 0.0
var _hit_player: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _process(delta: float) -> void:
	position.x += speed * direction * delta
	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()


func _draw() -> void:
	draw_rect(Rect2(-38, -10, 76, 20), Color(1.0, 0.55, 0.12, 0.95), true)
	draw_line(Vector2(-46, 0), Vector2(46, 0), Color(1.0, 0.95, 0.7, 1.0), 3.0)


func _on_body_entered(body: Node2D) -> void:
	if _hit_player or not body.is_in_group("player"):
		return
	_hit_player = true
	if body.has_method("take_level_damage"):
		body.take_level_damage(damage, global_position)
