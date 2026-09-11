extends Node
class_name ShadowFloodController

signal burst_count_changed(total_bursts: int, player_hits: int)

@export var avatar_scene: PackedScene
@export var shockwave_scene: PackedScene
@export var spawn_parent: Node
@export var spawn_points: Array[Marker2D] = []
@export var spawn_interval: float = 3.0
@export var max_active_avatars: int = 3
@export var hazard_objective: HazardLimitObjective

var _active_avatars: int = 0
var _spawn_index: int = 0
var _burst_count: int = 0
var _player_hit_count: int = 0


func _ready() -> void:
	_spawn_loop()


func _spawn_loop() -> void:
	while is_inside_tree():
		if _active_avatars < max_active_avatars:
			_spawn_avatar()
		await get_tree().create_timer(spawn_interval).timeout


func _spawn_avatar() -> void:
	if avatar_scene == null or spawn_points.is_empty():
		return
	var avatar := avatar_scene.instantiate() as ShadowAvatar
	var parent := spawn_parent if spawn_parent else get_parent()
	parent.add_child(avatar)
	avatar.global_position = spawn_points[_spawn_index % spawn_points.size()].global_position
	_spawn_index += 1
	avatar.shockwave_scene = shockwave_scene
	avatar.burst_triggered.connect(_on_avatar_burst)
	avatar.despawned.connect(_on_avatar_despawned)
	_active_avatars += 1


func _on_avatar_burst(player_hit: bool) -> void:
	if not player_hit:
		_burst_count += 1
	else:
		_player_hit_count += 1
		if hazard_objective:
			hazard_objective.register_hit()
	burst_count_changed.emit(_burst_count, _player_hit_count)


func _on_avatar_despawned() -> void:
	_active_avatars = max(_active_avatars - 1, 0)
