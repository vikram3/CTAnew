extends Area2D
class_name Shockwave

signal burst_hit(body: Node2D)

@export var collision_shape: CollisionShape2D
@export var damage: int = 20
@export var duration: float = 0.35
@export var max_radius: float = 110.0

var _elapsed: float = 0.0
var _hit_player: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	var progress := clampf(_elapsed / duration, 0.0, 1.0)
	if collision_shape:
		collision_shape.scale = Vector2.ONE * maxf(progress, 0.1)
	queue_redraw()
	if progress >= 1.0:
		queue_free()


func _draw() -> void:
	var progress := clampf(_elapsed / duration, 0.0, 1.0)
	draw_arc(Vector2.ZERO, max_radius * progress, 0.0, TAU, 40, Color(1.0, 0.35, 0.08, 0.9), 5.0)


func _on_body_entered(body: Node2D) -> void:
	if _hit_player or not body.is_in_group("player"):
		return
	_hit_player = true
	if body.has_method("take_level_damage"):
		body.take_level_damage(damage, global_position)
	burst_hit.emit(body)
