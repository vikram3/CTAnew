extends Node2D
class_name ShadowAvatar

signal burst_triggered(player_hit: bool)
signal despawned

@export var warning_time: float = 2.0
@export var lifetime: float = 8.0
@export var shockwave_scene: PackedScene
@export var burst_damage: int = 18

var _active: bool = false
var _pulse: float = 0.0


func _ready() -> void:
	queue_redraw()
	_start_sequence()


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func _start_sequence() -> void:
	await get_tree().create_timer(warning_time).timeout
	if not is_inside_tree():
		return
	_active = true
	_spawn_burst()
	await get_tree().create_timer(lifetime).timeout
	if is_inside_tree():
		despawned.emit()
		queue_free()


func _spawn_burst() -> void:
	if shockwave_scene == null:
		burst_triggered.emit(false)
		return
	var shockwave := shockwave_scene.instantiate() as Shockwave
	get_parent().add_child(shockwave)
	shockwave.global_position = global_position
	shockwave.damage = burst_damage
	shockwave.burst_hit.connect(_on_burst_hit)
	burst_triggered.emit(false)


func _on_burst_hit(_body: Node2D) -> void:
	burst_triggered.emit(true)


func _draw() -> void:
	var pulse := 0.5 + sin(_pulse * 8.0) * 0.5
	if not _active:
		draw_arc(Vector2.ZERO, 26.0 + pulse * 10.0, 0.0, TAU, 36, Color(0.9, 0.15, 0.2, 0.9), 3.0)
		draw_circle(Vector2.ZERO, 8.0, Color(0.9, 0.15, 0.2, 0.35))
		return
	draw_circle(Vector2(0, -8), 15.0, Color(0.08, 0.04, 0.12, 1.0))
	draw_rect(Rect2(-12, 5, 24, 30), Color(0.08, 0.04, 0.12, 1.0))
	draw_circle(Vector2(-5, -9), 2.0, Color(1.0, 0.32, 0.08, 1.0))
	draw_circle(Vector2(5, -9), 2.0, Color(1.0, 0.32, 0.08, 1.0))
