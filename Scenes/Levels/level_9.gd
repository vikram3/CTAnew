extends "res://Scenes/Levels/level_8.gd"
## Level 9 - "A Barreldugo! Flex says get close - let's try it!"
## Chapter 4, Segment 2 from the PDF: enemy-type combat tutorial.
## Tune the placed enemies as Tank, Speed, and Projectile/Barreldugo stand-ins.


func _ready() -> void:
	intro_text = "A Barreldugo! Flex says get close - let's try it!"
	objective_text = "Defeat the three enemy types, then reach the exit."
	clear_text = "Enemy types defeated!"
	auto_scroll_speed = 0.0
	required_defeats = 3
	super._ready()
