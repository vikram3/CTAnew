extends CharacterBody2D
class_name CompanionFollow

signal comment_requested(text: String)

@export var follow_distance: float = 48.0
@export var follow_speed: float = 180.0
@export var catch_up_distance: float = 420.0
@export var comments: Array[String] = []
@export var comment_interval_min: float = 9.0
@export var comment_interval_max: float = 16.0

var _player: Node2D
var _next_comment_at: float = 0.0


func _ready() -> void:
	add_to_group("companion")
	collision_layer = 0
	collision_mask = 0
	_next_comment_at = randf_range(comment_interval_min, comment_interval_max)


func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player == null:
		return
	var direction: float = sign(_player.global_position.x - global_position.x)
	var target := _player.global_position - Vector2(direction * follow_distance, 0)
	if global_position.distance_to(target) > catch_up_distance:
		global_position = target
	else:
		velocity = global_position.direction_to(target) * follow_speed
		move_and_slide()
	_next_comment_at -= delta
	if _next_comment_at <= 0.0:
		_next_comment_at = randf_range(comment_interval_min, comment_interval_max)
		if not comments.is_empty():
			comment_requested.emit(comments[randi() % comments.size()])
