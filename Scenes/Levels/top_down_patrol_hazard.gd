extends Area2D

@export var point_a: Vector2
@export var point_b: Vector2
@export var speed: float = 100.0
@export var damage: int = 12

var _target: Vector2


func _ready() -> void:
	_target = point_b
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if point_a == point_b:
		return

	var to_target := _target - global_position
	if to_target.length() <= speed * delta:
		global_position = _target
		_target = point_a if _target == point_b else point_b
	else:
		global_position += to_target.normalized() * speed * delta


func do_damage() -> int:
	return damage


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	var player := body as Player
	if player.is_dead or player.is_invulnerable or not player.hurt_box:
		return
	player.hurt_box.apply_damage(damage)
	player._start_invulnerability()
