extends Node
class_name CoinSpawner

@export var coin_scene: PackedScene
@export var spawn_parent: Node
@export var coin_count: int = 0
@export var spawn_rect: Rect2 = Rect2(-400, -220, 800, 440)
@export var seed: int = 0


func _ready() -> void:
	spawn_coins()


func spawn_coins() -> void:
	if coin_scene == null or coin_count <= 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var parent := spawn_parent if spawn_parent else get_parent()
	for index in range(coin_count):
		var coin := coin_scene.instantiate()
		parent.add_child(coin)
		if coin is Node2D:
			(coin as Node2D).position = Vector2(
				rng.randf_range(spawn_rect.position.x, spawn_rect.end.x),
				rng.randf_range(spawn_rect.position.y, spawn_rect.end.y)
			)
