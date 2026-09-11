extends Node
class_name ProjectileHazardSpawner

@export var projectile_scene: PackedScene
@export var spawn_parent: Node
@export var spawn_point: Marker2D
@export var interval: float = 2.0


func _ready() -> void:
	_spawn_loop()


func _spawn_loop() -> void:
	while is_inside_tree():
		if projectile_scene and spawn_point:
			var projectile := projectile_scene.instantiate()
			(spawn_parent if spawn_parent else get_parent()).add_child(projectile)
			if projectile is Node2D:
				(projectile as Node2D).global_position = spawn_point.global_position
		await get_tree().create_timer(interval).timeout
