extends Node
class_name HazardController

signal player_hit_hazard(hazard: Node)

@export var hazards: Array[Node] = []


func _ready() -> void:
	for hazard in hazards:
		if hazard and hazard.has_signal("player_hit"):
			hazard.connect("player_hit", _on_player_hit_hazard.bind(hazard))


func report_player_hit(hazard: Node) -> void:
	player_hit_hazard.emit(hazard)


func _on_player_hit_hazard(hazard: Node) -> void:
	report_player_hit(hazard)
