extends Control

# ─────────────────────────────────────────────
#  NODE REFERENCES
# ─────────────────────────────────────────────
@onready var scroll_container   = $ScrollContainer
@onready var center_container   = $ScrollContainer/CenterContainer
@onready var panel_container    = $ScrollContainer/CenterContainer/PanelContainer
@onready var chapter_label      = $CanvasLayer/TopBar/HBoxContainer/ChapterLabel
@onready var prev_btn           = $CanvasLayer/TopBar/HBoxContainer/PrevButton
@onready var next_btn           = $CanvasLayer/TopBar/HBoxContainer/NextButton
@onready var home_btn           = $CanvasLayer/TopBar/HBoxContainer/HomeButton
@onready var chapter_select_btn = $CanvasLayer/TopBar/HBoxContainer/ChapterSelectButton
@onready var coin_label         = $CoinDisplay/CoinLabel
@onready var zoom_in_btn        = $CanvasLayer/ZoomBar/ZoomIn
@onready var zoom_out_btn       = $CanvasLayer/ZoomBar/ZoomOut
@onready var zoom_reset_btn     = $CanvasLayer/ZoomBar/ZoomReset
@onready var zoom_label         = $CanvasLayer/ZoomBar/ZoomLabel
@onready var scroll_indicator   = $CanvasLayer/ScrollIndicator

# ─────────────────────────────────────────────
#  TUNABLE CONSTANTS
# ─────────────────────────────────────────────
var   BASE_PANEL_WIDTH: float = 720.0
const MIN_ZOOM           = 0.5
const MAX_ZOOM           = 2.5
const ZOOM_STEP          = 0.15
const SMOOTH_SCROLL_TIME = 0.4
const AUTO_SAVE_INTERVAL = 2.0
const UI_HIDE_DELAY      = 3.5

# ─────────────────────────────────────────────
#  STATE
# ─────────────────────────────────────────────
var chapter_panels: Array        = []
var current_chapter: int         = 1
var total_games: int             = 0
var saved_scroll_position: float = 0.0

var _zoom: float         = 1.0
var _zoom_busy: bool     = false
var _load_queue: Array   = []
var _is_loading: bool    = false
var _save_timer: float   = 0.0
var _resize_timer: float = 0.0
var _resize_pending: bool = false
var _scroll_tween: Tween = null
var _ui_visible: bool    = true
var _ui_hide_timer: float = UI_HIDE_DELAY

# ─────────────────────────────────────────────
#  PINCH-TO-ZOOM STATE
# ─────────────────────────────────────────────
var _touch_points: Dictionary = {}   # finger index → position
var _pinch_initial_distance: float = 0.0
var _pinch_initial_zoom: float     = 1.0
var _is_pinching: bool             = false

# Tap detection (single tap = toggle UI)
var _tap_start_pos: Vector2  = Vector2.ZERO
var _tap_start_time: float   = 0.0
const TAP_MAX_DISTANCE       = 20.0   # px — more than this = scroll, not tap
const TAP_MAX_DURATION       = 0.25   # seconds


# ════════════════════════════════════════════
#  READY
# ════════════════════════════════════════════
func _ready():
	
	if DisplayServer.is_touchscreen_available():
		BASE_PANEL_WIDTH = get_viewport().get_visible_rect().size.x
	else:
		BASE_PANEL_WIDTH = get_viewport().get_visible_rect().size.x
		_zoom = 0.5  # ← PC starts at 50%

	var saved_zoom = GameData.get_chapter_zoom(current_chapter)
	if saved_zoom > 0.0:
		_zoom = saved_zoom
	_refresh_zoom_ui()

	build_chapter()

	BASE_PANEL_WIDTH = get_viewport().get_visible_rect().size.x

	current_chapter = GameData.data.current_chapter
	chapter_panels  = ChapterData.get_chapter(current_chapter)
	total_games     = ChapterData.get_total_games(current_chapter)

	_setup_scroll_container()
	_setup_navigation()
	_setup_zoom_bar()
	_setup_scroll_indicator()

	build_chapter()

	await _wait_for_load_complete()

	var saved = GameData.get_chapter_progress(current_chapter)
	if saved > 0:
		scroll_container.scroll_vertical = int(saved)

	get_viewport().size_changed.connect(_on_viewport_size_changed)


# ════════════════════════════════════════════
#  SETUP
# ════════════════════════════════════════════
func _wait_for_load_complete():
	while _is_loading or not _load_queue.is_empty():
		await get_tree().process_frame
	for _i in 3:
		await get_tree().process_frame
	await get_tree().process_frame  # ← was queue_sort()
	await get_tree().process_frame


func _wait_for_layout():
	for _i in 3:
		await get_tree().process_frame


func _setup_scroll_container():
	scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	scroll_container.offset_top = $CanvasLayer/TopBar.size.y
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO

	center_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_container.alignment             = BoxContainer.ALIGNMENT_CENTER

	panel_container.size_flags_horizontal  = Control.SIZE_SHRINK_CENTER
	panel_container.add_theme_constant_override("separation", 0)


func _setup_navigation():
	chapter_label.text = "Chapter " + str(current_chapter)

	home_btn.text = "🏠"
	home_btn.pressed.connect(_on_home_pressed)

	chapter_select_btn.text = "📖"
	chapter_select_btn.pressed.connect(_on_chapter_select_pressed)

	prev_btn.text     = "◀"
	prev_btn.disabled = (current_chapter <= 1)
	prev_btn.pressed.connect(_on_prev_chapter)

	next_btn.text     = "▶"
	next_btn.disabled = not GameData.is_chapter_unlocked(current_chapter + 1)
	next_btn.pressed.connect(_on_next_chapter)

	coin_label.text = str(GameData.data.coins)


func _setup_zoom_bar():
	zoom_in_btn.text    = "＋"
	zoom_out_btn.text   = "－"
	zoom_reset_btn.text = "⟲"
	zoom_in_btn.pressed.connect(_zoom_in)
	zoom_out_btn.pressed.connect(_zoom_out)
	zoom_reset_btn.pressed.connect(_zoom_reset)
	_refresh_zoom_ui()


func _setup_scroll_indicator():
	scroll_indicator.min_value = 0.0
	scroll_indicator.max_value = 1.0
	scroll_indicator.value     = 0.0


# ════════════════════════════════════════════
#  PROCESS
# ════════════════════════════════════════════
func _process(delta: float):
	
	_save_timer += delta
	if _save_timer >= AUTO_SAVE_INTERVAL:
		_save_timer = 0.0
		GameData.save_chapter_progress(current_chapter, scroll_container.scroll_vertical)
		GameData.save_chapter_zoom(current_chapter, _zoom)  # ← add this
	# inside _process(delta):
	_check_overlay_visibility()
	if _resize_pending:
		_resize_timer -= delta
		if _resize_timer <= 0.0:
			_resize_pending = false
			_rebuild_for_new_size()

	_save_timer += delta
	if _save_timer >= AUTO_SAVE_INTERVAL:
		_save_timer = 0.0
		GameData.save_chapter_progress(current_chapter, scroll_container.scroll_vertical)

	_update_scroll_indicator()

	# UI auto-hide — only counts down when UI is visible
	if _ui_visible:
		_ui_hide_timer -= delta
		if _ui_hide_timer <= 0.0:
			_fade_ui(false)


func _check_overlay_visibility():
	var vp_top    = scroll_container.scroll_vertical
	var vp_bottom = vp_top + scroll_container.size.y

	for slot in panel_container.get_children():
		if not slot.name.begins_with("Slot_"):
			continue
		var trigger = slot.get_node_or_null("Playable_" + str(int(slot.name.split("_")[1]) + 1))
		if trigger == null:
			continue
		if not trigger.get_meta("auto_trigger_armed", false):
			continue

		# Global Y of the overlay strip
		var trigger_y = trigger.global_position.y
		if trigger_y < vp_bottom and (trigger_y + trigger.size.y) > vp_top:
			trigger.set_meta("auto_trigger_armed", false)
			trigger.show_prompt()   # add this method to PlayableTriggerPanel if needed

# ════════════════════════════════════════════
#  INPUT — keyboard, mouse-wheel zoom, touch
# ════════════════════════════════════════════
func _input(event: InputEvent):

	# ── Keyboard ────────────────────────────
	if event is InputEventKey and event.pressed:
		_wake_ui()
		var vp_h = scroll_container.size.y
		match event.keycode:
			KEY_DOWN, KEY_S:   smooth_scroll_to(scroll_container.scroll_vertical + 300)
			KEY_UP,   KEY_W:   smooth_scroll_to(scroll_container.scroll_vertical - 300)
			KEY_PAGEDOWN:      smooth_scroll_to(scroll_container.scroll_vertical + vp_h * 0.85)
			KEY_PAGEUP:        smooth_scroll_to(scroll_container.scroll_vertical - vp_h * 0.85)
			KEY_HOME:          smooth_scroll_to(0)
			KEY_END:           smooth_scroll_to(panel_container.size.y)
			KEY_EQUAL, KEY_KP_ADD:
				if event.ctrl_pressed: _zoom_in()
			KEY_MINUS, KEY_KP_SUBTRACT:
				if event.ctrl_pressed: _zoom_out()
			KEY_0:
				if event.ctrl_pressed: _zoom_reset()

	# ── Mouse wheel zoom (Ctrl held on PC) ──
	if event is InputEventMouseButton and event.pressed:
		if event.ctrl_pressed:
			_wake_ui()
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:   _zoom_in()
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: _zoom_out()

	# ── Touch ────────────────────────────────
	if event is InputEventScreenTouch:
		_handle_touch(event)

	if event is InputEventScreenDrag:
		_handle_drag(event)


# ════════════════════════════════════════════
#  TOUCH HANDLING  (tap + pinch)
# ════════════════════════════════════════════
func _handle_touch(event: InputEventScreenTouch):
	if event.pressed:
		_touch_points[event.index] = event.position

		if _touch_points.size() == 1:
			# Record potential tap start
			_tap_start_pos  = event.position
			_tap_start_time = Time.get_ticks_msec() / 1000.0

		elif _touch_points.size() == 2:
			# Second finger down — begin pinch
			_is_pinching            = true
			_pinch_initial_distance = _pinch_distance()
			_pinch_initial_zoom     = _zoom
			# Cancel pending tap
			_tap_start_time = -1.0

	else:
		# Finger lifted
		var lift_time = Time.get_ticks_msec() / 1000.0

		if _touch_points.size() == 1 and not _is_pinching:
			# Check if this qualifies as a tap
			var duration = lift_time - _tap_start_time
			var dist     = event.position.distance_to(_tap_start_pos)
			if duration <= TAP_MAX_DURATION and dist <= TAP_MAX_DISTANCE and _tap_start_time >= 0.0:
				_toggle_ui()

		_touch_points.erase(event.index)

		if _touch_points.size() < 2:
			_is_pinching = false


func _handle_drag(event: InputEventScreenDrag):
	_touch_points[event.index] = event.position

	if _touch_points.size() == 2 and _is_pinching:
		# Cancel any tap
		_tap_start_time = -1.0

		var current_dist = _pinch_distance()
		if _pinch_initial_distance > 0.0:
			var new_zoom = _pinch_initial_zoom * (current_dist / _pinch_initial_distance)
			new_zoom = clamp(new_zoom, MIN_ZOOM, MAX_ZOOM)
			if abs(new_zoom - _zoom) > 0.01:
				_apply_zoom_immediate(new_zoom)


func _pinch_distance() -> float:
	var keys = _touch_points.keys()
	if keys.size() < 2:
		return 0.0
	return _touch_points[keys[0]].distance_to(_touch_points[keys[1]])


# ════════════════════════════════════════════
#  UI TOGGLE / FADE
# ════════════════════════════════════════════
func _toggle_ui():
	if _ui_visible:
		_fade_ui(false)
	else:
		_wake_ui()


func _wake_ui():
	_ui_hide_timer = UI_HIDE_DELAY
	if not _ui_visible:
		_fade_ui(true)


func _fade_ui(show: bool):
	_ui_visible   = show
	var target    = 1.0 if show else 0.0
	var duration  = 0.25 if show else 0.6

	var tween = create_tween().set_parallel(true)
	tween.tween_property($CanvasLayer/TopBar,           "modulate:a", target, duration)
	tween.tween_property($CanvasLayer/ZoomBar,          "modulate:a", target, duration)
	tween.tween_property($CanvasLayer/ScrollIndicator,  "modulate:a", target, duration)
	tween.tween_property($CoinDisplay/CoinLabel,        "modulate:a", target, duration)

	# Disable button interaction while hidden so hidden bar can't be accidentally pressed
	tween.tween_callback(_sync_ui_interaction).set_delay(duration)


func _sync_ui_interaction():
	$CanvasLayer/TopBar.mouse_filter = \
		Control.MOUSE_FILTER_STOP if _ui_visible else Control.MOUSE_FILTER_IGNORE
	$CanvasLayer/ZoomBar.mouse_filter = \
		Control.MOUSE_FILTER_STOP if _ui_visible else Control.MOUSE_FILTER_IGNORE


# ════════════════════════════════════════════
#  SCROLL INDICATOR
# ════════════════════════════════════════════
func _update_scroll_indicator():
	var vbar  = scroll_container.get_v_scroll_bar()
	var range = vbar.max_value - vbar.page
	if range > 0.0:
		scroll_indicator.value = clamp(vbar.value / range, 0.0, 1.0)
	else:
		scroll_indicator.value = 0.0


# ════════════════════════════════════════════
#  ZOOM  (button-driven — smooth + scroll-preserving)
# ════════════════════════════════════════════
func _zoom_in():
	if _zoom < MAX_ZOOM - 0.001:
		_do_zoom(_zoom + ZOOM_STEP)

func _zoom_out():
	if _zoom > MIN_ZOOM + 0.001:
		_do_zoom(_zoom - ZOOM_STEP)

func _zoom_reset():
	_do_zoom(1.0)


func _do_zoom(new_zoom: float):
	if _zoom_busy:
		return
	_zoom_busy = true

	new_zoom      = clamp(new_zoom, MIN_ZOOM, MAX_ZOOM)
	var total_h   = panel_container.size.y
	var ratio     = float(scroll_container.scroll_vertical) / max(total_h, 1.0)

	_zoom = new_zoom
	_refresh_zoom_ui()
	_resize_all_panels()

	await get_tree().process_frame
	await get_tree().process_frame
	scroll_container.scroll_vertical = int(ratio * panel_container.size.y)

	_zoom_busy = false


# Pinch zoom — applied every drag event, no async needed
func _apply_zoom_immediate(new_zoom: float):
	var total_h = panel_container.size.y
	var ratio   = float(scroll_container.scroll_vertical) / max(total_h, 1.0)

	_zoom = new_zoom
	_refresh_zoom_ui()
	_resize_all_panels()

	# Restore proportional scroll position after one layout frame
	await get_tree().process_frame
	scroll_container.scroll_vertical = int(ratio * panel_container.size.y)


func _refresh_zoom_ui():
	zoom_label.text       = str(int(round(_zoom * 100))) + "%"
	zoom_in_btn.disabled  = (_zoom >= MAX_ZOOM - 0.001)
	zoom_out_btn.disabled = (_zoom <= MIN_ZOOM + 0.001)


func _panel_width() -> float:
	return BASE_PANEL_WIDTH * _zoom


func _resize_all_panels():
	var pw = _panel_width()
	for child in panel_container.get_children():
		if child.name.begins_with("Slot_"):
			for sub in child.get_children():
				if sub is TextureRect and sub.texture != null:
					var aspect = float(sub.texture.get_height()) / float(sub.texture.get_width())
					var h = pw * aspect
					sub.custom_minimum_size = Vector2(pw, h)
					sub.size                = Vector2(pw, h)
					child.custom_minimum_size = Vector2(pw, h)
					child.size                = Vector2(pw, h)
				elif sub.name.begins_with("Playable_"):
					sub.offset_top    = -220.0
					sub.offset_bottom = 0.0
					if sub.has_method("set_width"):
						sub.set_width(pw)
		elif child is TextureRect:
			if child.texture != null:
				var aspect = float(child.texture.get_height()) / float(child.texture.get_width())
				child.custom_minimum_size = Vector2(pw, pw * aspect)
			else:
				child.custom_minimum_size = Vector2(pw, pw * 1.45)
		else:
			if child.has_method("set_width"):
				child.set_width(pw)
			child.custom_minimum_size.x = pw
	panel_container.queue_sort()


# ════════════════════════════════════════════
#  VIEWPORT RESIZE / ROTATION
# ════════════════════════════════════════════
func _on_viewport_size_changed():
	BASE_PANEL_WIDTH = get_viewport().get_visible_rect().size.x
	_resize_pending  = true
	_resize_timer    = 0.25


func _rebuild_for_new_size():
	var total_h = panel_container.size.y
	var ratio   = float(scroll_container.scroll_vertical) / max(total_h, 1.0)

	build_chapter()

	for _i in 4:
		await get_tree().process_frame
	panel_container.queue_sort()
	await get_tree().process_frame

	scroll_container.scroll_vertical = int(ratio * panel_container.size.y)


# ════════════════════════════════════════════
#  BUILD CHAPTER
# ════════════════════════════════════════════
func build_chapter():
	_load_queue.clear()
	_is_loading = false

	for child in panel_container.get_children():
		child.queue_free()

	var i = 0
	while i < chapter_panels.size():
		var entry = chapter_panels[i]

		if entry.type == ChapterData.PanelType.STATIC:
			var next_entry = chapter_panels[i + 1] if i + 1 < chapter_panels.size() else null
			if next_entry != null and next_entry.type == ChapterData.PanelType.PLAYABLE:
				_add_panel_with_overlay(entry, i, next_entry, i + 1)
				i += 2
			else:
				_add_static_panel(entry, i)
				i += 1
		else:
			_add_playable_trigger_panel(entry, i)
			i += 1

func _add_panel_with_overlay(
		static_entry: ChapterData.PanelEntry, static_index: int,
		play_entry:   ChapterData.PanelEntry, play_index:   int):

	var pw = _panel_width()

	# Control wrapper — VBoxContainer treats this as one slot
	var wrapper = Control.new()
	wrapper.name                  = "Slot_" + str(static_index)
	wrapper.custom_minimum_size   = Vector2(pw, pw * 1.45)
	wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel_container.add_child(wrapper)

# Static image — same sizing as _add_static_panel
	var rect = TextureRect.new()
	rect.name                  = "Panel_" + str(static_index)
	rect.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.expand_mode           = TextureRect.EXPAND_IGNORE_SIZE
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rect.custom_minimum_size   = Vector2(pw, pw * 1.45)  # placeholder until texture loads
	rect.set_meta("image_path", static_entry.image_path)
	wrapper.add_child(rect)

	if static_entry.image_path != "" and ResourceLoader.exists(static_entry.image_path):
		_load_queue.append({"rect": rect, "path": static_entry.image_path, "wrapper": wrapper})
		if not _is_loading:
			_process_load_queue()
	else:
		push_error("Image not found: " + static_entry.image_path)

	# Playable trigger — anchored to bottom of wrapper
	var already_done = GameData.is_game_completed(current_chapter, play_entry.game_index)
	var trigger = preload("res://Scenes/UI/PlayableTriggerPanel.tscn").instantiate()
	trigger.name          = "Playable_" + str(play_index)
	trigger.anchor_left   = 0.0
	trigger.anchor_right  = 1.0
	trigger.anchor_top    = 1.0
	trigger.anchor_bottom = 1.0
	trigger.offset_top    = -220.0   # matches PlayableTriggerPanel height
	trigger.offset_bottom = 0.0
	wrapper.add_child(trigger)
	trigger.setup(play_entry.transition_text, pw)

	if already_done:
		trigger.set_play_again_mode()

	trigger.play_pressed.connect(_on_play_pressed.bind(play_entry, play_index))

func _add_static_panel(entry: ChapterData.PanelEntry, index: int):
	var pw   = _panel_width()
	var rect = TextureRect.new()
	rect.name                  = "Panel_" + str(index)
	rect.custom_minimum_size   = Vector2(pw, pw * 1.45)
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rect.set_meta("image_path", entry.image_path)
	panel_container.add_child(rect)

	if entry.image_path == "" or not ResourceLoader.exists(entry.image_path):
		push_error("Image not found: " + entry.image_path)
		return

	_load_queue.append({"rect": rect, "path": entry.image_path})
	if not _is_loading:
		_process_load_queue()


func _add_playable_trigger_panel(entry: ChapterData.PanelEntry, index: int):
	var already_done = GameData.is_game_completed(current_chapter, entry.game_index)

	var trigger = preload("res://Scenes/UI/PlayableTriggerPanel.tscn").instantiate()
	trigger.name                  = "Playable_" + str(index)
	trigger.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	trigger.custom_minimum_size.x = _panel_width()
	panel_container.add_child(trigger)
	trigger.setup(entry.transition_text)

	if already_done:
		trigger.set_play_again_mode()

	trigger.play_pressed.connect(_on_play_pressed.bind(entry, index))


# ════════════════════════════════════════════
#  ASYNC IMAGE LOADING
# ════════════════════════════════════════════
func _process_load_queue():
	if _load_queue.is_empty():
		_is_loading = false
		return

	_is_loading       = true
	var item          = _load_queue.pop_front()
	var rect: TextureRect = item["rect"]
	var path: String      = item["path"]

	ResourceLoader.load_threaded_request(path, "Texture2D")

	while true:
		var status = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		elif status == ResourceLoader.THREAD_LOAD_FAILED \
		  or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Failed to load image: " + path)
			_process_load_queue()
			return

	var texture = ResourceLoader.load_threaded_get(path)

	if is_instance_valid(rect):
		_apply_texture(rect, texture)

	_process_load_queue()

func _apply_texture(rect: TextureRect, texture: Texture2D):
	if texture == null or not is_instance_valid(rect):
		return
	var pw     = _panel_width()
	var aspect = float(texture.get_height()) / float(texture.get_width())
	var h      = pw * aspect

	rect.texture               = texture
	rect.stretch_mode          = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.expand_mode           = TextureRect.EXPAND_IGNORE_SIZE
	rect.size                  = Vector2(pw, h)
	rect.custom_minimum_size   = Vector2(pw, h)
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var parent = rect.get_parent()
	if parent != null and parent.name.begins_with("Slot_"):
		# Wrapper must exactly match the image size
		parent.custom_minimum_size = Vector2(pw, h)
		parent.size                = Vector2(pw, h)
		# Trigger sits at the bottom of the image, 220px tall
		for child in parent.get_children():
			if child.name.begins_with("Playable_"):
				child.offset_top    = -220.0
				child.offset_bottom = 0.0

# ════════════════════════════════════════════
#  SMOOTH SCROLL
# ════════════════════════════════════════════
func smooth_scroll_to(target_y: float):
	target_y = clamp(target_y, 0.0, panel_container.size.y)
	if _scroll_tween:
		_scroll_tween.kill()
	_scroll_tween = create_tween()
	_scroll_tween.set_ease(Tween.EASE_OUT)
	_scroll_tween.set_trans(Tween.TRANS_QUART)
	_scroll_tween.tween_property(
		scroll_container.get_v_scroll_bar(), "value", target_y, SMOOTH_SCROLL_TIME
	)


# ════════════════════════════════════════════
#  GAME SEGMENT FLOW
# ════════════════════════════════════════════
func _on_play_pressed(entry: ChapterData.PanelEntry, panel_index: int):
	if not SceneManager.is_gameplay_segment_available(entry.playable_scene):
		push_error("WebtoonReader: gameplay segment is unavailable: %s" % entry.playable_scene)
		return

	saved_scroll_position = scroll_container.scroll_vertical
	GameData.save_chapter_progress(current_chapter, saved_scroll_position)
	GameData.record_segment_played(current_chapter, entry.game_index)
	AchievementManager.on_segment_played(current_chapter, entry.game_index)

	TransitionManager.current_panel_index   = panel_index
	TransitionManager.current_game_index    = entry.game_index
	TransitionManager.current_coins_reward  = entry.coins_reward
	SceneManager.start_gameplay_segment(entry.playable_scene, self)


func restore_scroll_only():
	await _wait_for_layout()
	scroll_container.scroll_vertical = int(saved_scroll_position)


func advance_past_playable():
	var panel_index  = TransitionManager.current_panel_index
	var game_index   = TransitionManager.current_game_index
	var coins_reward = TransitionManager.current_coins_reward
	var time_taken   = TransitionManager.last_segment_time

	var was_chapter_done = GameData.is_chapter_fully_completed(current_chapter)
	var first_time_game  = not GameData.is_game_completed(current_chapter, game_index)

	var coins_awarded = GameData.record_segment_completed(current_chapter, game_index, coins_reward)

	if coins_awarded > 0:
		_show_segment_banner(current_chapter, game_index, coins_awarded)
		AchievementManager.on_coins_changed()

	coin_label.text = str(GameData.data.coins)

	if first_time_game:
		AchievementManager.on_segment_completed(current_chapter, game_index, time_taken)

# Replace the child search loop with:
	for slot in panel_container.get_children():
		var node: Node = null
		if slot.name.begins_with("Slot_"):
			node = slot.get_node_or_null("Playable_" + str(panel_index))
		elif slot.name == "Playable_" + str(panel_index):
			node = slot
		if node != null and node.has_method("set_play_again_mode"):
			node.set_play_again_mode()
			break

	if GameData.check_chapter_complete(current_chapter, total_games):
		if not was_chapter_done:
			_on_chapter_fully_completed()

	await _wait_for_layout()
	_scroll_to_next_panel_after(panel_index)


func _scroll_to_next_panel_after(panel_index: int):
	for child in panel_container.get_children():
		if child.name.begins_with("Panel_"):
			var idx = int(child.name.split("_")[1])
			if idx > panel_index and child.visible:
				smooth_scroll_to(child.global_position.y)
				GameData.save_chapter_progress(current_chapter, child.global_position.y)
				return


# ════════════════════════════════════════════
#  CHAPTER COMPLETION
# ════════════════════════════════════════════
func _on_chapter_fully_completed():
	GameData.unlock_chapter(current_chapter + 1)
	next_btn.disabled = false


func _show_segment_banner(chapter: int, game_index: int, coins_awarded: int):
	var defs = ChapterData.get_playable_definitions(chapter)
	var segment_name = "Game %d" % (game_index + 1)
	for d in defs:
		if d.game_index == game_index:
			segment_name = d.text
			break
	_show_banner("✅  %s\n+%d 🪙 coins earned!" % [segment_name, coins_awarded], 22, 2.5)


func _show_completion_banner():
	pass


func _show_banner(msg: String, font_size: int, hold_sec: float):
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	canvas.add_child(panel)

	var mg = MarginContainer.new()
	mg.add_theme_constant_override("margin_left",   20)
	mg.add_theme_constant_override("margin_right",  20)
	mg.add_theme_constant_override("margin_top",    12)
	mg.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(mg)

	var label = Label.new()
	label.text = msg
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mg.add_child(label)

	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	tween.tween_interval(hold_sec)
	tween.tween_property(panel, "modulate:a", 0.0, 0.45)
	await tween.finished
	canvas.queue_free()



func save_progress():
	GameData.save_chapter_progress(current_chapter, scroll_container.scroll_vertical)
	GameData.save_chapter_zoom(current_chapter, _zoom)  # ← add this

func _on_home_pressed():
	save_progress(); SceneManager.go_to_title()

func _on_chapter_select_pressed():
	save_progress(); SceneManager.go_to_chapter_select()

func _on_prev_chapter():
	if current_chapter > 1:
		save_progress(); SceneManager.go_to_chapter(current_chapter - 1)

func _on_next_chapter():
	var next = current_chapter + 1
	if GameData.is_chapter_unlocked(next):
		save_progress(); SceneManager.go_to_chapter(next)
