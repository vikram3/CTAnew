extends CharacterBody2D
class_name EnemyBase

signal defeated

@export var stats: Stats
@export var enemy_data: EnemyData

var is_dead: bool = false


func _ready() -> void:
	_apply_enemy_data()
	if stats and not stats.health_depleated.is_connected(_on_health_depleated):
		stats.health_depleated.connect(_on_health_depleated)


func take_hit(damage_info: DamageInfo) -> void:
	if is_dead or stats == null:
		return
	stats.take_damage_info(_resolve_damage(damage_info))


func _resolve_damage(damage_info: DamageInfo) -> DamageInfo:
	if damage_info == null or enemy_data == null or enemy_data.weaknesses.is_empty():
		return damage_info
	var multiplier := enemy_data.weakness_damage_multiplier if enemy_data.weaknesses.has(str(damage_info.damage_type)) else enemy_data.resistance_damage_multiplier
	return damage_info.copy_with_amount(maxi(1, roundi(damage_info.amount * multiplier)))


func _apply_enemy_data() -> void:
	if enemy_data and enemy_data.stats and stats:
		stats.initialize(enemy_data.stats)


func _on_health_depleated() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	defeated.emit()
