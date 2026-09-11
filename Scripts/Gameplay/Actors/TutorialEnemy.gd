extends EnemyBase
class_name TutorialEnemy

@export var category: StringName = &"tank"
@export var movement_speed: float = 80.0
@export var contact_damage: int = 12
@export var contact_range: float = 38.0
@export var color: Color = Color(0.7, 0.3, 0.2, 1.0)

var _player: Node2D
var _attack_cooldown: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group("enemy_" + category)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player == null:
		return
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	var distance := global_position.distance_to(_player.global_position)
	if distance > contact_range:
		velocity = global_position.direction_to(_player.global_position) * movement_speed
		move_and_slide()
	elif _attack_cooldown <= 0.0:
		_attack_cooldown = 1.0
		_player.take_level_damage(contact_damage, global_position)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 22.0, color)
	draw_circle(Vector2(-7, -5), 3.0, Color.WHITE)
	draw_circle(Vector2(7, -5), 3.0, Color.WHITE)
