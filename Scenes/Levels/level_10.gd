extends "res://Scenes/Levels/level_8.gd"
## Level 10 - "The Queen stepped in - but those bulls aren't done yet!"
## Chapter 5, Segment 1 from the PDF: bull stampede survival.
## Use fast ground enemies as bull stand-ins and leave room for charge lanes.


func _ready() -> void:
	intro_text = "The Queen stepped in - but those bulls aren't done yet!"
	objective_text = "Survive the bull chaos and defeat two minor bulls, then escape."
	clear_text = "Bull stampede survived!"
	auto_scroll_speed = 0.0
	required_defeats = 2
	survive_time = 70.0
	timer_can_win = true
	fall_y_threshold = 2200.0
	super._ready()
