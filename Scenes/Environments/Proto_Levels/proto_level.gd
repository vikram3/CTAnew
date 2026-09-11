extends Node2D
## Level 3, Segment 1 controller — "New players flooding in..."
## Coin collecting + obstacle dodging across a larger open arena. Paint the
## map, scatter ~40 Coin instances, and place ShadowAvatar instances directly
## in the editor (their own warning/spawn/despawn timing is self-contained —
## this script doesn't spawn or drive them). This only wires HUD, win/lose,
## and the two tracked stats: coins collected and collision bursts taken.

signal level_completed(success: bool)

@export_group("Core Nodes")
@export var player: Player
@export var hud: Control
@export var game_over_panel: Control
@export var win_panel: Control

@export_group("Spawn Points")
@export var player_start: Marker2D

@export_group("Objective")
@export var required_coins: int = 30
@export var max_collision_bursts: int = 5
@export var intro_text: String = "New players flooding in... better grab what I can before it gets crazy!"
@export var burst_warning_text: String = "Watch out!"
@export var toast_duration: float = 1.2

var _status_label: Label
var _coin_label: Label
var _burst_label: Label
var _burst_count: int = 0
var _level_finished: bool = false
var _toast_timer: Timer


func _ready() -> void:
	CollectedItems.reset()
	_wire_player()
	_wire_hud()
	_wire_panels()
	_wire_shadow_avatars()

	CollectedItems.coins_collected.connect(_on_coins_collected)

	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	add_child(_toast_timer)
	_toast_timer.timeout.connect(_restore_status_text)


func _wire_player() -> void:
	if not player:
		return
	player.add_to_group("player")
	player.movement_mode = Player.MovementMode.PLATFORMER
	if player_start:
		player.position = player_start.position


func _wire_hud() -> void:
	if not hud:
		return
	_status_label = hud.get_node_or_null("StatusLabel") as Label
	_coin_label = hud.get_node_or_null("CoinLabel") as Label
	_burst_label = hud.get_node_or_null("BurstLabel") as Label

	if _status_label:
		_status_label.text = intro_text
	_update_hud()


func _wire_panels() -> void:
	if game_over_panel:
		game_over_panel.hide()
		game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	if win_panel:
		win_panel.hide()
		win_panel.process_mode = Node.PROCESS_MODE_ALWAYS


## Shadow Avatars are self-driving (see shadow_avatar.gd) — this just listens
## for the one signal that matters to the win/lose condition. Works for any
## number of them scattered across the arena in the editor.
func _wire_shadow_avatars() -> void:
	for avatar in get_tree().get_nodes_in_group("shadow_avatars"):
		if avatar.has_signal("player_hit") and not avatar.player_hit.is_connected(_on_collision_burst):
			avatar.player_hit.connect(_on_collision_burst)


func _on_coins_collected() -> void:
	_update_hud()
	if CollectedItems.coins_amount >= required_coins:
		_finish(true)


func _on_collision_burst() -> void:
	if _level_finished:
		return
	_burst_count += 1
	_update_hud()

	if _status_label:
		_status_label.text = burst_warning_text
	if _toast_timer:
		_toast_timer.start(toast_duration)

	if _burst_count >= max_collision_bursts:
		_finish(false)


func _restore_status_text() -> void:
	if _status_label and not _level_finished:
		_status_label.text = intro_text


func _update_hud() -> void:
	if _coin_label:
		_coin_label.text = "%d / %d" % [CollectedItems.coins_amount, required_coins]
	if _burst_label:
		_burst_label.text = "Bursts: %d / %d" % [_burst_count, max_collision_bursts]


func _finish(success: bool) -> void:
	if _level_finished:
		return
	_level_finished = true

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
