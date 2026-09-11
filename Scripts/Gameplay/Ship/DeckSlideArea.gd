extends Area2D
class_name DeckSlideArea

@export var slide_direction: Vector2 = Vector2.RIGHT
@export var slide_strength: float = 180.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("apply_force"):
			body.apply_force(slide_direction.normalized(), slide_strength)


func _on_body_entered(_body: Node2D) -> void:
	pass
