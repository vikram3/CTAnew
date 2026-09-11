extends "res://Scenes/Levels/level_8.gd"
## Level 17 - "I signed WHAT?! Gotta do something - find those coins first!"
## Chapter 8, Segment 2 from the PDF: frantic contract panic.
## Fast pacing, quicksand, traps, and the mayor's coin bag at the end.


func _ready() -> void:
	intro_text = "I signed WHAT?! Gotta do something - find those coins first!"
	objective_text = "Collect 25 coins and reach the mayor's coin bag before time runs out."
	clear_text = "Reached the coin bag!"
	auto_scroll_speed = 0.0
	required_coins = 25
	survive_time = 45.0
	timer_can_win = false
	super._ready()
