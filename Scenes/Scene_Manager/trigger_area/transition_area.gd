extends Area2D

@export_file("*.tscn") var target_scene
@export var target_spawn_id := "start"

signal level_completed(success: bool)


#func _ready():
	#body_entered.connect(_on_body_entered)
#
#func _on_body_entered(body):
	#if not body.is_in_group("player"):
		#return
#
	#var loader := get_tree().get_first_node_in_group("scene_loader")
	#if loader:
		#loader.load_level(target_scene, target_spawn_id)


# Call this when player reaches the exit/goal:
func _on_goal_reached():
	emit_signal("level_completed", true)

# Call this on game over or skip button:
func _on_game_over():
	emit_signal("level_completed", false)
