extends Node
class_name LevelController

signal level_completed(success: bool)
signal level_finished(success: bool, message: String)

@export var config: LevelConfig
@export var player: Node2D
@export var player_start: Marker2D
@export var objective_controller: ObjectiveController
@export var win_panel: Control
@export var game_over_panel: Control

var is_finished: bool = false


func _ready() -> void:
	if config and config.reset_collected_items:
		CollectedItems.reset()
	_setup_player()
	_wire_objectives()
	_wire_panels()


func complete(message: String = "") -> void:
	_finish(true, message if message != "" else _success_message())


func fail(message: String = "") -> void:
	_finish(false, message if message != "" else _failure_message())


func _setup_player() -> void:
	if player == null:
		return
	player.add_to_group("player")
	if player_start:
		player.global_position = player_start.global_position
	if player.has_signal("died"):
		player.connect("died", _on_player_died)


func _wire_objectives() -> void:
	if objective_controller == null:
		return
	objective_controller.all_completed.connect(_on_objectives_completed)
	objective_controller.objective_failed.connect(_on_objective_failed)
	objective_controller.start()


func _wire_panels() -> void:
	if win_panel:
		win_panel.hide()
		win_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	if game_over_panel:
		game_over_panel.hide()
		game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS


func _on_player_died() -> void:
	fail()


func _on_objectives_completed() -> void:
	complete()


func _on_objective_failed(objective: ObjectiveBase) -> void:
	fail(objective.failure_message)


func _finish(success: bool, message: String) -> void:
	if is_finished:
		return
	is_finished = true
	level_finished.emit(success, message)
	level_completed.emit(success)
	if config and config.pause_on_finish:
		get_tree().paused = true
	if success and win_panel:
		win_panel.show()
	elif not success and game_over_panel:
		game_over_panel.show()


func _success_message() -> String:
	return config.success_message if config else ""


func _failure_message() -> String:
	return config.failure_message if config else ""
