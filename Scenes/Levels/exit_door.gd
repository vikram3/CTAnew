extends Area2D
class_name ExitDoor

signal exit_reached
signal missing_coins(needed: int)

@export var required_coins: int = 18


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if CollectedItems.coins_amount >= required_coins:
		exit_reached.emit()
	else:
		missing_coins.emit(required_coins - CollectedItems.coins_amount)
