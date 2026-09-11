extends Resource
class_name LevelConfig

@export_category("Identity")
@export var level_id: StringName
@export var display_name: String

@export_category("Setup")
@export var reset_collected_items: bool = true
@export var pause_on_finish: bool = false

@export_category("Messages")
@export_multiline var success_message: String
@export_multiline var failure_message: String
