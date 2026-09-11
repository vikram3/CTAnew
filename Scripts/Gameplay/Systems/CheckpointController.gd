extends Node
class_name CheckpointController

signal checkpoint_activated(checkpoint: Marker2D)

@export var player: Node2D
@export var initial_checkpoint: Marker2D

var current_checkpoint: Marker2D


func _ready() -> void:
	current_checkpoint = initial_checkpoint


func activate_checkpoint(checkpoint: Marker2D) -> void:
	if checkpoint == null:
		return
	current_checkpoint = checkpoint
	checkpoint_activated.emit(checkpoint)


func restore_player() -> void:
	if player and current_checkpoint:
		player.global_position = current_checkpoint.global_position
