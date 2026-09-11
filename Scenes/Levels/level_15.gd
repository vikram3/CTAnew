extends "res://Scenes/Levels/level_8.gd"
## Level 15 - "The ship is going DOWN - hold on and get to safety!"
## Chapter 7, Segment 2 from the PDF: tilting ship survival puzzle.
## Arrange platforms upward and use moving hazards/crates to sell the tilt.


func _ready() -> void:
	intro_text = "The ship is going DOWN - hold on and get to safety!"
	objective_text = "Climb to the upper safety zone while the ship falls apart."
	clear_text = "Reached the safety zone!"
	auto_scroll_speed = 0.0
	fall_y_threshold = 2200.0
	super._ready()
