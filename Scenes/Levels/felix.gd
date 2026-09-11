extends CharacterBody2D
## Felix ("Flex") — Level 7's companion. Purely cosmetic/atmospheric: follows
## CT through the forest and occasionally pops up an idle comment bubble.
## No combat, no interaction, can't be hurt, can't hurt anything, can't be
## collided with — he's set up to just ghost through the player and enemies
## so he never gets in the way of platforming or fights.

@export_group("Follow Behavior")
## Horizontal distance Felix tries to keep behind the player (in the
## direction the player is facing/moving), so he trails rather than
## overlapping.
@export var follow_distance: float = 48.0
## How fast Felix closes horizontal distance to his target follow position.
@export var follow_speed: float = 140.0
## If the gap to the player exceeds this, Felix "teleport catches up" (a
## short blink/dash) instead of visibly struggling to keep pace across a
## big level jump/gap — keeps him from looking like he's glitching out
## trying to walk across a chasm he can't actually cross.
@export var teleport_catch_up_distance: float = 420.0

@export_group("Physics")
@export var gravity: float = 900.0
@export var max_fall_speed: float = 700.0

@export_group("Idle Comments")
## Lines Felix pops up with periodically. Purely flavor text — not tied to
## any gameplay event, just ambient bonding-banter per the design doc.
@export var idle_comments: Array[String] = [
	"There's coins all through these woods, trust me.",
	"Watch your step — some of this brush hides drops.",
	"You hear that? ...probably nothing.",
	"I used to get lost out here all the time.",
	"Grab everything shiny, I'll explain later.",
]
@export var comment_interval_min: float = 8.0
@export var comment_interval_max: float = 16.0
@export var comment_display_time: float = 3.0

@export_group("Nodes")
@export var body: Node2D
@export var anim: AnimationPlayer
## A Label/RichTextLabel (in a small bubble background, however you've
## styled it) positioned above Felix's head. Hidden by default, shown only
## while a comment is on screen.
@export var comment_bubble: Control
@export var comment_label: Label

var _player: Node2D
var _facing_dir: int = 1
var _comment_timer: Timer


func _ready() -> void:
	add_to_group("companion")

	# Felix should never physically collide with anything — he's along for
	# the ride, not a physical obstacle for the player or enemies.
	collision_layer = 0
	collision_mask = 0

	if comment_bubble:
		comment_bubble.hide()

	_comment_timer = Timer.new()
	_comment_timer.one_shot = true
	add_child(_comment_timer)
	_comment_timer.timeout.connect(_show_random_comment)
	_queue_next_comment()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if not is_instance_valid(_player):
			return

	# Gravity, so Felix stays grounded on the same platforms as the player
	# instead of floating.
	if not is_on_floor():
		velocity.y += gravity * delta
		if velocity.y > max_fall_speed:
			velocity.y = max_fall_speed
	else:
		velocity.y = 0.0

	var to_player: Vector2 = _player.global_position - global_position
	if absf(to_player.x) > 1.0:
		_facing_dir = 1 if to_player.x > 0.0 else -1

	# Trail behind the player rather than standing on top of them.
	var target_x: float = _player.global_position.x - (follow_distance * _facing_dir)
	var gap: float = target_x - global_position.x

	if absf(gap) > teleport_catch_up_distance:
		# Big level gap (e.g. player crossed a chasm Felix can't traverse
		# the normal way) — blink to just behind the player instead of
		# comically trying to walk it.
		global_position = Vector2(target_x, _player.global_position.y)
		velocity = Vector2.ZERO
	else:
		velocity.x = clamp(gap, -follow_speed, follow_speed)

	move_and_slide()
	_update_animation()

	if body:
		body.scale.x = _facing_dir


func _update_animation() -> void:
	if not anim:
		return
	var moving := absf(velocity.x) > 4.0
	if not is_on_floor():
		anim.play("idle_up" if anim.has_animation("idle_up") else "idle")
	else:
		anim.play("walk" if moving and anim.has_animation("walk") else "idle")


func _queue_next_comment() -> void:
	if not _comment_timer:
		return
	_comment_timer.start(randf_range(comment_interval_min, comment_interval_max))


func _show_random_comment() -> void:
	if idle_comments.is_empty() or not comment_bubble:
		_queue_next_comment()
		return

	if comment_label:
		comment_label.text = idle_comments[randi() % idle_comments.size()]
	comment_bubble.show()

	await get_tree().create_timer(comment_display_time).timeout
	if is_instance_valid(comment_bubble):
		comment_bubble.hide()

	_queue_next_comment()
