extends ObjectiveBase
class_name CoinObjective

@export var required_coins: int = 1


func activate() -> void:
	super.activate()
	if not CollectedItems.coins_collected.is_connected(_on_coins_changed):
		CollectedItems.coins_collected.connect(_on_coins_changed)
	_on_coins_changed()


func deactivate() -> void:
	if CollectedItems.coins_collected.is_connected(_on_coins_changed):
		CollectedItems.coins_collected.disconnect(_on_coins_changed)
	super.deactivate()


func _on_coins_changed() -> void:
	var current: int = CollectedItems.coins_amount
	report_progress(current, required_coins)
	if current >= required_coins:
		complete()
