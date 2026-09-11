extends ObjectiveBase
class_name DefeatCategoryObjective

@export var required_categories: PackedStringArray = PackedStringArray()

var _defeated_categories: Dictionary = {}


func activate() -> void:
	super.activate()
	for category in required_categories:
		for enemy in get_tree().get_nodes_in_group(StringName("enemy_" + category)):
			_connect_enemy(enemy, category)
	report_progress(_defeated_categories.size(), required_categories.size())


func _connect_enemy(enemy: Node, category: StringName) -> void:
	if enemy.has_signal("defeated"):
		enemy.connect("defeated", _on_enemy_defeated.bind(category), CONNECT_ONE_SHOT)


func _on_enemy_defeated(category: StringName) -> void:
	_defeated_categories[category] = true
	report_progress(_defeated_categories.size(), required_categories.size())
	if _defeated_categories.size() >= required_categories.size():
		complete()
