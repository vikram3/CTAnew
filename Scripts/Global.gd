# global.gd (autoload)
extends Node

#var boss:CharacterBody2D
var player: CharacterBody2D
var cam: Node   # assigned by camera node in _ready

# Hit-stop / freeze frames
func _freeze(duration: float, time_scale: float) -> void:
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration * time_scale).timeout
	Engine.time_scale = 1.0
