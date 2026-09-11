extends Node

var reader_ref: Node = null
var game_instance: Node = null
var transition_overlay: ColorRect = null
var is_transitioning: bool = false
var is_segment_active: bool = false

var current_panel_index:  int   = -1
var current_game_index:   int   = -1
var current_coins_reward: int   = 0     # passed from ChapterData segment def
var last_segment_time:    float = 0.0   # seconds spent in the level (speedrun achievement)

var _segment_start_time:  float = 0.0   # internal


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color(0, 0, 0, 0)
	transition_overlay.anchor_right = 1.0
	transition_overlay.anchor_bottom = 1.0
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.z_index = 100
	canvas.add_child(transition_overlay)

func start_game_segment(scene_path: String, reader: Node) -> void:
	if is_transitioning or is_segment_active:
		push_warning("TransitionManager: a gameplay segment is already active.")
		return
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("TransitionManager: gameplay segment scene is unavailable: %s" % scene_path)
		if reader and reader.has_method("restore_scroll_only"):
			reader.restore_scroll_only()
		return

	is_transitioning = true
	reader_ref = reader
	
	await fade_to_black()
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	await get_tree().create_timer(0.3).timeout
	
	var game_scene := ResourceLoader.load(scene_path) as PackedScene
	if game_scene == null:
		await _abort_segment_launch("scene did not load: %s" % scene_path)
		return
	game_instance = game_scene.instantiate()
	if game_instance == null or not game_instance.has_signal("level_completed"):
		await _abort_segment_launch("root must expose level_completed(success: bool): %s" % scene_path)
		return
	
	# Add to scene FIRST
	get_tree().root.add_child(game_instance)
	
	# Connect AFTER it's in the scene tree
	await get_tree().process_frame
	game_instance.level_completed.connect(_on_level_completed)
	
	if reader_ref and is_instance_valid(reader_ref):
		reader_ref.hide()
	_segment_start_time = Time.get_ticks_msec() / 1000.0
	is_segment_active = true
	await fade_to_clear()
	is_transitioning = false


func _abort_segment_launch(reason: String) -> void:
	push_error("TransitionManager: could not start gameplay segment: %s" % reason)
	if game_instance and is_instance_valid(game_instance):
		game_instance.queue_free()
		game_instance = null
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	if reader_ref and is_instance_valid(reader_ref) and reader_ref.has_method("restore_scroll_only"):
		reader_ref.restore_scroll_only()
	await fade_to_clear()
	is_transitioning = false

func _on_level_completed(success: bool) -> void:
	if is_transitioning or not is_segment_active:
		return
	is_transitioning = true
	last_segment_time = (Time.get_ticks_msec() / 1000.0) - _segment_start_time
	await end_game_segment(success)

func end_game_segment(success: bool) -> void:
	await fade_to_black()
	
	if game_instance and is_instance_valid(game_instance):
		game_instance.queue_free()
		game_instance = null
	
	# LevelController scenes may pause on completion; the reader must resume.
	get_tree().paused = false
	await get_tree().create_timer(0.2).timeout
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	await get_tree().create_timer(0.3).timeout
	
	if reader_ref and is_instance_valid(reader_ref):
		reader_ref.show()
		if success:
			# Player reached exit — mark complete, scroll to next panel
			reader_ref.advance_past_playable()
		else:
			# Player pressed back — just restore scroll, keep trigger
			reader_ref.restore_scroll_only()
	else:
		push_error("reader_ref is null!")
	
	await fade_to_clear()
	is_segment_active = false
	is_transitioning = false

func fade_to_black() -> void:
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(transition_overlay, "color", Color(0, 0, 0, 1), 0.5)
	await tween.finished

func fade_to_clear() -> void:
	var tween = create_tween()
	tween.tween_property(transition_overlay, "color", Color(0, 0, 0, 0), 0.5)
	await tween.finished
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
