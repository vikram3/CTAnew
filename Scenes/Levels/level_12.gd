extends "res://Scenes/Levels/level_8.gd"
## Level 12 - "Big Bird went straight for projectiles - dodge and get close!"
## Chapter 6, Segment 1 from the PDF: close-range boss pressure.
## Big Bird can be represented by a tuned enemy/boss placeholder until custom
## boss AI is added.


func _ready() -> void:
	intro_text = "Big Bird went straight for projectiles - dodge and get close!"
	objective_text = "Dodge Big Bird's pressure, land five close-range wins, then exit."
	clear_text = "Big Bird pressure broken!"
	auto_scroll_speed = 0.0
	required_defeats = 5
	super._ready()
