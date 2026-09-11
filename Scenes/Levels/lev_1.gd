extends Node2D
## Tutorial level controller.
##
## This script no longer generates the level at runtime. Paint the TileMap,
## place Coin / Prop / Guard scenes, and set patrol points directly in the
## Godot editor. This script only wires up signals, HUD text, the camera,
## night/glow atmosphere, and win/lose flow.

signal level_completed(success: bool)

# ---------------------------------------------------------------------------
# Core references — assign these in the Inspector.
# ---------------------------------------------------------------------------
@export_group("Core Nodes")
@export var player: Player
@export var exit_door: ExitDoor
@export var hud: Control
@export var game_over_panel: Control
@export var win_panel: Control
@export var tile_map: TileMap

# ---------------------------------------------------------------------------
# Spawn points — drop Marker2D nodes in the scene and link them here.
# If left empty, the player/exit keep whatever position they already have
# in the scene tree (i.e. exactly where you placed them in the editor).
# ---------------------------------------------------------------------------
@export_group("Spawn Points")
@export var player_start: Marker2D
@export var exit_position: Marker2D

# ---------------------------------------------------------------------------
# Gameplay tuning
# ---------------------------------------------------------------------------
@export_group("Objective")
@export var required_coins: int = 20
@export var objective_text: String = "Time to grab those coins before anyone notices..."
@export var exit_open_text: String = "The exit is open. Slip out before the skull guards notice."
@export var missing_coins_text: String = "Need more coins."
@export var hidden_text: String = "Hidden"
@export var toast_duration: float = 1.4

@export_group("Stealth Pacing")
## The heist deliberately gets hotter as the player secures more loot. These
## thresholds create a readable opening, a contested mid-game, and a tense exit.
@export var alert_threshold_one: int = 7
@export var alert_threshold_two: int = 14
@export var guard_alert_multipliers: PackedFloat32Array = PackedFloat32Array([1.0, 1.12, 1.26])

# ---------------------------------------------------------------------------
# Camera
# ---------------------------------------------------------------------------
@export_group("Camera")
@export var camera_zoom: Vector2 = Vector2(0.8, 0.8)
@export var camera_smoothing_enabled: bool = true
@export var camera_smoothing_speed: float = 6.0
@export var use_camera_limits: bool = false
@export var camera_limit_rect: Rect2 = Rect2()

# ---------------------------------------------------------------------------
# Collision layers — exposed so you can tune them per-level without editing code.
# ---------------------------------------------------------------------------
@export_group("Collision")
@export_flags_2d_physics var player_collision_layer: int = 2
@export_flags_2d_physics var player_collision_mask: int = 1

# ---------------------------------------------------------------------------
# Night / glow atmosphere
#
# CanvasModulate darkens the whole scene uniformly (your "it's night" base
# layer). WorldEnvironment's Environment resource should have glow_enabled
# on — that's what makes any PointLight2D / emissive sprite actually bloom
# instead of just being a flat bright circle. Individual lights (on coins,
# lamps, the exit door, guards) stay as Light2D nodes placed in the editor;
# this script just toggles/tunes the ones that need to react to gameplay.
# ---------------------------------------------------------------------------
@export_group("Night Atmosphere")
@export var canvas_modulate: CanvasModulate
@export var night_tint: Color = Color(0.12, 0.12, 0.22)
@export var world_environment: WorldEnvironment

## Light on/under the exit door. Starts disabled and switches on once the
## player has collected enough coins, doubling as a visual "exit is open" cue.
@export var exit_light: PointLight2D
@export var exit_light_energy: float = 1.0
@export var exit_light_fade_time: float = 0.6

## Optional: a group name applied to guard PointLight2D "vision" lights, in
## case you want to dim/brighten them globally (e.g. a stealth-boost pickup).
@export var guard_light_group: String = "guard_lights"
@export var guard_light_color: Color = Color(1.0, 0.22, 0.16, 1.0)
@export_range(0.0, 2.0, 0.05) var guard_light_energy: float = 0.65

var _status_label: Label
var _toast_timer: Timer
var _level_finished: bool = false
var _base_status_text: String
var _guard_alert_phase: int = 0


func _ready() -> void:
	CollectedItems.reset()
	_base_status_text = objective_text
	_wire_level()
	_update_objective_status()


func _wire_level() -> void:
	_wire_player()
	_wire_exit_door()
	_wire_hud()
	_wire_panels()
	_wire_night_atmosphere()

	CollectedItems.coins_collected.connect(_on_coins_collected)

	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	add_child(_toast_timer)
	_toast_timer.timeout.connect(_restore_objective_text)


func _wire_player() -> void:
	if not player:
		return

	player.add_to_group("player")
	player.collision_layer = player_collision_layer
	player.collision_mask = player_collision_mask

	if player_start:
		player.position = player_start.position

	player.died.connect(_on_player_died)
	player.hidden_state_changed.connect(_on_player_hidden_state_changed)

	_configure_camera()


func _wire_exit_door() -> void:
	if not exit_door:
		return

	if exit_position:
		exit_door.position = exit_position.position

	exit_door.required_coins = required_coins
	exit_door.exit_reached.connect(_on_exit_reached)
	exit_door.missing_coins.connect(_on_exit_missing_coins)

	if exit_light:
		exit_light.enabled = false
		exit_light.energy = 0.0


func _wire_hud() -> void:
	if not hud:
		return

	_status_label = hud.get_node_or_null("StatusLabel") as Label
	if _status_label:
		_status_label.text = objective_text


func _wire_panels() -> void:
	if game_over_panel:
		game_over_panel.hide()
		game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	if win_panel:
		win_panel.hide()
		win_panel.process_mode = Node.PROCESS_MODE_ALWAYS


func _wire_night_atmosphere() -> void:
	if canvas_modulate:
		canvas_modulate.color = night_tint

	if world_environment and world_environment.environment:
		world_environment.environment.glow_enabled = true

	# Guard lights are a readable, low-intensity warning in the dark. They
	# support the patrol game without revealing the entire maze at once.
	for node in get_tree().get_nodes_in_group(guard_light_group):
		var guard_light := node as PointLight2D
		if guard_light:
			guard_light.color = guard_light_color
			if guard_light.has_method("set_light_energy"):
				guard_light.call("set_light_energy", guard_light_energy)
			else:
				guard_light.energy = guard_light_energy


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


func _on_coins_collected() -> void:
	if CollectedItems.coins_amount >= required_coins:
		_base_status_text = exit_open_text
		if _status_label:
			_status_label.text = _base_status_text
		_light_exit_door()
		return

	_update_alert_phase()
	_update_objective_status()


func _update_alert_phase() -> void:
	var target_phase: int = 0
	if CollectedItems.coins_amount >= alert_threshold_two:
		target_phase = 2
	elif CollectedItems.coins_amount >= alert_threshold_one:
		target_phase = 1

	if target_phase == _guard_alert_phase:
		return

	var previous_multiplier: float = guard_alert_multipliers[_guard_alert_phase]
	var next_multiplier: float = guard_alert_multipliers[target_phase]
	var ratio: float = next_multiplier / previous_multiplier
	_guard_alert_phase = target_phase

	for node in get_tree().get_nodes_in_group("level_1_guards"):
		var guard := node as CharacterBody2D
		if not guard:
			continue
		guard.set("patrol_speed", float(guard.get("patrol_speed")) * ratio)
		guard.set("chase_speed", float(guard.get("chase_speed")) * ratio)
		guard.set("chase_distance", float(guard.get("chase_distance")) * ratio)

	for node in get_tree().get_nodes_in_group(guard_light_group):
		var guard_light := node as PointLight2D
		if guard_light:
			var alert_energy: float = guard_light_energy * (1.0 + 0.18 * _guard_alert_phase)
			if guard_light.has_method("set_light_energy"):
				guard_light.call("set_light_energy", alert_energy)
			else:
				guard_light.energy = alert_energy


func _update_objective_status() -> void:
	if not _status_label:
		return

	var progress := "Coins: %d / %d" % [CollectedItems.coins_amount, required_coins]
	match _guard_alert_phase:
		0:
			_base_status_text = "%s  Stay low. Cover breaks pursuit." % progress
		1:
			_base_status_text = "%s  Patrols are alert. Lose sight, then hide." % progress
		_:
			_base_status_text = "%s  Final sweep. Plan the route to the exit." % progress
	_status_label.text = _base_status_text


func _light_exit_door() -> void:
	if not exit_light or exit_light.enabled:
		return

	exit_light.enabled = true
	var tween := create_tween()
	tween.tween_property(exit_light, "energy", exit_light_energy, exit_light_fade_time) \
		.from(0.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_exit_missing_coins(_needed: int) -> void:
	if _status_label:
		_status_label.text = missing_coins_text
	if _toast_timer:
		_toast_timer.start(toast_duration)


func _restore_objective_text() -> void:
	if _status_label:
		_status_label.text = _base_status_text


func _on_player_hidden_state_changed(is_hidden: bool) -> void:
	if not _status_label:
		return
	_status_label.text = hidden_text if is_hidden else _base_status_text


func _on_player_died() -> void:
	var has_completion_listener := not level_completed.get_connections().is_empty()
	if has_completion_listener:
		level_completed.emit(false)
		return
	get_tree().paused = true
	if game_over_panel:
		game_over_panel.show()


func _on_exit_reached() -> void:
	if _level_finished:
		return
	_level_finished = true

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
	if not level_completed.get_connections().is_empty():
		level_completed.emit(false)
		return
	get_tree().change_scene_to_file(menu_scene_path)
