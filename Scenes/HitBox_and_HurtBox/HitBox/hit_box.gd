extends Area2D

var damage: int

@export var main_body: Node2D
@export var damage_type: StringName = &"physical"
@export var knockback_direction: Vector2 = Vector2.ZERO
@export var knockback_strength: float = 0.0


func do_damage() -> int:
	if main_body != null:
		damage = main_body.stats.get_damage()
		return damage
	else:
		damage = 10
		return damage


func get_damage_info() -> DamageInfo:
	return DamageInfo.new(
		do_damage(), main_body, damage_type, knockback_direction, knockback_strength
	)
