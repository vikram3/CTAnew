extends Node2D

signal level_completed(success: bool)  # ADD THIS SIGNAL

func _ready():
	$SceneLoader.load_level("res://Scenes/Environments/Small_Scenes/Sub_Scenes/sub_scene_1.tscn", "start")


# When player reaches the end goal:
func _on_goal_reached():
	emit_signal("level_completed", true)

# When player runs out of lives or wants to exit:
func _on_game_over():
	emit_signal("level_completed", false)
	
# Also add an exit/back button for players who want to skip
func _on_skip_button_pressed():
	emit_signal("level_completed", false)
