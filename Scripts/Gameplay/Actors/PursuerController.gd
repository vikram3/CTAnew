extends CharacterBody2D
class_name PursuerController

signal charge_started
signal charge_hit(player: Node2D)

@export var detection_range: float = 280.0
@export var telegraph_time: float = 0.8
@export var charge_speed: float = 360.0
@export var charge_duration: float = 1.3
@export var cooldown_time: float = 1.0
@export var knockback_strength: float = 280.0

var _player: Node2D
var _timer: float = 0.0
var _state: StringName = &"idle"


func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node2D
	match _state:
		&"idle":
			if _player and global_position.distance_to(_player.global_position) <= detection_range:
				_state = &"telegraph"
				_timer = telegraph_time
		&"telegraph":
			_timer -= delta
			if _timer <= 0.0:
				_state = &"charge"
				_timer = charge_duration
				charge_started.emit()
		&"charge":
			_timer -= delta
			if _player:
				velocity = global_position.direction_to(_player.global_position) * charge_speed
			move_and_slide()
			if _player and global_position.distance_to(_player.global_position) < 34.0:
				_hit_player()
			if _timer <= 0.0:
				_state = &"cooldown"
				_timer = cooldown_time
		&"cooldown":
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer <= 0.0:
				_state = &"idle"


func _hit_player() -> void:
	if _player.has_method("take_level_damage"):
		_player.take_level_damage(18, global_position)
	if _player.has_method("apply_force"):
		_player.apply_force((_player.global_position - global_position).normalized(), knockback_strength)
	charge_hit.emit(_player)
	_state = &"cooldown"
	_timer = cooldown_time
