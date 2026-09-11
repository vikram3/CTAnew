extends CharacterBody2D

# =====================================================
# ENUMS
# =====================================================
enum MoveType { STATIC, VERTICAL, HORIZONTAL }
enum PlatformBehaviour { PERMANENT, TIMED }

# =====================================================
# EXPORTS
# =====================================================
@export var move_type : MoveType = MoveType.STATIC
@export var behaviour : PlatformBehaviour = PlatformBehaviour.PERMANENT

@export var speed : float = 80.0
@export var move_limit : float = 120.0
@export var wait_time : float = 1.0
@export var disappear_time : float = 2.0

# =====================================================
# INTERNAL
# =====================================================
var start_position : Vector2
var direction : int = 1
var waiting : bool = false

@onready var direction_timer : Timer = $DirectionTimer
@onready var disappear_timer : Timer = $DisappearTimer
@onready var player_detector : Area2D = $PlayerDetector

# =====================================================
# READY
# =====================================================
func _ready():
	start_position = global_position

	direction_timer.wait_time = wait_time
	disappear_timer.wait_time = disappear_time

	direction_timer.timeout.connect(_on_direction_timeout)
	disappear_timer.timeout.connect(_on_disappear_timeout)

	player_detector.body_entered.connect(_on_body_entered)
	player_detector.body_exited.connect(_on_body_exited)

# =====================================================
# PHYSICS
# =====================================================
func _physics_process(delta):

	if move_type == MoveType.STATIC:
		velocity = Vector2.ZERO
		return

	if waiting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var move_dir := Vector2.ZERO

	match move_type:
		MoveType.VERTICAL:
			move_dir.y = direction
		MoveType.HORIZONTAL:
			move_dir.x = direction

	velocity = move_dir * speed

	# IMPORTANT: CHECK LIMIT BEFORE MOVING
	if _will_reach_limit():
		_start_wait()
		move_and_slide()
		return

	move_and_slide()

# =====================================================
# LIMIT CHECK (PRE-MOVE CHECK)
# =====================================================
func _will_reach_limit() -> bool:

	var offset := global_position - start_position

	match move_type:

		MoveType.VERTICAL:
			if direction == 1 and offset.y >= move_limit:
				global_position.y = start_position.y + move_limit
				return true

			elif direction == -1 and offset.y <= -move_limit:
				global_position.y = start_position.y - move_limit
				return true

		MoveType.HORIZONTAL:
			if direction == 1 and offset.x >= move_limit:
				global_position.x = start_position.x + move_limit
				return true

			elif direction == -1 and offset.x <= -move_limit:
				global_position.x = start_position.x - move_limit
				return true

	return false

# =====================================================
# WAIT HANDLING
# =====================================================
func _start_wait():
	if waiting:
		return

	waiting = true
	velocity = Vector2.ZERO
	direction_timer.start()

func _on_direction_timeout():
	direction *= -1
	waiting = false

# =====================================================
# TIMED PLATFORM
# =====================================================
func _on_disappear_timeout():
	# FUTURE ANIMATION HERE
	# $AnimationPlayer.play("break")
	queue_free()

# =====================================================
# PLAYER DETECTION
# =====================================================
func _on_body_entered(body):
	if not body.is_in_group("player"):
		return

	if behaviour == PlatformBehaviour.TIMED:
		if disappear_timer.is_stopped():
			disappear_timer.start()

func _on_body_exited(body):
	if not body.is_in_group("player"):
		return
