extends Node2D
## Level 2 controller — 2D platformer treasure chase.
##
## Pattern mirrors Level1Controller so the project stays consistent, but the
## rules are different: it's a straight-line/verticality run against a clock,
## not a stealth-and-collect level. Paint your platformer TileMap, place the
## Player, a Chest (Area2D) at the goal, and your Skull enemy scenes directly
## in the Godot editor — this script only wires signals, HUD, the timer, and
## win/lose flow.
##
## IMPORTANT SETUP NOTES
## 1. This does NOT create or drive Skull enemies. Build/keep your existing
##    Guard-style scene (renamed "Skull" or however you like) and just have it
##    add_to_group(skull_enemy_group) in its own _ready(). This controller only
##    needs that group name to optionally freeze them on win/lose.
## 2. The Chest is a plain Area2D you place in the editor — set its
##    Collision > monitoring on, give it a CollisionShape2D, and make sure the
##    Player's body is on a layer the chest's mask picks up. No custom script
##    needed on the chest itself, just assign it in the Inspector below.
## 3. Player.movement_mode is forced to PLATFORMER in code here (see
##    _wire_player), so you don't have to remember to flip it in the
##    Inspector — but flipping it there too is fine and makes the scene
##    self-documenting.

signal level_completed(success: bool)

# ---------------------------------------------------------------------------
# Core references — assign these in the Inspector.
# ---------------------------------------------------------------------------
@export_group("Core Nodes")
@export var player: Player
@export var chest: Area2D
@export var hud: Control
@export var game_over_panel: Control
@export var win_panel: Control
@export var tile_map: TileMap

# ---------------------------------------------------------------------------
# Spawn points
# ---------------------------------------------------------------------------
@export_group("Spawn Points")
@export var player_start: Marker2D

# ---------------------------------------------------------------------------
# Objective / timing
# ---------------------------------------------------------------------------
@export_group("Objective")
@export var time_limit: float = 60.0
@export var objective_text: String = "Run! Grab the treasure before time runs out!"
@export var time_up_text: String = "Time's up!"
@export var chest_reached_text: String = "Treasure secured!"
@export var caught_text: String = "Caught by a skull guard!"

# ---------------------------------------------------------------------------
# Skull enemies
# ---------------------------------------------------------------------------
@export_group("Skull Enemies")
## Group name your skull enemy scenes should add themselves to in their own
## _ready(). Used only to (optionally) freeze them once the level ends.
@export var skull_enemy_group: String = "skull_enemies"

# ---------------------------------------------------------------------------
# Chest glow (matches the "glowing chest marker" ask — reuses the same
# glow_enabled WorldEnvironment approach as Level 1's night atmosphere).
# ---------------------------------------------------------------------------
@export_group("Chest Glow")
@export var chest_light: PointLight2D
@export var world_environment: WorldEnvironment
@export var glow_pulse_enabled: bool = true
@export var glow_min_energy: float = 0.8
@export var glow_max_energy: float = 1.4
@export var glow_pulse_time: float = 0.9

# ---------------------------------------------------------------------------
# Camera (same knobs as Level 1, platformers usually want tighter vertical
# smoothing so it doesn't lag behind falls/jumps)
# ---------------------------------------------------------------------------
@export_group("Camera")
@export var camera_zoom: Vector2 = Vector2(1.0, 1.0)
@export var camera_smoothing_enabled: bool = true
@export var camera_smoothing_speed: float = 8.0
@export var use_camera_limits: bool = false
@export var camera_limit_rect: Rect2 = Rect2()

# ---------------------------------------------------------------------------
# Collision layers
# ---------------------------------------------------------------------------
@export_group("Collision")
@export_flags_2d_physics var player_collision_layer: int = 2
@export_flags_2d_physics var player_collision_mask: int = 1

var _status_label: Label
var _timer_label: Label
var _time_remaining: float
var _level_finished: bool = false


func _ready() -> void:
	_time_remaining = time_limit
	_wire_level()


func _wire_level() -> void:
	_wire_player()
	_wire_chest()
	_wire_hud()
	_wire_panels()
	_wire_chest_glow()


func _process(delta: float) -> void:
	if _level_finished:
		return

	_time_remaining -= delta
	if _timer_label:
		_timer_label.text = "%d" % int(ceil(max(_time_remaining, 0.0)))

	if _time_remaining <= 0.0:
		_on_time_up()


func _wire_player() -> void:
	if not player:
		return

	player.add_to_group("player")
	player.collision_layer = player_collision_layer
	player.collision_mask = player_collision_mask
	player.movement_mode = Player.MovementMode.PLATFORMER

	if player_start:
		player.position = player_start.position

	player.died.connect(_on_player_caught)

	_configure_camera()


func _wire_chest() -> void:
	if not chest:
		return
	if chest.has_signal("body_entered"):
		chest.body_entered.connect(_on_chest_body_entered)


func _on_chest_body_entered(body: Node) -> void:
	if body == player:
		_on_chest_reached()


func _wire_hud() -> void:
	if not hud:
		return

	_status_label = hud.get_node_or_null("StatusLabel") as Label
	_timer_label = hud.get_node_or_null("TimerLabel") as Label

	if _status_label:
		_status_label.text = objective_text
	if _timer_label:
		_timer_label.text = "%d" % int(time_limit)


func _wire_panels() -> void:
	if game_over_panel:
		game_over_panel.hide()
		game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	if win_panel:
		win_panel.hide()
		win_panel.process_mode = Node.PROCESS_MODE_ALWAYS


func _wire_chest_glow() -> void:
	if world_environment and world_environment.environment:
		world_environment.environment.glow_enabled = true

	if chest_light and glow_pulse_enabled:
		chest_light.enabled = true
		var tween := create_tween().set_loops()
		tween.tween_property(chest_light, "energy", glow_max_energy, glow_pulse_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(chest_light, "energy", glow_min_energy, glow_pulse_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _configure_camera() -> void:
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if not camera:
		return

	camera.enabled = true
	camera.position_smoothing_enabled = camera_smoothing_enabled
	camera.position_smoothing_speed = camera_smoothing_speed
	camera.zoom = camera_zoom

	if use_camera_limits and camera_limit_rect.size != Vector2.ZERO:
		camera.limit_left = int(camera_limit_rect.position.x)
		camera.limit_top = int(camera_limit_rect.position.y)
		camera.limit_right = int(camera_limit_rect.position.x + camera_limit_rect.size.x)
		camera.limit_bottom = int(camera_limit_rect.position.y + camera_limit_rect.size.y)


# ---------------------------------------------------------------------------
# Win / lose flow — same "emit signal, but let a listener override the
# default panel" pattern as Level1Controller.
# ---------------------------------------------------------------------------
func _on_chest_reached() -> void:
	if _level_finished:
		return
	_level_finished = true

	if _status_label:
		_status_label.text = chest_reached_text
	_freeze_skulls()

	var has_completion_listener := not level_completed.get_connections().is_empty()
	level_completed.emit(true)
	if has_completion_listener:
		return

	get_tree().paused = true
	if win_panel:
		win_panel.show()


func _on_time_up() -> void:
	if _level_finished:
		return
	_level_finished = true

	if _status_label:
		_status_label.text = time_up_text
	_freeze_skulls()

	var has_completion_listener := not level_completed.get_connections().is_empty()
	level_completed.emit(false)
	if has_completion_listener:
		return

	get_tree().paused = true
	if game_over_panel:
		game_over_panel.show()


func _on_player_caught() -> void:
	if _level_finished:
		return
	_level_finished = true

	if _status_label:
		_status_label.text = caught_text
	_freeze_skulls()

	var has_completion_listener := not level_completed.get_connections().is_empty()
	if has_completion_listener:
		level_completed.emit(false)
		return

	get_tree().paused = true
	if game_over_panel:
		game_over_panel.show()


func _freeze_skulls() -> void:
	for skull in get_tree().get_nodes_in_group(skull_enemy_group):
		if skull.has_method("freeze"):
			skull.freeze()


func restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func quit_to_menu(menu_scene_path: String = "res://Scenes/UI/TitleScreen.tscn") -> void:
	get_tree().paused = false
	if not level_completed.get_connections().is_empty():
		level_completed.emit(false)
		return
	get_tree().change_scene_to_file(menu_scene_path)
