extends "res://Scenes/Levels/level_8.gd"
## Level 16 - "Welcome to Sand Land... and it does NOT look friendly."
## Chapter 8, Segment 1 from the PDF: desert biome intro.
## Use sand/quicksand hazards and broken ruins as editable map pieces.


func _ready() -> void:
	intro_text = "Welcome to Sand Land... and it does NOT look friendly."
	objective_text = "Explore the ruined desert town and collect 30 coins."
	clear_text = "Sand Land explored!"
	auto_scroll_speed = 0.0
	required_coins = 30
	auto_complete_on_coins = true
	super._ready()
