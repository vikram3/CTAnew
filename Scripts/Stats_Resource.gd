# stats_resource.gd
# Create this as a Resource. Go to: FileSystem → right-click → New Resource → StatsResource
# Save as e.g. res://Resources/player_stats.tres
extends Resource
class_name stats_resource

@export var max_health: float  = 100.0
@export var max_energy: float  = 50.0
@export var damage: float      = 15.0
@export var defense: float     = 2.0
@export var crit_chance: float = 0.15    # 0.0 – 1.0
@export var crit_damage: float = 2.0     # multiplier
@export var move_speed: float  = 100.0
