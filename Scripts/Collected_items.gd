extends Node

signal coins_collected

var coins_amount: int = 0


func reset() -> void:
	coins_amount = 0
	coins_collected.emit()
