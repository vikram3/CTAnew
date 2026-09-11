extends Area2D

var stats: Stats

signal hit_received(damage_info: DamageInfo)

@export var auto_receive_hits: bool = false

func _ready() -> void:
	stats = get_parent().get_parent().stats
	if auto_receive_hits:
		area_entered.connect(_on_area_entered)


func apply_damage(damage: int) -> void:
	stats.take_damage(damage)


func apply_hit(damage_info: DamageInfo) -> void:
	if damage_info == null:
		return
	var combatant := get_parent().get_parent()
	if combatant is EnemyBase:
		combatant.take_hit(damage_info)
	else:
		stats.take_damage_info(damage_info)
	hit_received.emit(damage_info)


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("get_damage_info"):
		apply_hit(area.get_damage_info())
	elif area.has_method("do_damage"):
		apply_damage(area.do_damage())
