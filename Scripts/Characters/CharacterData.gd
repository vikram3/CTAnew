extends Resource
class_name CharacterData

@export var character_id: StringName
@export var display_name: String
@export var stats: stats_resource
@export var projectile_scene: PackedScene
@export var shield_hits: int = 0
@export var close_range_damage_type: StringName = &"physical"
