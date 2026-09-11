@tool
extends StaticBody2D
## Reusable "hideable prop" — a static obstacle with an attached hide zone.
##
## Sprite2D, CollisionShape2D, and HideZone (Area2D + CollisionShape2D) are
## already set up manually as children in the scene. This script only wires
## up the hide-zone behavior: when the player enters HideZone, they become
## hidden; when they leave, they become visible again.
##
## Requires the player to be in group "player" (already done in Player.gd)
## and to have a method set_hidden_state(bool) (already exists in Player.gd).

@onready var _hide_zone: Area2D = $HideZone


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_hide_zone.body_entered.connect(_on_hide_zone_body_entered)
	_hide_zone.body_exited.connect(_on_hide_zone_body_exited)


func _on_hide_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("set_hidden_state"):
		body.set_hidden_state(true)


func _on_hide_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("set_hidden_state"):
		body.set_hidden_state(false)
