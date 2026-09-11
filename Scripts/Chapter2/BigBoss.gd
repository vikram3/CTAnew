extends Node2D
class_name BigBoss

@export var sword_wave_scene: PackedScene
@export var ground_slam_scene: PackedScene
@export var telegraph_scene: PackedScene
@export var attack_interval: float = 2.8
@export var telegraph_time: float = 0.8

var _attack_timer: float = 1.2
var _attack_index: int = 0
var _attacking: bool = false


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	if _attacking:
		return
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_start_attack()


func _start_attack() -> void:
	_attacking = true
	_attack_timer = attack_interval
	if _attack_index % 2 == 0:
		_sword_attack()
	else:
		_slam_attack()
	_attack_index += 1


func _sword_attack() -> void:
	var telegraph := _create_telegraph(true, Vector2(720, 58), global_position + Vector2(0, 60))
	await get_tree().create_timer(telegraph_time).timeout
	if not is_inside_tree():
		return
	var wave := sword_wave_scene.instantiate() as SwordWave
	get_parent().add_child(wave)
	wave.global_position = global_position + Vector2(-42, 60)
	wave.direction = -1.0
	_attacking = false


func _slam_attack() -> void:
	var target := _player_position()
	var telegraph := _create_telegraph(false, Vector2(260, 260), target)
	await get_tree().create_timer(telegraph_time).timeout
	if not is_inside_tree():
		return
	var slam := ground_slam_scene.instantiate() as GroundSlam
	get_parent().add_child(slam)
	slam.global_position = target
	_attacking = false


func _create_telegraph(horizontal: bool, size: Vector2, target: Vector2) -> AttackTelegraph:
	var telegraph := telegraph_scene.instantiate() as AttackTelegraph
	get_parent().add_child(telegraph)
	telegraph.global_position = target
	telegraph.horizontal = horizontal
	telegraph.size = size
	telegraph.duration = telegraph_time
	return telegraph


func _player_position() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	return player.global_position if player else global_position


func _draw() -> void:
	draw_circle(Vector2(0, -50), 31.0, Color(0.12, 0.1, 0.12, 1.0))
	draw_rect(Rect2(-37, -20, 74, 92), Color(0.18, 0.16, 0.18, 1.0))
	draw_circle(Vector2(-12, -56), 4.0, Color(1.0, 0.22, 0.08, 1.0))
	draw_circle(Vector2(12, -56), 4.0, Color(1.0, 0.22, 0.08, 1.0))
	draw_line(Vector2(34, 4), Vector2(75, -38), Color(0.78, 0.78, 0.7, 1.0), 10.0)
