extends "res://Scenes/Levels/level_8.gd"
## Level 14 - "Alex won! Now the coins are flowing - grab what you can!"
## Chapter 7, Segment 1 from the PDF: celebration coin rush.
## This is intentionally low-stakes: coins, crowd energy, and no serious
## enemies unless you add small optional hazards.


func _ready() -> void:
	intro_text = "Alex won! Now the coins are flowing - grab what you can!"
	objective_text = "Collect 40 celebration coins from the ship deck."
	clear_text = "Celebration haul complete!"
	auto_scroll_speed = 0.0
	required_coins = 40
	auto_complete_on_coins = true
	super._ready()
