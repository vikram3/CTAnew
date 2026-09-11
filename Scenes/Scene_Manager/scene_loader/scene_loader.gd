extends Node

@export var level_container: NodePath
@export var fade_layer: NodePath
@export var player: NodePath

@export var cam: Camera2D

var _current_level: Node = null
var _is_transitioning := false

func load_level(scene_path: String, spawn_id: String = "start") -> void:
	if _is_transitioning:
		return

	_is_transitioning = true

	_lock_player()

	var fade := get_node(fade_layer)
	await fade.fade_in()

	if _current_level:
		_current_level.queue_free()
		_current_level = null

	var packed_scene := load(scene_path)
	var level_instance = packed_scene.instantiate()
	get_node(level_container).add_child(level_instance)
	_current_level = level_instance

	_place_player(spawn_id)
	_reset_camera()
	_apply_level_camera_limits()
	_snap_camera_to_player()

	await fade.fade_out()

	_unlock_player()
	_is_transitioning = false

func _place_player(spawn_id: String) -> void:
	if not _current_level:
		return

	var spawn_points := _current_level.get_node_or_null("SpawnPoints")
	if not spawn_points:
		push_error("Level has no SpawnPoints node")
		return

	var spawn := spawn_points.get_node_or_null(spawn_id)
	if not spawn:
		push_error("Spawn point '%s' not found" % spawn_id)
		return

	var player_node := get_node(player)
	player_node.global_position = spawn.global_position

func _snap_camera_to_player():
	cam.get_parent().global_position = get_node(player).global_position
	cam.reset_smoothing()

func _reset_camera():
	cam.limit_left = -100000
	cam.limit_right = 100000
	cam.limit_top = -100000
	cam.limit_bottom = 100000

	cam.reset_smoothing()

func _apply_level_camera_limits():

	var limits := _current_level
	if limits == null:
		push_warning("Level has no CameraLimits node")
		return

	cam.limit_left = int(limits.cam_limit_left)
	cam.limit_right = int(limits.cam_limit_right)
	cam.limit_top = int(limits.cam_limit_top)
	cam.limit_bottom = int(limits.cam_limit_bottom)

	cam.reset_smoothing()

func _lock_player():
	var p := get_node(player)
	p.lock_input()

func _unlock_player():
	var p := get_node(player)
	p.unlock_input()
