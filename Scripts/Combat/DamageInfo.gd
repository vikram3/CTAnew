extends RefCounted
class_name DamageInfo

var amount: int
var damage_type: StringName
var source: Node2D
var knockback_direction: Vector2
var knockback_strength: float
var ignores_invulnerability: bool


func _init(
		damage_amount: int,
		attack_source: Node2D = null,
		attack_type: StringName = &"physical",
		direction: Vector2 = Vector2.ZERO,
		strength: float = 0.0,
		ignore_invulnerability: bool = false
	) -> void:
	amount = damage_amount
	source = attack_source
	damage_type = attack_type
	knockback_direction = direction
	knockback_strength = strength
	ignores_invulnerability = ignore_invulnerability


func copy_with_amount(new_amount: int) -> DamageInfo:
	return DamageInfo.new(
		new_amount, source, damage_type, knockback_direction, knockback_strength,
		ignores_invulnerability
	)
