extends "res://Scenes/Levels/level_8.gd"
## Level 13 - "Alex is on one knee... he's not done yet. Neither are we!"
## Chapter 6, Segment 2 from the PDF: crowd-area coin scramble.
## Add falling debris and heavy projectile arcs around the deck/crowd area.


func _ready() -> void:
	intro_text = "Alex is on one knee... he's not done yet. Neither are we!"
	objective_text = "Collect 20 coins while surviving the duel debris."
	clear_text = "Scramble survived!"
	auto_scroll_speed = 0.0
	required_coins = 20
	survive_time = 60.0
	timer_can_win = true
	super._ready()
