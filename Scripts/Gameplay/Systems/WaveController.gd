extends Node
class_name WaveController

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal all_waves_completed

@export var enemy_spawner: EnemySpawner
@export var wave_sizes: Array[int] = []
@export var wave_configs: Array[WaveConfig] = []
@export var spawn_stagger_time: float = 0.5
@export var inter_wave_delay: float = 1.5
@export var start_on_ready: bool = false

var _current_wave: int = -1
var _alive_enemies: int = 0
var _finished: bool = false


func _ready() -> void:
	if start_on_ready:
		start_waves()


func start_waves() -> void:
	if _finished or _current_wave >= 0:
		return
	_start_wave(0)


func _start_wave(index: int) -> void:
	if index >= _wave_count():
		_finished = true
		all_waves_completed.emit()
		return
	_current_wave = index
	_alive_enemies = 0
	wave_started.emit(index + 1)
	var wave_config := _get_wave_config(index)
	for i in range(wave_config.enemy_count):
		var enemy := enemy_spawner.spawn_enemy() if enemy_spawner else null
		if enemy:
			_alive_enemies += 1
			if enemy.has_signal("defeated"):
				enemy.connect("defeated", _on_enemy_defeated.bind(enemy), CONNECT_ONE_SHOT)
		if i < wave_config.enemy_count - 1:
			await get_tree().create_timer(wave_config.spawn_stagger_time).timeout
	if _alive_enemies == 0:
		_finish_wave()


func _on_enemy_defeated(_enemy: Node) -> void:
	_alive_enemies = max(_alive_enemies - 1, 0)
	if _alive_enemies == 0:
		_finish_wave()


func _finish_wave() -> void:
	if _finished:
		return
	wave_cleared.emit(_current_wave + 1)
	await get_tree().create_timer(_get_wave_config(_current_wave).inter_wave_delay).timeout
	_start_wave(_current_wave + 1)


func report_enemy_removed(enemy: Node) -> void:
	_on_enemy_defeated(enemy)


func _wave_count() -> int:
	return wave_configs.size() if not wave_configs.is_empty() else wave_sizes.size()


func _get_wave_config(index: int) -> WaveConfig:
	if not wave_configs.is_empty():
		return wave_configs[index]
	var fallback := WaveConfig.new()
	fallback.enemy_count = wave_sizes[index]
	fallback.spawn_stagger_time = spawn_stagger_time
	fallback.inter_wave_delay = inter_wave_delay
	return fallback
