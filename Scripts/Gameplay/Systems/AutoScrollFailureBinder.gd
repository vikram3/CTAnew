extends Node
class_name AutoScrollFailureBinder

@export var auto_scroll_controller: AutoScrollController
@export var level_controller: LevelController


func _ready() -> void:
	if auto_scroll_controller and level_controller:
		auto_scroll_controller.player_fell_behind.connect(_on_player_fell_behind)


func _on_player_fell_behind() -> void:
	level_controller.fail("Horn caught up.")
