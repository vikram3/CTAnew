extends "res://Scenes/Levels/level_8.gd"
## Level 18 - "A sand wormfish?! Everyone scatter!"
## Chapter 8, Segment 3 from the PDF: pure desert chase.
## Keep combat light; the main threat should be speed, falling rocks, and
## the left-side chase pressure.


func _ready() -> void:
	intro_text = "A sand wormfish?! Everyone scatter!"
	objective_text = "Run right and survive the wormfish chase."
	clear_text = "Wormfish chase survived!"
	auto_scroll_speed = 3.2
	fall_y_threshold = 2200.0
	super._ready()
