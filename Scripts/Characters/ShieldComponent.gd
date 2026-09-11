extends Node
class_name ShieldComponent

signal shield_changed(hits_remaining: int)
signal shield_broken

@export var max_hits: int = 0

var hits_remaining: int = 0


func grant() -> void:
	hits_remaining = max_hits
	shield_changed.emit(hits_remaining)


func absorb_hit() -> bool:
	if hits_remaining <= 0:
		return false
	hits_remaining -= 1
	shield_changed.emit(hits_remaining)
	if hits_remaining == 0:
		shield_broken.emit()
	return true
