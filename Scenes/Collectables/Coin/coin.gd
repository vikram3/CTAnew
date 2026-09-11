extends Area2D
@export var anim:AnimationPlayer

func _ready() -> void:
	# Guard against a missing anim reference: if `anim.play(...)` threw a
	# null-reference error here, it used to stop _ready() before the
	# connect() call below ever ran — silently making that coin permanently
	# uncollectable. Guarding it means a missing anim only costs the visual
	# spin, never collection itself.
	if anim:
		anim.play("animated")
	connect("body_entered", on_player_entered)

func on_player_entered(body: Node2D) -> void:
	# Only the actual player collects coins — `body is CharacterBody2D`
	# used to also match Skull enemies (they're CharacterBody2D too), so a
	# wandering/chasing enemy could eat a coin before the player got there.
	if not body.is_in_group("player"):
		return

	CollectedItems.coins_amount += 1
	CollectedItems.emit_signal("coins_collected")
	queue_free()
