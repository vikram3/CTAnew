extends Area2D

var stats: Stats

signal hit_received(damage_info: DamageInfo)

func _ready() -> void:
	
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area.has_method("do_damage"):
		apply_damage(area.do_damage())


func apply_damage(damage: int) -> void:
	if not stats:
		push_warning("HurtBox cannot apply damage without a Stats reference.")
		return
	stats.take_damage(damage)


func apply_hit(damage_info: DamageInfo) -> void:
	if damage_info == null:
		return
	apply_damage(damage_info.amount)
	hit_received.emit(damage_info)
