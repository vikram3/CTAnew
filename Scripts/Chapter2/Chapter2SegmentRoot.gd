extends Node2D
class_name Chapter2SegmentRoot

signal level_completed(success: bool)

@export var level_controller: LevelController
@export var wave_controller: WaveController
@export var restart_button: Button
@export var quit_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if level_controller == null:
		level_controller = get_node_or_null("LevelController") as LevelController
	if wave_controller == null:
		wave_controller = get_node_or_null("WaveController") as WaveController
	if restart_button == null:
		restart_button = get_node_or_null("HUD/WinPanel/Restart") as Button
	if quit_button == null:
		quit_button = get_node_or_null("HUD/WinPanel/Quit") as Button
	if level_controller and not level_controller.level_completed.is_connected(_on_level_completed):
		level_controller.level_completed.connect(_on_level_completed)
	_connect_button(restart_button, restart_level)
	_connect_button(quit_button, quit_to_menu)
	_connect_button(get_node_or_null("HUD/GameOverPanel/Restart") as Button, restart_level)
	_connect_button(get_node_or_null("HUD/GameOverPanel/Quit") as Button, quit_to_menu)
	if wave_controller:
		wave_controller.call_deferred("start_waves")


func restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func quit_to_menu() -> void:
	get_tree().paused = false
	level_completed.emit(false)


func _on_level_completed(success: bool) -> void:
	level_completed.emit(success)


func _connect_button(button: Button, callback: Callable) -> void:
	if button and not button.pressed.is_connected(callback):
		button.pressed.connect(callback)
