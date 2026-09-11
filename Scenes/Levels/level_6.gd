extends Node2D
## Level 6 — "Better snap out of it... something doesn't feel right."
## Cliff ambush: CT, still lovestruck/distracted, has to survive Horn's
## charge attacks and a handful of Skull enemies on a set of narrow cliff
## platforms.
##
## IMPORTANT DESIGN NOTE: per the design doc, "get knocked off the cliff" is
## NOT a failure — it's the chapter's scripted physical consequence (the
## page 26 fall). So this level has exactly ONE real failure state (the
## player actually dying, e.g. worn down by Skulls), and TWO success paths:
## surviving the full timer, or falling off the cliff. `segment_ended`
## reports which one happened so your cutscene/page logic can branch
## correctly (survive vs. scripted fall want different follow-up beats),
## while `level_completed(bool)` stays true for both success paths for
## anything that only cares about pass/fail.
##
## SETUP NOTES
## - Place Horn and any Skull enemies directly in the editor, same as every
##   other level — nothing here spawns them.
## - `fall_y_threshold` is a world Y position: once the player's
##   global_position.y exceeds it (i.e. they've fallen below the lowest
##   platform, into the gap), that's read as "fell off the cliff." Set it
##   just below your lowest platform's collision, in the gap area, so a
##   normal jump/landing never crosses it but an actual fall off the edge
##   does.

signal level_completed(success: bool)
## outcome is one of: "survived", "scripted_fall", "failed"
signal segment_ended(outcome: String)

@export_group("Core Nodes")
@export var player: Player
@export var hud: Control
@export var game_over_panel: Control
@export var win_panel: Control
## Optional: a distinct panel/cutscene trigger for the scripted-fall ending,
## if you want it to look different from a normal win. Leave unassigned to
## just reuse win_panel for both success outcomes.
@export var scripted_fall_panel: Control

@export_group("Spawn Points")
@export var player_start: Marker2D

@export_group("Objective")
@export var survive_time: float = 60.0
## World Y position marking "fallen into the gap between platforms." See
## the setup note above for how to place this.
@export var fall_y_threshold: float = 2000.0
@export var intro_text: String = "Better snap out of it... something doesn't feel right."
@export var survived_text: String = "You made it through!"
@export var falling_text: String = "Whoa—!"

var _status_label: Label
var _timer_label: Label
var _time_remaining: float
var _level_finished: bool = false


func _ready() -> void:
	_time_remaining = survive_time
	_wire_player()
	_wire_hud()
	_wire_panels()


func _process(delta: float) -> void:
	if _level_finished:
		return

	if not player:
		return

	if player.global_position.y > fall_y_threshold:
		_finish(true, "scripted_fall", falling_text)
		return

	_time_remaining -= delta
	if _timer_label:
		_timer_label.text = "%d" % int(ceil(max(_time_remaining, 0.0)))

	if _time_remaining <= 0.0:
		_finish(true, "survived", survived_text)


func _wire_player() -> void:
	if not player:
		return
	player.add_to_group("player")
	player.movement_mode = Player.MovementMode.PLATFORMER
	if player_start:
		player.position = player_start.position
	if player.has_signal("died"):
		player.died.connect(_on_player_died)


func _wire_hud() -> void:
	if not hud:
		return
	_status_label = hud.get_node_or_null("StatusLabel") as Label
	_timer_label = hud.get_node_or_null("TimerLabel") as Label
	if _status_label:
		_status_label.text = intro_text
	if _timer_label:
		_timer_label.text = "%d" % int(survive_time)


func _wire_panels() -> void:
	if game_over_panel:
		game_over_panel.hide()
		game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	if win_panel:
		win_panel.hide()
		win_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	if scripted_fall_panel:
		scripted_fall_panel.hide()
		scripted_fall_panel.process_mode = Node.PROCESS_MODE_ALWAYS


func _on_player_died() -> void:
	_finish(false, "failed", "")


func _finish(success: bool, outcome: String, message: String) -> void:
	if _level_finished:
		return
	_level_finished = true

	if _status_label and message != "":
		_status_label.text = message

	segment_ended.emit(outcome)

	var has_completion_listener := not level_completed.get_connections().is_empty()
	level_completed.emit(success)
	if has_completion_listener:
		return

	get_tree().paused = true
	if outcome == "scripted_fall" and scripted_fall_panel:
		scripted_fall_panel.show()
	elif success and win_panel:
		win_panel.show()
	elif not success and game_over_panel:
		game_over_panel.show()


func restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func quit_to_menu(menu_scene_path: String = "res://Scenes/UI/TitleScreen.tscn") -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(menu_scene_path)
