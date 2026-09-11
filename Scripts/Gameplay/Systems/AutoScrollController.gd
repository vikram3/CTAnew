extends Node
class_name AutoScrollController

signal player_fell_behind
signal scroll_advanced(edge_x: float)

@export var player: Node2D
@export var speed: float = 150.0
@export var allowed_lag: float = 160.0
@export var start_edge_x: float = 0.0

var edge_x: float = 0.0


func _ready() -> void:
	edge_x = start_edge_x


func _process(delta: float) -> void:
	edge_x += speed * delta
	scroll_advanced.emit(edge_x)
	if player and player.global_position.x < edge_x - allowed_lag:
		player_fell_behind.emit()
