extends EnemyBase

enum states{
	IDLE,
	PATROL,
	CHASE,
	DASH_ATTACK,
	ATTACK,
	HURT,
	DIE
}

# Top-down enemy sub-state (separate from the platformer `states` above,
# since top-down mode drives its own tiny state machine in _top_down_physics)
enum TopDownState{
	PATROL,
	SUSPICIOUS,
	CHASE,
	SEARCH,
	RETURN
}

var player_in_range:bool = false
var player_in_attack_range :bool = false
var is_hurt:bool = false
var current_states:states = states.IDLE

@export var idle_walk_timer:Timer
@export var floor_detector:RayCast2D
@export var wall_detector:RayCast2D
@export var body:Node2D
@export var anim:AnimationPlayer
@export var awareness_light: PointLight2D
@export var awareness_indicator: Label

@export var patrol_speed:float = 30.0
@export var dash_speed:float = 80.0

@export var chase_speed:float = 100.0
@export var accel:float = 100.0
@export var gravity:float = 980.0

@export var top_down_mode: bool = false

@export_group("Top Down Patrol")
## Turn patrolling on/off.
@export var patrol_enabled: bool = true
## Patrol back and forth Horizontally (left/right) or Vertically (up/down).
@export_enum("Horizontal", "Vertical") var patrol_axis: String = "Horizontal"
## Total distance (px) walked along the chosen axis, centered on spawn point.
@export var patrol_distance: float = 200.0

@export_group("Top Down Combat")
## Distance at which the enemy first notices the player and starts chasing
## (assuming line-of-sight isn't blocked). This is the "detection radius" —
## separate from how close it needs to be to actually land a hit.
@export var chase_distance: float = 220.0
## Distance at which the enemy can actually land an attack on the player.
## Should be small — this is melee/contact range, not detection range.
@export var attack_distance: float = 78.0
@export var contact_damage: int = 25
## Collision layers that block line-of-sight to the player (your wall/tile layers).
## Chasing is cancelled if a wall on this mask is between the enemy and the player.
@export_flags_2d_physics var vision_wall_mask: int = 1

@export_group("Top Down Awareness")
## A short, visible hesitation before a guard commits to a chase. This gives
## the player a fair chance to break line-of-sight or use nearby cover.
@export_range(0.1, 3.0, 0.05) var suspicion_duration: float = 0.85
@export var patrol_light_color: Color = Color(1.0, 0.22, 0.16, 1.0)
@export var suspicious_light_color: Color = Color(1.0, 0.72, 0.16, 1.0)
@export var chase_light_color: Color = Color(1.0, 0.08, 0.12, 1.0)

## How long (seconds) the enemy stands still "looking around" after losing the player.
@export var search_duration: float = 1.6
## How often (seconds) it flips its look direction while searching (left/right/left...).
@export var search_look_interval: float = 0.4
## How many look-flips before giving up and going back to patrol. Leave 0 to just use search_duration.
@export var search_look_count: int = 3

## Fraction of the "attack" animation's length to wait before actually
## applying damage (i.e. when the swing "connects"). Tune this to match
## the real impact frame of your animation. 0.5 = halfway through.
@export_range(0.0, 1.0, 0.05) var attack_impact_fraction: float = 0.5

@export_group("Platformer Physical Collision")
## Player and Enemy are both CharacterBody2D. If their collision layers/masks
## overlap, Godot's physics solver treats contact between them as two solid
## bodies shoving each other apart — that's the "player throws the enemy"
## effect. Damage is meant to travel through Area2D overlap (hurt_box /
## attack detection), not solid-body collision, so by default this adds a
## physics collision exception between this enemy and the player the first
## time it finds them — they simply pass through each other, while each
## still collides with the floor/walls/everything else completely normally.
@export var platformer_disable_solid_collision_with_player: bool = true

@export_group("Platformer Detection")
## Line-of-sight is OFF by default for platformer mode: a raycast between two
## characters standing on the same flat ground grazes the top of the tile
## collision and reports "blocked" almost constantly, which is why chasing
## looked completely dead. Leave this off for simple "chase within radius"
## behavior. Turn it on only if you actually have walls you want to block
## vision around, and raise platformer_vision_height_offset so the ray
## clears the floor.
@export var platformer_use_line_of_sight: bool = false
## Raises the raycast (negative = up, since Godot's Y+ is down) off of feet
## height before checking line-of-sight, so it doesn't skim the floor tiles.
## Only used when platformer_use_line_of_sight is true.
@export var platformer_vision_height_offset: float = -16.0

var direction : int = 1
# Was typed `Player`, with `as Player` casts below. That only works if the
# node in the "player" group is literally that exact GDScript class — a
# different player character (e.g. Level 3's own script) is a different
# class, so `as Player` would silently return null even though it's the
# right node and in the right group. CharacterBody2D + duck typing
# (accessing .is_hidden / .take_level_damage() directly, without a cast)
# works with any player character that implements that small interface,
# regardless of which script/class it actually is.
# Deliberately untyped (no `: Type`). GDScript statically checks member
# access on typed variables against that exact type's known members — even
# CharacterBody2D doesn't have .is_hidden or .take_level_damage(), so typing
# this as CharacterBody2D would fail to compile the moment we access those.
# Leaving it untyped defers member lookup to runtime, which is what actual
# duck typing needs: this works with ANY node in the "player" group that
# happens to implement .is_hidden / .take_level_damage(), regardless of
# which script/class it is.
var _player
var _attack_cooldown: float = 0.0
var _is_attacking: bool = false
var _disabled_solid_collision_with_player: bool = false

var _top_down_state: TopDownState = TopDownState.PATROL
var _search_timer: float = 0.0
var _search_look_timer: float = 0.0
var _search_looks_done: int = 0
var _suspicion_timer: float = 0.0
var _last_known_player_pos: Vector2

# Spawn point patrol is centered around, captured once in _ready().
var _spawn_position: Vector2
# +1 or -1: which way along the patrol axis the enemy is currently walking.
var _patrol_dir: int = 1


func _ready() -> void:
	super._ready()
	if top_down_mode:
		_spawn_position = global_position
		if anim:
			anim.play("walk")


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		if anim and anim.current_animation != "dead":
			anim.play("dead")
		return

	if top_down_mode:
		_top_down_physics(delta)
		return

	_gravity()
	# Detection no longer depends solely on a PlayerDetector/AttackRange Area2D
	# being wired up correctly in the scene (wrong collision mask, missing
	# shape, monitoring off, etc. all silently break that). This polls
	# distance + line-of-sight every frame using the same chase_distance /
	# attack_distance / vision_wall_mask exports as top-down mode, so it works
	# even if those Area2D nodes aren't set up. If you DO have them wired
	# correctly, their signals still fire and are harmless — this just
	# overwrites player_in_range / player_in_attack_range right after with an
	# independently-verified value.
	_update_platformer_detection()
	match_state()
	state_transition()
	move_and_slide()

	# Only let the floor/wall raycasts auto-flip direction during ordinary
	# patrol/idle movement. While CHASE/ATTACK/DASH_ATTACK are driving
	# `direction` on purpose (towards the player), this used to immediately
	# stomp that back the other way the instant a wall/ledge ray tripped,
	# which is part of why chasing looked like it wasn't working.
	if current_states == states.PATROL or current_states == states.IDLE:
		if wall_detector.is_colliding() or !floor_detector.is_colliding():
			direction *= -1

	body.scale.x = direction

func _gravity():
	if !is_on_floor():
		velocity.y += gravity * get_process_delta_time()
	else:
		velocity.y = 0


## Platformer-mode detection, independent of any Area2D scene wiring.
## Sets player_in_range / player_in_attack_range from actual distance + LOS,
## reusing the same chase_distance / attack_distance / vision_wall_mask
## exports top-down mode already uses.
func _update_platformer_detection() -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if is_instance_valid(_player) and platformer_disable_solid_collision_with_player \
				and not _disabled_solid_collision_with_player:
			_disable_solid_collision_with_player()

	if not is_instance_valid(_player):
		player_in_range = false
		player_in_attack_range = false
		return

	if _player.is_hidden:
		player_in_range = false
		player_in_attack_range = false
		return

	var dist: float = global_position.distance_to(_player.global_position)
	var can_see := true
	if platformer_use_line_of_sight:
		can_see = _has_line_of_sight(platformer_vision_height_offset)

	player_in_range = dist <= chase_distance and can_see
	player_in_attack_range = dist <= attack_distance and can_see


## Adds a physics collision exception between this enemy and the player, one
## time. Unlike editing collision_layer/collision_mask, this ONLY disables
## collision between these two specific bodies — it can't accidentally break
## floor/wall detection for either of them (which is what happened when this
## was done via layer/mask bits: if the player happens to share a physics
## layer with the ground, clearing that bit from the enemy's mask also blinds
## it to the floor, and it falls straight through). Damage still works
## exactly as before via hurt_box / attack range Area2D overlap.
func _disable_solid_collision_with_player() -> void:
	if not is_instance_valid(_player):
		return
	if not (has_method("add_collision_exception_with") and _player.has_method("add_collision_exception_with")):
		return
	add_collision_exception_with(_player)
	_player.add_collision_exception_with(self)
	_disabled_solid_collision_with_player = true


func _top_down_physics(delta: float) -> void:
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")

	var player_hidden: bool = is_instance_valid(_player) and _player.is_hidden
	if player_hidden:
		player_in_range = false

	var dist_to_player := INF
	if is_instance_valid(_player):
		dist_to_player = global_position.distance_to(_player.global_position)

	var can_see_player: bool
	if _top_down_state == TopDownState.CHASE:
		# Already chasing: only stop if the player is actually hidden.
		# (No distance cutoff here — once chasing, it commits until it loses
		# sight, otherwise it'd flicker in/out right at chase_distance's edge.)
		can_see_player = is_instance_valid(_player) and not player_hidden
	else:
		# Not chasing yet: needs to be within chase_distance (the "notice"
		# radius) with line of sight to actually start.
		can_see_player = is_instance_valid(_player) and not player_hidden \
			and dist_to_player <= chase_distance and _has_line_of_sight()

	if _top_down_state == TopDownState.SUSPICIOUS:
		if not can_see_player:
			_top_down_state = TopDownState.RETURN
			_set_awareness_light(patrol_light_color)
		else:
			_process_suspicion(delta)
		return

	# A guard that catches a glimpse of CT pauses to confirm it. This is the
	# stealth telegraph: use the moment to round a corner or hide.
	if can_see_player and _top_down_state != TopDownState.CHASE:
		_start_suspicion()

	# Just lost the player (i.e. they hid) while chasing -> start searching.
	if not can_see_player and _top_down_state == TopDownState.CHASE and not _is_attacking:
		_start_searching()

	# While a swing is in progress, don't let movement/state logic override it.
	if _is_attacking:
		return

	match _top_down_state:
		TopDownState.SUSPICIOUS:
			_process_suspicion(delta)
		TopDownState.CHASE:
			_process_chase(can_see_player)
		TopDownState.SEARCH:
			_process_search(delta)
		TopDownState.RETURN:
			_process_return(delta)
		TopDownState.PATROL:
			_process_patrol(delta)

## Casts a ray from this enemy to the player. Returns false (no line of sight)
## if anything on vision_wall_mask (walls/tiles) is in the way, so the enemy
## won't blindly chase/attack straight through a wall.
## vertical_offset raises (negative) or lowers (positive) both ray endpoints
## before casting — used by platformer mode to avoid grazing floor tiles.
## Default 0.0 keeps top-down mode's behavior exactly as before.
func _has_line_of_sight(vertical_offset: float = 0.0) -> bool:
	if not is_instance_valid(_player):
		return false
	var offset := Vector2(0, vertical_offset)
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position + offset, _player.global_position + offset, vision_wall_mask
	)
	query.exclude = [self]
	var result := space_state.intersect_ray(query)
	return result.is_empty()


func _process_chase(can_see_player: bool) -> void:
	if not can_see_player:
		return
	var to_player: Vector2 = _player.global_position - global_position
	_last_known_player_pos = _player.global_position
	if to_player.length() <= attack_distance:
		_hit_player()
		return
	velocity = to_player.normalized() * chase_speed
	move_and_slide()
	_face_towards(velocity)
	_set_awareness_light(chase_light_color)
	_set_awareness_indicator("!", chase_light_color)
	if anim:
		anim.play("walk")


func _start_suspicion() -> void:
	_top_down_state = TopDownState.SUSPICIOUS
	_suspicion_timer = suspicion_duration
	_set_awareness_light(suspicious_light_color)
	_set_awareness_indicator("!", suspicious_light_color)


func _process_suspicion(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	if is_instance_valid(_player):
		_face_towards(_player.global_position - global_position)
	if anim:
		anim.play("idle")

	_suspicion_timer -= delta
	if _suspicion_timer <= 0.0:
		_top_down_state = TopDownState.CHASE
		_set_awareness_light(chase_light_color)
		_set_awareness_indicator("!", chase_light_color)


func _start_searching() -> void:
	_top_down_state = TopDownState.SEARCH
	_search_timer = search_duration
	_search_look_timer = search_look_interval
	_search_looks_done = 0
	velocity = Vector2.ZERO
	# First glance towards wherever the player was last headed.
	_face_towards(_last_known_player_pos - global_position)
	_set_awareness_light(suspicious_light_color)
	_set_awareness_indicator("?", suspicious_light_color)


func _process_search(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()

	if anim:
		anim.play("idle")

	_search_timer -= delta
	_search_look_timer -= delta

	if _search_look_timer <= 0.0:
		_search_look_timer = search_look_interval
		# Flip which way it's "looking" — alternates left/right like it's scanning.
		if body:
			body.scale.x = -body.scale.x if body.scale.x != 0 else 1
		_search_looks_done += 1

	var done_looking := search_look_count > 0 and _search_looks_done >= search_look_count
	if _search_timer <= 0.0 or done_looking:
		_top_down_state = TopDownState.RETURN
		_set_awareness_light(patrol_light_color)
		_set_awareness_indicator("", patrol_light_color)


## After giving up the search, walk back to the very first spawn position
## before resuming patrol. Prevents the enemy from getting stuck patrolling
## from some random spot it ended up at after chasing the player.
func _process_return(delta: float) -> void:
	var to_spawn := _spawn_position - global_position

	if to_spawn.length() <= max(patrol_speed * delta, 6.0):
		global_position = _spawn_position
		velocity = Vector2.ZERO
		move_and_slide()
		_patrol_dir = 1
		_top_down_state = TopDownState.PATROL
		return

	velocity = to_spawn.normalized() * patrol_speed
	move_and_slide()
	_face_towards(velocity)

	if anim:
		anim.play("walk")
	_set_awareness_light(patrol_light_color)
	_set_awareness_indicator("", patrol_light_color)


func _process_patrol(delta: float) -> void:
	if not patrol_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		if anim:
			anim.play("idle")
		return

	var axis_vec := Vector2.RIGHT if patrol_axis == "Horizontal" else Vector2.DOWN

	velocity = axis_vec * patrol_speed * _patrol_dir
	move_and_slide()

	# Hit a wall tile -> turn back immediately.
	if get_slide_collision_count() > 0:
		_patrol_dir *= -1

	# How far we've walked along the patrol axis from spawn -> flip direction
	# once we hit the edge of patrol_distance.
	var offset := (global_position - _spawn_position).dot(axis_vec)
	if offset >= patrol_distance * 0.5:
		_patrol_dir = -1
	elif offset <= -patrol_distance * 0.5:
		_patrol_dir = 1

	_face_towards(velocity)

	if anim:
		anim.play("walk" if velocity.length() > 1.0 else "idle")
	_set_awareness_light(patrol_light_color)
	_set_awareness_indicator("", patrol_light_color)


func _set_awareness_light(color: Color) -> void:
	if awareness_light:
		awareness_light.color = color


func _set_awareness_indicator(symbol: String, color: Color) -> void:
	if awareness_indicator:
		awareness_indicator.visible = not symbol.is_empty()
		awareness_indicator.text = symbol
		awareness_indicator.modulate = color


func _face_towards(dir: Vector2) -> void:
	if body and absf(dir.x) > 1.0:
		body.scale.x = 1 if dir.x > 0.0 else -1


## Plays the attack swing and only applies damage once the animation has
## actually reached its impact point AND the player is still within
## attack_distance at that moment. This stops the enemy from "hitting" the
## player instantly from far away just because an attack was triggered.
func _hit_player() -> void:
	if _attack_cooldown > 0.0 or not is_instance_valid(_player) or _is_attacking:
		return

	_attack_cooldown = 1.0
	_is_attacking = true
	velocity = Vector2.ZERO

	if anim:
		anim.play("attack")
		var impact_delay := anim.current_animation_length * attack_impact_fraction
		await get_tree().create_timer(impact_delay).timeout

	# Re-validate right before applying damage: the player may have moved
	# away, hidden, or been invalidated during the wind-up.
	if is_instance_valid(_player) and not _player.is_hidden:
		if global_position.distance_to(_player.global_position) <= attack_distance:
			_player.take_level_damage(contact_damage, global_position)

	# Let the rest of the swing animation finish before resuming movement/AI.
	if anim and anim.is_playing() and anim.current_animation == "attack":
		await anim.animation_finished

	_is_attacking = false


func match_state():
	match current_states:
		states.IDLE:
			anim.play("idle")
			velocity.x = 0
		states.PATROL:
			velocity.x = patrol_speed * direction
			anim.play("walk")
		states.CHASE:
			# Was `pass` — detection worked (player_in_range flipped true) but
			# nothing ever moved the enemy or faced it towards the player.
			# That's the "not detecting" symptom: it saw the player, just did
			# nothing about it until they wandered into attack range.
			if is_instance_valid(_player):
				var to_player_x: float = _player.global_position.x - global_position.x
				if absf(to_player_x) > 1.0:
					direction = 1 if to_player_x > 0.0 else -1
			velocity.x = chase_speed * direction
			anim.play("walk")
		states.ATTACK:
			# Was missing the actual damage application — it played the swing
			# animation and went straight back to IDLE without ever calling
			# take_level_damage, so attacks looked right but never hurt the
			# player. Now mirrors top-down's _hit_player timing: wait for the
			# animation's impact frame, then re-check range before applying.
			velocity.x = 0
			if anim:
				anim.play("attack")
				var impact_delay := anim.current_animation_length * attack_impact_fraction
				await get_tree().create_timer(impact_delay).timeout
				if is_instance_valid(_player) and player_in_attack_range and not _player.is_hidden:
					_player.take_level_damage(contact_damage, global_position)
				if anim.is_playing() and anim.current_animation == "attack":
					await anim.animation_finished
			current_states = states.IDLE
		states.HURT:
			pass
		states.DIE:
			velocity = Vector2.ZERO
			if anim and anim.current_animation != "dead":
				anim.play("dead")

func state_transition():
	if is_dead:
		current_states = states.DIE
		return
	
	if is_hurt:
		current_states = states.HURT
		return
	
	if player_in_attack_range:
		current_states = states.ATTACK
		return
	
	# This was commented out, which is the main bug: player_in_range was
	# being set correctly by the detector Area2D, but nothing ever acted on
	# it, so the enemy never left PATROL/IDLE to chase.
	if player_in_range:
		current_states = states.CHASE
		return

	# Player left detection range (and we're not attacking) -> stop chasing
	# and let the idle/patrol timer pick a new state again.
	if current_states == states.CHASE:
		current_states = states.IDLE

	if idle_walk_timer.is_stopped():
		if current_states == states.IDLE:
			idle_walk_timer.start(1)
		else:
			idle_walk_timer.start(3)

func choose_state():
	var rand_states = [states.IDLE,states.PATROL]
	rand_states.shuffle()
	var nxt_state = rand_states[0]
	if current_states != nxt_state:
		current_states = nxt_state
	else:
		choose_state()
	

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body
		player_in_range = not _player.is_hidden

func _on_player_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_range = true
		if top_down_mode:
			_player = body
			# Don't attack here directly — entering this Area2D just marks the
			# player as "in attack range". Whether a hit actually lands is
			# decided in _hit_player(), which re-checks the real attack_distance
			# and times the damage to the animation's impact point instead of
			# firing the instant this area is touched.

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_attack_range = false

func _on_idle_and_walk_timeout() -> void:
	choose_state()
