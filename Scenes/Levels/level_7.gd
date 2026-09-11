extends Node2D
## Level 7 — "Alright Flex, lead the way — but watch out for what's in these
## woods!" Relaxed forest exploration: collect coins scattered (including
## hidden clusters) across an open biome, light enemy presence, Felix
## tagging along as a non-interactive companion. No timer, no combat
## pressure — the design doc's tone here is "light exploration + bonding,"
## so this controller deliberately has no fail-by-running-out-of-time path.
##
## SETUP NOTES
## - Scatter ~50 Coin instances across the map (some in hidden/tucked-away
##   spots per the design doc) — same as every other level, painted in the
##   editor, nothing spawned at runtime.
## - Place light Skull/forest enemy instances (enemy.gd, top_down_mode =
##   false) sparsely; "light enemy presence" per the doc, not a combat focus.
## - Felix just needs to exist in the scene with felix.gd attached; he finds
##   the player himself via the "player" group, same pattern as your other
##   NPCs. No wiring needed here beyond the optional export below (only used
##   for the intro banter line, not required for him to function).

signal level_completed(success: bool)

@export_group("Core Nodes")
@export var player: Player
@export var felix: CharacterBody2D
@export var hud: Control
@export var win_panel: Control

@export_group("Spawn Points")
@export var player_start: Marker2D
@export var felix_start: Marker2D

@export_group("Objective")
@export var required_coins: int = 35
@export var intro_text: String = "Alright Flex, lead the way — but watch out for what's in these woods!"
@export var goal_reached_text: String = "That's plenty — nice haul!"

var _status_label: Label
var _coin_label: Label
var _level_finished: bool = false


func _ready() -> void:
	CollectedItems.reset()
	_wire_player()
	_wire_felix()
	_wire_hud()
	_wire_panel()

	CollectedItems.coins_collected.connect(_on_coins_collected)


func _wire_player() -> void:
	if not player:
		return
	player.add_to_group("player")
	player.movement_mode = Player.MovementMode.PLATFORMER
	if player_start:
		player.position = player_start.position


func _wire_felix() -> void:
	if not felix:
		return
	if felix_start:
		felix.global_position = felix_start.global_position


func _wire_hud() -> void:
	if not hud:
		return
	_status_label = hud.get_node_or_null("StatusLabel") as Label
	_coin_label = hud.get_node_or_null("CoinLabel") as Label
	if _status_label:
		_status_label.text = intro_text
	_update_hud()


func _wire_panel() -> void:
	if win_panel:
		win_panel.hide()
		win_panel.process_mode = Node.PROCESS_MODE_ALWAYS


func _on_coins_collected() -> void:
	_update_hud()
	if CollectedItems.coins_amount >= required_coins:
		_finish()


func _update_hud() -> void:
	if _coin_label:
		_coin_label.text = "%d / %d" % [CollectedItems.coins_amount, required_coins]


func _finish() -> void:
	if _level_finished:
		return
	_level_finished = true

	if _status_label:
		_status_label.text = goal_reached_text

	var has_completion_listener := not level_completed.get_connections().is_empty()
	level_completed.emit(true)
	if has_completion_listener:
		return

	get_tree().paused = true
	if win_panel:
		win_panel.show()


func restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func quit_to_menu(menu_scene_path: String = "res://Scenes/UI/TitleScreen.tscn") -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(menu_scene_path)
