extends Area2D
class_name MainArenaGate

@export var wave_controller: WaveController
@export var level_controller: LevelController
@export var enemy_group: StringName = &"wave_enemy"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(enemy_group):
		return
	if wave_controller:
		wave_controller.report_enemy_removed(body)
	if level_controller:
		level_controller.fail("A Skull reached the main arena.")
	body.queue_free()
