extends Node2D
## Level 5 — "She's holding her own... but Big Boss has one more trick!"
## Side-corridor defense: CT fights off waves of Skull reinforcements trying
## to reach the main arena while Pink Girl vs Big Boss plays out in the
## background. 3 escalating waves; win when all waves are cleared.
##
## SETUP NOTES
## 1. Enemy scenes for each wave are spawned at runtime (unlike Coin/most
##    other levels' "paint it in the editor" approach) specifically so wave
##    size/difficulty can escalate without hand-placing three full sets of
##    enemies. Give this controller a `skull_scene` (a PackedScene whose
##    root uses enemy.gd with top_down_mode = false) and a handful of
##    Marker2D spawn points along the corridor.
## 2. `arena_entrance` is an optional Area2D placed at the far end of the
##    corridor (the point a Skull reaching it = "got through"). If a Skull's
##    CharacterBody2D enters it, that counts as a breach. Leave it unassigned
##    if you don't want breach tracking at all.
## 3. Background fight (Pink Girl vs Big Boss) is just whatever
##    AnimationPlayer/timeline you're already driving elsewhere in the scene
##    — this script doesn't touch it, it only reacts to `player_agency_hint`
##    text swaps and level completion.

signal level_completed(success: bool)

@export_group("Core Nodes")
@export var player: Player
@export var hud: Control
@export var game_over_panel: Control
@export var win_panel: Control

@export_group("Spawn Points")
@export var player_start: Marker2D
## Where Skulls spawn in. Enemies pick from these in order (looping) as each
## wave spawns — spread a few along the corridor for variety.
@export var wave_spawn_points: Array[Marker2D] = []

@export_group("Waves")
## Scene root must use enemy.gd with top_down_mode = false (platformer Skull).
@export var skull_scene: PackedScene
## Enemy count per wave, in order — escalating by default (3 waves).
@export var wave_sizes: Array[int] = [3, 4, 5]
## Delay between each individual enemy spawn within a wave (staggered, not
## all at once).
@export var spawn_stagger_time: float = 0.6
## Pause between a wave being fully cleared and the next wave starting.
@export var inter_wave_delay: float = 2.0

@export_group("Arena Breach (optional)")
## Area2D at the far end of the corridor. A Skull entering it counts as a
## breach. Leave unassigned to disable breach tracking entirely.
@export var arena_entrance: Area2D
## If >= 0, the level fails once this many Skulls have breached. Leave at -1
## (default) to only track/display breaches without ever failing the level
## because of them — per the design doc, the stated win condition is
## clearing all waves, not a hard breach limit.
@export var max_allowed_breaches: int = -1

@export_group("Objective Text")
@export var wave_intro_text: String = "Skulls incoming — hold the line!"
@export var wave_cleared_text: String = "Wave cleared!"
@export var breach_text: String = "One got through!"
@export var all_waves_cleared_text: String = "Reinforcements stopped!"
@export var toast_duration: float = 1.2

var _status_label: Label
var _wave_label: Label
var _breach_label: Label

var _current_wave_index: int = -1
var _alive_in_wave: int = 0
var _breach_count: int = 0
var _level_finished: bool = false
var _next_spawn_point_index: int = 0
var _toast_timer: Timer


func _ready() -> void:
	_wire_player()
	_wire_hud()
	_wire_panels()
	_wire_arena_entrance()

	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	add_child(_toast_timer)
	_toast_timer.timeout.connect(_restore_wave_text)

	_start_wave(0)


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
	_wave_label = hud.get_node_or_null("WaveLabel") as Label
	_breach_label = hud.get_node_or_null("BreachLabel") as Label
	_update_hud()


func _wire_panels() -> void:
	if game_over_panel:
		game_over_panel.hide()
		game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	if win_panel:
		win_panel.hide()
		win_panel.process_mode = Node.PROCESS_MODE_ALWAYS


func _wire_arena_entrance() -> void:
	if arena_entrance and arena_entrance.has_signal("body_entered"):
		arena_entrance.body_entered.connect(_on_arena_entrance_body_entered)


# ---------------------------------------------------------------------------
# Wave spawning
# ---------------------------------------------------------------------------
func _start_wave(index: int) -> void:
	if _level_finished:
		return

	if index >= wave_sizes.size():
		_finish(true, all_waves_cleared_text)
		return

	_current_wave_index = index
	_alive_in_wave = 0

	if _status_label:
		_status_label.text = wave_intro_text
	_update_hud()

	var count: int = wave_sizes[index]
	for i in range(count):
		_spawn_skull()
		if i < count - 1:
			await get_tree().create_timer(spawn_stagger_time).timeout
		if _level_finished:
			return  # level ended mid-spawn (e.g. player died) — stop spawning more


func _spawn_skull() -> void:
	if not skull_scene:
		push_warning("Level5: no skull_scene assigned — cannot spawn wave enemies.")
		return
	if wave_spawn_points.is_empty():
		push_warning("Level5: no wave_spawn_points assigned — cannot place spawned enemies.")
		return

	var skull: Node = skull_scene.instantiate()
	add_child(skull)

	var spawn_point: Marker2D = wave_spawn_points[_next_spawn_point_index % wave_spawn_points.size()]
	_next_spawn_point_index += 1
	if skull is Node2D:
		(skull as Node2D).global_position = spawn_point.global_position

	skull.add_to_group("skull_enemies")
	_alive_in_wave += 1

	if skull.has_signal("defeated"):
		_connect_defeated(skull)


## Split into its own function only so the lambda capture below reads
## cleanly — connects with a one-shot-style guard so a given skull node
## can't double-count if defeated fires more than once for any reason.
func _connect_defeated(skull: Node) -> void:
	skull.defeated.connect(func():
		_on_skull_defeated(skull)
	, CONNECT_ONE_SHOT)


func _on_skull_defeated(skull: Node) -> void:
	if is_instance_valid(skull):
		_remove_active_skull(skull)


func _on_arena_entrance_body_entered(body: Node2D) -> void:
	if _level_finished:
		return
	if not body.is_in_group("skull_enemies"):
		return

	_breach_count += 1
	_remove_active_skull(body)

	if _status_label:
		_status_label.text = breach_text
	if _toast_timer:
		_toast_timer.start(toast_duration)
	_update_hud()

	if max_allowed_breaches >= 0 and _breach_count > max_allowed_breaches:
		_finish(false, "")
		return

	if is_instance_valid(body):
		body.queue_free()


## Shared bookkeeping for "this skull is no longer part of the active wave
## count," whether it died in combat or breached the arena entrance. When
## the count hits zero, either starts the next wave or ends the level.
func _remove_active_skull(_skull: Node) -> void:
	_alive_in_wave = max(_alive_in_wave - 1, 0)
	_update_hud()

	if _alive_in_wave <= 0 and not _level_finished:
		if _status_label:
			_status_label.text = wave_cleared_text
		if _toast_timer:
			_toast_timer.start(toast_duration)

		await get_tree().create_timer(inter_wave_delay).timeout
		_start_wave(_current_wave_index + 1)


func _restore_wave_text() -> void:
	if _status_label and not _level_finished:
		_status_label.text = wave_intro_text


func _update_hud() -> void:
	if _wave_label:
		var wave_display: int = _current_wave_index + 1
		_wave_label.text = "Wave %d / %d" % [wave_display, wave_sizes.size()]
	if _breach_label:
		if max_allowed_breaches >= 0:
			_breach_label.text = "Breaches: %d / %d" % [_breach_count, max_allowed_breaches]
		else:
			_breach_label.text = "Breaches: %d" % _breach_count


func _on_player_died() -> void:
	_finish(false, "")


func _finish(success: bool, message: String) -> void:
	if _level_finished:
		return
	_level_finished = true

	if _status_label and message != "":
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
