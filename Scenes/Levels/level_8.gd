extends Node2D
## Level 8 - "Horn is somewhere in these woods... keep moving!"
## Chapter 4, Segment 1: auto-scrolling forest chase. This scene is an
## editable duplicate of the existing platformer level setup; move platforms,
## enemies, coins, and hazards directly in the editor.

signal level_completed(success: bool)

@export_group("Core Nodes")
@export var player: CharacterBody2D
@export var hud: Control
@export var game_over_panel: Control
@export var win_panel: Control
@export var player_start: Marker2D
@export var exit_area: Area2D

@export_group("Objective")
@export var intro_text := "Horn is somewhere in these woods... keep moving!"
@export_multiline var objective_text := "Reach the end before the chase catches you."
@export var clear_text := "Escaped the forest chase!"
@export var required_coins := 0
@export var required_defeats := 0
@export var survive_time := 0.0
@export var timer_can_win := false
@export var auto_scroll_speed := 2.5
@export var auto_complete_on_coins := false
@export var fall_y_threshold := 2200.0

var _status_label: Label
var _coin_label: Label
var _timer_label: Label
var _defeats := 0
var _time_remaining := 0.0
var _scroll_edge_x := 0.0
var _level_finished := false


func _ready() -> void:
	_time_remaining = survive_time
	_auto_find_nodes()
	_wire_player()
	_wire_hud()
	_wire_panels()
	_wire_exit()
	_wire_enemies()
	CollectedItems.reset()
	CollectedItems.coins_collected.connect(_on_coins_changed)
	_update_hud()


func _process(delta: float) -> void:
	if _level_finished or not player:
		return
	if player.global_position.y > fall_y_threshold:
		_finish(false, "You fell out of the chase.")
		return
	if survive_time > 0.0:
		_time_remaining = maxf(_time_remaining - delta, 0.0)
		if _time_remaining <= 0.0:
			if timer_can_win and _requirements_met():
				_finish(true, clear_text)
			else:
				_finish(false, "Time's up.")
			return
	if auto_scroll_speed > 0.0:
		_scroll_edge_x += auto_scroll_speed * 60.0 * delta
		if player.global_position.x < _scroll_edge_x - 160.0:
			_finish(false, "Horn caught up.")
			return
	_update_hud()


func _auto_find_nodes() -> void:
	player = player if player else get_node_or_null("Player") as CharacterBody2D
	hud = hud if hud else get_node_or_null("CanvasLayer2/HUD") as Control
	game_over_panel = game_over_panel if game_over_panel else get_node_or_null("CanvasLayer2/GameOverPanel") as Control
	win_panel = win_panel if win_panel else get_node_or_null("CanvasLayer2/WinPanel") as Control
	player_start = player_start if player_start else get_node_or_null("Start") as Marker2D
	exit_area = exit_area if exit_area else get_node_or_null("TransitionArea") as Area2D


func _wire_player() -> void:
	if not player:
		return
	player.add_to_group("player")
	if player_start:
		player.global_position = player_start.global_position
	if player.has_signal("died"):
		player.died.connect(_on_player_died)


func _wire_hud() -> void:
	if not hud:
		return
	_status_label = hud.get_node_or_null("StatusLabel") as Label
	_coin_label = hud.get_node_or_null("CoinLabel") as Label
	if not _coin_label:
		_coin_label = hud.get_node_or_null("Label") as Label
	_timer_label = hud.get_node_or_null("TimerLabel") as Label


func _wire_panels() -> void:
	if game_over_panel:
		game_over_panel.hide()
		game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	if win_panel:
		win_panel.hide()
		win_panel.process_mode = Node.PROCESS_MODE_ALWAYS


func _wire_exit() -> void:
	if exit_area and exit_area.has_signal("body_entered"):
		exit_area.body_entered.connect(_on_exit_body_entered)


func _wire_enemies() -> void:
	var enemies := get_node_or_null("enemies")
	if not enemies:
		return
	for enemy in enemies.get_children():
		if enemy.has_signal("defeated"):
			enemy.defeated.connect(_on_enemy_defeated)


func _on_coins_changed() -> void:
	_update_hud()
	if auto_complete_on_coins and required_coins > 0 and CollectedItems.coins_amount >= required_coins:
		_finish(true, clear_text)


func _on_enemy_defeated() -> void:
	_defeats += 1
	_update_hud()


func _on_player_died() -> void:
	_finish(false, "You ran out of health.")


func _on_exit_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if _requirements_met():
			_finish(true, clear_text)
		elif _status_label:
			_status_label.text = _missing_text()


func _requirements_met() -> bool:
	return CollectedItems.coins_amount >= required_coins and _defeats >= required_defeats


func _missing_text() -> String:
	var parts: Array[String] = []
	if CollectedItems.coins_amount < required_coins:
		parts.append("%d more coins" % (required_coins - CollectedItems.coins_amount))
	if _defeats < required_defeats:
		parts.append("%d more enemies" % (required_defeats - _defeats))
	return "Need " + ", ".join(parts) + "."


func _update_hud() -> void:
	if _status_label and not _level_finished:
		_status_label.text = intro_text
	if _coin_label:
		_coin_label.text = "Coins: %d / %d" % [CollectedItems.coins_amount, required_coins] if required_coins > 0 else "Coins: %d" % CollectedItems.coins_amount
	if _timer_label:
		var parts: Array[String] = []
		if survive_time > 0.0:
			parts.append("Time: %d" % int(ceil(_time_remaining)))
		if required_defeats > 0:
			parts.append("Defeats: %d / %d" % [_defeats, required_defeats])
		_timer_label.text = " | ".join(parts)


func _finish(success: bool, message: String) -> void:
	if _level_finished:
		return
	_level_finished = true
	if _status_label:
		_status_label.text = message
	var has_completion_listener := not level_completed.get_connections().is_empty()
	level_completed.emit(success)
	if has_completion_listener:
		return
	get_tree().paused = true
	if success and win_panel:
		win_panel.show()
	elif not success and game_over_panel:
		game_over_panel.show()


func restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func quit_to_menu(menu_scene_path: String = "res://Scenes/UI/TitleScreen.tscn") -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(menu_scene_path)
