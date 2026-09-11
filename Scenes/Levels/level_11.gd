extends "res://Scenes/Levels/level_8.gd"
## Level 11 - "Alex accepted the duel... somebody's gotta warm up for him!"
## Chapter 5, Segment 2 from the PDF: ship-deck warmup.
## Collect coins and clear light enemy waves before the duel.


func _ready() -> void:
	intro_text = "Alex accepted the duel... somebody's gotta warm up for him!"
	objective_text = "Collect 25 coins and clear the ship-deck enemies."
	clear_text = "Warmup complete!"
	auto_scroll_speed = 0.0
	required_coins = 25
	required_defeats = 2
	super._ready()
