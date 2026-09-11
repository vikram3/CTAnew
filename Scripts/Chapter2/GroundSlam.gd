extends Area2D
class_name GroundSlam

@export var collision_shape: CollisionShape2D
@export var damage: int = 28
@export var duration: float = 0.55

var _elapsed: float = 0.0
var _hit_player: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	var progress := clampf(_elapsed / duration, 0.0, 1.0)
	if collision_shape:
		collision_shape.scale = Vector2.ONE * maxf(progress, 0.15)
	queue_redraw()
	if progress >= 1.0:
		queue_free()


func _draw() -> void:
	var radius := 150.0 * clampf(_elapsed / duration, 0.0, 1.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1.0, 0.3, 0.05, 0.95), 6.0)


func _on_body_entered(body: Node2D) -> void:
	if _hit_player or not body.is_in_group("player"):
		return
	_hit_player = true
	if body.has_method("take_level_damage"):
		body.take_level_damage(damage, global_position)
