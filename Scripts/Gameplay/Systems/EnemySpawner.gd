extends Node
class_name EnemySpawner

signal enemy_spawned(enemy: Node)

@export var enemy_scene: PackedScene
@export var spawn_points: Array[Marker2D] = []
@export var spawn_parent: Node
@export var initial_property_values: Dictionary = {}
@export var spawned_enemy_group: StringName = &"wave_enemy"

var _spawn_index: int = 0


func spawn_enemy() -> Node:
	if enemy_scene == null or spawn_points.is_empty():
		return null
	var enemy := enemy_scene.instantiate()
	var parent := spawn_parent if spawn_parent else get_parent()
	var spawn_point := spawn_points[_spawn_index % spawn_points.size()]
	_spawn_index += 1
	for property_name in initial_property_values:
		enemy.set(property_name, initial_property_values[property_name])
	if enemy is Node2D:
		if parent is Node2D:
			(enemy as Node2D).position = (parent as Node2D).to_local(spawn_point.global_position)
		else:
			(enemy as Node2D).position = spawn_point.global_position
	if spawned_enemy_group != &"":
		enemy.add_to_group(spawned_enemy_group)
	parent.add_child(enemy)
	enemy_spawned.emit(enemy)
	return enemy
