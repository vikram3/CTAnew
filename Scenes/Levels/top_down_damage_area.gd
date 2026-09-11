extends Area2D

@export var damage: int = 10


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func do_damage() -> int:
	return damage


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	var player := body as Player
	if player.is_dead or player.is_invulnerable:
		return
	player.take_level_damage(damage, global_position)
