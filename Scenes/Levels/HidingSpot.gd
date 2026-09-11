extends Area2D
class_name HidingSpot

## The prop's visual node (its Sprite2D/Node2D root) — the player's z_index gets
## set just below this so they visually disappear behind it, not just tint green.
@export var occluder: Node2D
## Optional exact spot the player dashes to when first entering hiding — usually a
## Marker2D placed slightly behind the prop's visual center. If left empty, this
## Area2D's own position is used.
@export var hide_marker: Marker2D

var _player: Player = null


func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func get_hide_position() -> Vector2:
	return hide_marker.global_position if hide_marker else global_position


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player = body as Player
	# Just marks this spot as available — actually hiding happens when the
	# player presses the hide key (see Player.gd's hide_action).
	_player.set_nearby_hide_spot(self)


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player") or body != _player:
		return
	# Walking out of the zone only clears availability now. If the player is
	# currently hidden, they stay hidden until they press the hide key —
	# no more auto-unhide just from walking out.
	_player.clear_nearby_hide_spot(self)
	_player = null
