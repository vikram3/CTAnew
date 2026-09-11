extends Node
class_name Stats

signal health_updated(health)
signal energy_updated(energy)
signal health_depleated
signal energy_depleated
signal health_changed(current_health: float, max_health: float)
signal died

@export var stats: stats_resource
@export var min_damage: float = 0.0

var current_health: float
var current_energy: float
var is_dead: bool = false


func _ready() -> void:
	if stats:
		initialize(stats)


func initialize(character_stats: stats_resource) -> void:
	stats = character_stats
	current_health = stats.max_health
	current_energy = stats.max_energy
	is_dead = false


# =================================
# DAMAGE GIVEN (USED BY HITBOX)
# =================================
func _damage_given() -> int:
	var damage = stats.damage
	# critical hit check
	if randf() <= stats.crit_chance:
		damage *= stats.crit_damage
	# minimum damage clamp
	damage = max(damage, min_damage)
	return damage


func get_damage() -> int:
	return _damage_given()


# =================================
# DAMAGE TAKEN (USED BY HURTBOX)
# =================================
func _damage_deduction(damage: int) -> void:
	var final_damage = damage - stats.defense
	final_damage = max(final_damage, min_damage)
	current_health -= final_damage
	emit_signal("health_updated", current_health)
	if current_health <= 0:
		current_health = 0
		emit_signal("health_depleated")
		if not is_dead:
			is_dead = true
			died.emit()
	health_changed.emit(current_health, stats.max_health)


func take_damage(damage: int) -> void:
	_damage_deduction(damage)


func take_damage_info(damage_info: DamageInfo) -> void:
	if damage_info:
		take_damage(damage_info.amount)


# =================================
# ENERGY MANAGEMENT
# =================================
func _energy_consumption(ammount) -> bool:
	if current_energy < ammount:
		return false

	_energy_deduction(ammount)
	return true


func _energy_deduction(value: float) -> void:
	current_energy -= value
	emit_signal("energy_updated", current_energy)
	if current_energy <= 0:
		current_energy = 0
		emit_signal("energy_depleated")


func _energy_refill(value: float) -> void:
	current_energy = min(current_energy + value, stats.max_energy)
	emit_signal("energy_updated", current_energy)


# =================================
# HEALTH MANAGEMENT
# =================================
func _health_refill(value: float) -> void:
	current_health = min(current_health + value, stats.max_health)
	emit_signal("health_updated", current_health)
