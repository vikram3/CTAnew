extends CharacterBody2D
## Horn — aggressive pursuer for Level 6's cliff ambush. Cannot be killed:
## it has no health hook and ignores any damage calls. Its whole threat is
## the charge attack's knockback, which (per the level design) is dangerous
## specifically because it can shove CT off a narrow cliff platform.
##
## Place directly in the editor like your other enemies. Needs a
## RayCast2D (wall_detector) pointed in its current facing direction so a
## charge stops cleanly against a wall instead of clipping through it, and a
## child Area2D (hit_box) that only actually damages/knocks back the player
## while state == CHARGING.

enum State { IDLE, TELEGRAPH, CHARGING, COOLDOWN }

@export_group("Detection")
@export var detection_range: float = 260.0
@export_flags_2d_physics var vision_wall_mask: int = 1

@export_group("Charge Attack")
## Brief pause before charging, once the player is noticed — gives the
## player a moment to react/dodge instead of an instant unavoidable hit.
@export var telegraph_time: float = 0.5
@export var charge_speed: float = 340.0
## Safety cap so a charge can't run forever if it never hits a wall or times out.
@export var charge_max_duration: float = 1.4
@export var cooldown_time: float = 0.9
@export var knockback_strength: float = 260.0

@export_group("Nodes")
@export var body: Node2D
@export var anim: AnimationPlayer
@export var wall_detector: RayCast2D
@export var hit_box: Area2D

var state: State = State.IDLE
var direction: int = 1
var _player
var _telegraph_timer: float = 0.0
var _charge_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _has_hit_this_charge: bool = false


func _ready() -> void:
	add_to_group("horn")
	if hit_box:
		hit_box.monitoring = false
		if hit_box.has_signal("body_entered"):
			hit_box.body_entered.connect(_on_hit_box_body_entered)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

	match state:
		State.IDLE:
			_process_idle()
		State.TELEGRAPH:
			_process_telegraph(delta)
		State.CHARGING:
			_process_charging(delta)
		State.COOLDOWN:
			_process_cooldown(delta)

	move_and_slide()
	if body:
		body.scale.x = direction


func _process_idle() -> void:
	velocity.x = 0.0
	if anim:
		anim.play("idle")

	if not is_instance_valid(_player):
		return

	var dist: float = global_position.distance_to(_player.global_position)
	if dist <= detection_range and _has_line_of_sight():
		direction = 1 if _player.global_position.x > global_position.x else -1
		state = State.TELEGRAPH
		_telegraph_timer = telegraph_time


func _process_telegraph(delta: float) -> void:
	velocity.x = 0.0
	if anim:
		anim.play("telegraph" if anim.has_animation("telegraph") else "idle")

	_telegraph_timer -= delta
	if _telegraph_timer <= 0.0:
		state = State.CHARGING
		_charge_timer = charge_max_duration
		_has_hit_this_charge = false
		if hit_box:
			hit_box.monitoring = true


func _process_charging(delta: float) -> void:
	velocity.x = charge_speed * direction
	if anim:
		anim.play("charge" if anim.has_animation("charge") else "walk")

	_charge_timer -= delta

	var hit_wall := wall_detector and wall_detector.is_colliding()
	if hit_wall or _charge_timer <= 0.0:
		_end_charge()


func _end_charge() -> void:
	state = State.COOLDOWN
	_cooldown_timer = cooldown_time
	if hit_box:
		hit_box.monitoring = false


func _process_cooldown(delta: float) -> void:
	velocity.x = 0.0
	if anim:
		anim.play("idle")

	_cooldown_timer -= delta
	if _cooldown_timer <= 0.0:
		state = State.IDLE


func _has_line_of_sight() -> bool:
	if not is_instance_valid(_player):
		return false
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position, _player.global_position, vision_wall_mask
	)
	query.exclude = [self]
	var result := space_state.intersect_ray(query)
	return result.is_empty()


func _on_hit_box_body_entered(hit_body: Node2D) -> void:
	if state != State.CHARGING or _has_hit_this_charge:
		return
	if not hit_body.is_in_group("player"):
		return

	_has_hit_this_charge = true

	if hit_body.has_method("apply_force"):
		var away: Vector2 = hit_body.global_position - global_position
		var dir: Vector2 = away.normalized() if away.length() > 0.0 else Vector2(direction, -0.3)
		hit_body.apply_force(dir, knockback_strength)


## Horn cannot be killed — any damage call against it is a deliberate no-op,
## not a missing feature. Kept as a real method (rather than just "no
## hurt_box at all") so a Player projectile/attack that calls
## take_level_damage on whatever it hits doesn't error out on a null method.
func take_level_damage(_damage: int, _source_position: Vector2) -> void:
	pass
