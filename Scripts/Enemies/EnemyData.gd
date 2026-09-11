extends Resource
class_name EnemyData

@export_category("Identity")
@export var enemy_id: StringName
@export var display_name: String

@export_category("Health")
@export var stats: stats_resource
@export var invulnerability_time: float = 0.0
@export var weaknesses: PackedStringArray = PackedStringArray()
@export var weakness_damage_multiplier: float = 1.5
@export var resistance_damage_multiplier: float = 0.5

@export_category("Movement")
@export var movement_speed: float = 0.0
@export var chase_speed: float = 0.0

@export_category("Attack")
@export var attack_type: StringName = &"melee"
@export var attack_damage: int = 0
@export var attack_range: float = 0.0
@export var projectile_scene: PackedScene
@export var knockback_strength: float = 0.0

@export_category("Death")
@export var death_behavior: StringName = &"animation"
