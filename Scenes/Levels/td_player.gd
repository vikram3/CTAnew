extends CharacterBody2D
class_name Player

# =====================================================
# SIGNALS
# =====================================================
signal died
signal damaged(current_health: float)
signal hidden_state_changed(is_hidden: bool)
signal stamina_changed(current_stamina: float, max_stamina: float)

# =====================================================
# MOVEMENT MODE
#
# TOP_DOWN  -> exact original Level 1 behaviour (4-directional, hiding, etc).
# PLATFORMER -> new Level 2 behaviour (gravity, jumping, left/right only).
#
# Defaults to TOP_DOWN so any existing scene (Level 1) that doesn't set this
# in the Inspector keeps working exactly as before. Level 2's Player node
# just needs this switched to Platformer in the Inspector (Level2Controller
# also sets it in code as a safety net).
# =====================================================
enum MovementMode { TOP_DOWN, PLATFORMER }

@export_group("Movement Mode")
@export var movement_mode: MovementMode = MovementMode.TOP_DOWN

# =====================================================
# EXPORTS (original — unchanged)
# =====================================================
@export var speed: float = 120.0
@export var invulnerable_time: float = 1.0
@export var knockback_strength: float = 220.0
@export var knockback_time: float = 0.16

@export var stats: Stats
@export var anim: AnimationPlayer        # AnimationPlayer node
@export var sprite: Node2D               # your AnimatedSprite2D or Sprite2D (for flipping/modulate)
@export var hurt_box: Area2D

@export_group("Top Down Sprint")
@export var sprint_action: StringName = &"sprint"
@export_range(1.0, 2.0, 0.05) var sprint_speed_multiplier: float = 1.5
@export_range(1.0, 2.0, 0.05) var sprint_animation_speed_scale: float = 1.2
@export_range(1.0, 200.0, 1.0) var stamina_max: float = 100.0
@export_range(1.0, 100.0, 1.0) var stamina_drain_per_second: float = 34.0
@export_range(1.0, 100.0, 1.0) var stamina_recovery_per_second: float = 26.0
@export_range(0.0, 3.0, 0.05) var stamina_recovery_delay: float = 0.7

# --- Hiding (Top-Down only) ---
## Input action that both enters AND exits hiding. Defaults to Godot's built-in
## "ui_accept" (Space/Enter/gamepad A). Must be standing inside a HidingSpot's
## zone to hide; can be pressed from anywhere while hidden to break cover.
@export var hide_action: StringName = &"ui_accept"
## How long the little "scurry into hiding" dash takes when first entering cover.
## Movement is locked for this brief moment only.
@export var hide_dash_time: float = 0.18
## How squashed the sprite gets mid-dash (comedic pop). x>1, y<1 = wide & flat.
@export var hide_squash_scale: Vector2 = Vector2(1.3, 0.7)
## Speed multiplier applied while hidden and moving around inside cover (1.0 = normal speed).
@export var hide_move_speed_multiplier: float = 1.0
## Color/alpha applied while hidden (dim, blended into the prop).
@export var hidden_tint: Color = Color(0.62, 0.85, 0.62, 0.78)
## Distance of the step-out dash when exiting cover via the hide key.
@export var hide_exit_dash_distance: float = 20.0
## How long that step-out dash takes — the in-between beat before free movement resumes.
@export var hide_exit_dash_time: float = 0.16

# --- Platformer (Level 2 only) ---
@export_group("Platformer Movement")
## Downward acceleration applied every physics frame while in Platformer mode
## (used while rising / on the ground; see platformer_fall_gravity_multiplier
## for the falling case).
@export var platformer_gravity: float = 900.0
## Multiplies gravity while falling (velocity.y > 0). Real platformers almost
## never use the same gravity for rising and falling — falling faster than
## you rise is a huge part of what makes a jump feel snappy instead of floaty.
## 1.0 = no difference (the "floaty" feeling you're getting right now).
## Try 1.5–2.0.
@export var platformer_fall_gravity_multiplier: float = 1.7
## Upward velocity applied on jump (negative = up).
@export var platformer_jump_velocity: float = -320.0
## Terminal fall speed so you don't accelerate forever off a big drop.
@export var platformer_max_fall_speed: float = 700.0
## Max horizontal run speed.
@export var platformer_run_speed: float = 160.0
## How fast horizontal velocity ramps toward target speed (higher = snappier).
## Only used when platformer_instant_speed is false.
@export var platformer_ground_acceleration: float = 1400.0
## Multiplier applied to acceleration while airborne (lower = floatier air control).
## Only used when platformer_instant_speed is false.
@export var platformer_air_control_multiplier: float = 0.65
## Level 3 style movement: jump straight to platformer_run_speed on input
## instead of ramping up/down through ground_acceleration. Feels snappier
## and more "arcade," at the cost of the smoother accel/decel curve.
@export var platformer_instant_speed: bool = true
## Grace window after walking off a ledge where a jump still registers.
@export var platformer_coyote_time: float = 0.1
## Grace window where a jump press slightly before landing still registers.
@export var platformer_jump_buffer_time: float = 0.1
## Releasing jump early while still rising cuts velocity by this factor (variable jump height).
@export var platformer_jump_release_dampen: float = 0.45
## Input action used to jump in Platformer mode.
@export var platformer_jump_action: StringName = &"ui_accept"
## Speeds up (or slows down) all animations while in Platformer mode.
## 1.0 = normal, 1.5 = 50% faster, 2.0 = double speed, etc.
## Applied via AnimationPlayer.speed_scale, so every clip (idle/walk in
## all directions) speeds up together without touching individual animations.
## Has zero effect in Top-Down mode (speed_scale is reset to 1.0 there).
@export var platformer_anim_speed_scale: float = 1.5
## Guaranteed collision layer/mask for Platformer mode, applied in _ready()
## regardless of whatever a LevelController does (or fails to do). This is
## what fixed coins not being collectible in Level 2 — the Player's
## collision_layer was staying at whatever the editor happened to have
## (1), which didn't match what Coin's Area2D was listening for (2),
## because Level2Controller's wiring wasn't actually reaching this node.
## Setting it here means Level 2 works correctly no matter what's set (or
## not set) in the scene/controller. Has zero effect in Top-Down mode.
@export var platformer_collision_layer: int = 2
@export var platformer_collision_mask: int = 1
## Level 3 style knockback: instead of freezing input and hard-overriding
## velocity for a fixed knockback_time (what Top-Down mode still does below),
## Platformer mode layers a separate, decaying force on top of normal
## movement via apply_force()/external_velocity — same model as your Level 3
## character's force_decay. Higher = snaps back to normal faster.
@export var platformer_force_decay: float = 750.0

@export_group("Fail-safes / Auto Restart")
## Master switch for the fall/stuck auto-restart checks below.
@export var auto_restart_enabled: bool = true
## Seconds of continuous falling (Platformer mode, moving downward, not on
## floor) before the level restarts. Guards against bottomless pits. Has no
## effect in Top-Down mode (no gravity there).
@export var fall_restart_time: float = 3.0
## Optional hard kill-plane. If > 0 and global_position.y exceeds this value,
## the level restarts immediately regardless of fall_restart_time. Set to 0
## to disable and rely on fall_restart_time only.
@export var fall_kill_y: float = 0.0
## Seconds the player can hold a movement direction with almost no
## positional change before being considered "stuck" and the level restarts.
## Works in both modes. Set to 0 to disable stuck-detection.
@export var stuck_restart_time: float = 3.0
## Minimum distance (pixels) the player must cover within stuck_restart_time
## to NOT be considered stuck.
@export var stuck_min_distance: float = 6.0

# Animation names expected on `anim`:
#   idle_down, idle_up, idle_right, idle_left (or use idle_right + scale flip)
#   walk_down, walk_up, walk_right, walk_left (or use walk_right + scale flip)

enum Facing { DOWN, UP, LEFT, RIGHT }

var facing: Facing = Facing.DOWN
var is_dead: bool = false
var is_invulnerable: bool = false
var is_hidden: bool = false
var is_sprinting: bool = false
var current_stamina: float
var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_timer: float = 0.0
var _stamina_recovery_timer: float = 0.0

var _invuln_timer: Timer

# --- Hiding state ---
var _current_hide_spot: HidingSpot = null
## Hide spot the player is currently standing inside but not yet hidden in.
## Set/cleared by HidingSpot when the player enters/exits its zone.
var _nearby_hide_spot: HidingSpot = null
var _is_dashing_to_hide: bool = false
var _is_exiting_hide: bool = false
var _saved_z_index: int = 0
var _saved_z_as_relative: bool = true

# --- Platformer state ---
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
## Decaying knockback force, added on top of normal movement each frame and
## smoothed toward zero via platformer_force_decay — the Level 3 model.
## Only used/updated in Platformer mode; Top-Down mode's knockback still
## goes entirely through _knockback_velocity/_knockback_timer, untouched.
var external_velocity: Vector2 = Vector2.ZERO
## Gravity/jump's own vertical velocity, tracked separately from `velocity`.
## `velocity.y` itself is recombined fresh every frame as
## _platformer_vertical_velocity + external_velocity.y — it is NEVER fed
## back into this accumulator. That separation is what stops knockback from
## compounding: previously gravity's persistent velocity.y absorbed the
## knockback every frame, then kept adding more (still-decaying) knockback
## on top of that already-boosted value, snowballing into the player
## rocketing upward instead of a quick pop that fades out.
var _platformer_vertical_velocity: float = 0.0

# --- Fail-safe / auto-restart state ---
var _fall_timer: float = 0.0
var _stuck_timer: float = 0.0
var _stuck_reference_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("player")
	current_stamina = stamina_max
	_stuck_reference_position = global_position

	if stats:
		stats.health_updated.connect(_on_health_updated)
		stats.health_depleated.connect(_on_health_depleated)

	if hurt_box:
		hurt_box.stats = stats
		if hurt_box.has_signal("area_entered"):
			hurt_box.area_entered.connect(_on_hurt_box_area_entered)

	_invuln_timer = Timer.new()
	_invuln_timer.one_shot = true
	add_child(_invuln_timer)
	_invuln_timer.timeout.connect(func(): is_invulnerable = false)


func _physics_process(_delta: float) -> void:
	# --- Shared across both modes (unchanged from original) ---
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _knockback_timer > 0.0:
		_knockback_timer -= _delta
		_update_top_down_sprint(Vector2.ZERO, _delta)
		velocity = _knockback_velocity
		move_and_slide()
		return

	# --- Mode split ---
	if movement_mode == MovementMode.PLATFORMER:
		_physics_process_platformer(_delta)
		return

	# --- Everything below this line is the ORIGINAL Top-Down logic,
	#     completely untouched, and only runs when movement_mode == TOP_DOWN. ---

	# Make sure animations play at normal speed in Top-Down mode, in case
	# platformer_anim_speed_scale was left applied from a previous mode switch.
	if anim:
		anim.speed_scale = 1.0

	if _is_dashing_to_hide:
		# The entry dash tween is driving global_position — don't fight it with velocity.
		_update_top_down_sprint(Vector2.ZERO, _delta)
		velocity = Vector2.ZERO
		return

	if _is_exiting_hide:
		# Committed to a break-cover step-out dash — same deal.
		_update_top_down_sprint(Vector2.ZERO, _delta)
		velocity = Vector2.ZERO
		return

	# Space (hide_action) toggles hiding: hide when standing in a zone, exit when already hidden.
	if Input.is_action_just_pressed(hide_action):
		if is_hidden:
			_break_cover(_facing_vector())
			return
		elif _nearby_hide_spot:
			hide_at(_nearby_hide_spot)
			return

	if is_hidden and _current_hide_spot:
		_update_top_down_sprint(Vector2.ZERO, _delta)
		_process_hidden(_delta)
		return

	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	_update_top_down_sprint(input_dir, _delta)
	velocity = input_dir * speed * (sprint_speed_multiplier if is_sprinting else 1.0)
	move_and_slide()

	_update_facing(input_dir)
	_update_animation(input_dir)

	if auto_restart_enabled:
		_check_stuck_restart(_delta, input_dir)


func _update_top_down_sprint(input_dir: Vector2, delta: float) -> void:
	var previous_stamina: float = current_stamina
	var can_sprint := movement_mode == MovementMode.TOP_DOWN \
		and not is_dead \
		and not is_hidden \
		and input_dir.length_squared() > 0.001 \
		and current_stamina > 0.0 \
		and Input.is_action_pressed(sprint_action)

	is_sprinting = can_sprint
	if is_sprinting:
		current_stamina = maxf(0.0, current_stamina - stamina_drain_per_second * delta)
		_stamina_recovery_timer = stamina_recovery_delay
	else:
		_stamina_recovery_timer = maxf(0.0, _stamina_recovery_timer - delta)
		if _stamina_recovery_timer <= 0.0:
			current_stamina = minf(stamina_max, current_stamina + stamina_recovery_per_second * delta)

	if anim:
		anim.speed_scale = sprint_animation_speed_scale if is_sprinting else 1.0
	if not is_equal_approx(previous_stamina, current_stamina):
		stamina_changed.emit(current_stamina, stamina_max)


# =====================================================
# PLATFORMER MOVEMENT (Level 2 only — new)
# =====================================================
func _physics_process_platformer(delta: float) -> void:
	# Speed up all animations in Platformer mode. Re-applied every frame
	# (like the collision layer/mask below) so it's immune to anything else
	# touching `anim.speed_scale`, and so it survives a mode switch back
	# to Top-Down without needing extra bookkeeping there.
	if anim:
		anim.speed_scale = platformer_anim_speed_scale

	# Re-asserted every frame (cheap int writes) rather than once in _ready(),
	# because Level2Controller's own wiring runs AFTER this node's _ready()
	# (Godot readies children before parents) and was overwriting a one-time
	# _ready() fix with whatever its own (in this case wrong) values were.
	# Doing it here guarantees Level 2 always has the right collision setup
	# no matter what the scene/controller does.
	collision_layer = platformer_collision_layer
	collision_mask = platformer_collision_mask

	# Gravity — stronger while falling than while rising. Operates on
	# _platformer_vertical_velocity (not velocity.y directly) so it never
	# absorbs knockback — see the var's comment above for why that matters.
	var current_gravity := platformer_gravity
	if _platformer_vertical_velocity > 0.0:
		current_gravity *= platformer_fall_gravity_multiplier
	_platformer_vertical_velocity += current_gravity * delta
	if _platformer_vertical_velocity > platformer_max_fall_speed:
		_platformer_vertical_velocity = platformer_max_fall_speed

	# Coyote time bookkeeping
	if is_on_floor():
		_coyote_timer = platformer_coyote_time
	else:
		_coyote_timer -= delta

	# Jump buffering
	if Input.is_action_just_pressed(platformer_jump_action):
		_jump_buffer_timer = platformer_jump_buffer_time
	else:
		_jump_buffer_timer -= delta

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		_platformer_vertical_velocity = platformer_jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	# Variable jump height — tap for a short hop, hold for full height.
	if Input.is_action_just_released(platformer_jump_action) and _platformer_vertical_velocity < 0.0:
		_platformer_vertical_velocity *= platformer_jump_release_dampen

	var horizontal := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")

	if platformer_instant_speed:
		# Level 3 style — snap straight to full speed on input instead of
		# ramping through an acceleration curve. Snappier, more "arcade."
		velocity.x = horizontal * platformer_run_speed
	else:
		var target_speed := horizontal * platformer_run_speed
		var accel := platformer_ground_acceleration
		if not is_on_floor():
			accel *= platformer_air_control_multiplier
		velocity.x = move_toward(velocity.x, target_speed, accel * delta)

	# Smooth knockback (Level 3 style): external_velocity is a separate,
	# decaying force layered on top of normal movement instead of freezing
	# input and overriding velocity outright for a fixed duration. It's set
	# by apply_force() (called from take_level_damage() below), decays here,
	# and is combined fresh into velocity every frame — never accumulated
	# into _platformer_vertical_velocity or carried forward on its own.
	external_velocity = external_velocity.move_toward(Vector2.ZERO, platformer_force_decay * delta)
	velocity.x += external_velocity.x
	velocity.y = _platformer_vertical_velocity + external_velocity.y

	move_and_slide()

	if auto_restart_enabled:
		_check_fall_restart(delta)
		_check_stuck_restart(delta, Vector2(horizontal, 0.0))

	var facing_input := Vector2(horizontal, 0.0)
	_update_facing(facing_input)

	# While airborne, override the normal walk/idle animation with idle_up
	# (rising) or idle_down (falling) instead — looks far better than a
	# sideways walk cycle playing mid-jump. Horizontal input still flips the
	# sprite so the player still visibly faces the direction they're moving.
	# Uses _platformer_vertical_velocity rather than velocity.y so a strong
	# knockback doesn't misclassify rising/falling for a frame.
	if not is_on_floor():
		_update_airborne_animation(horizontal)
	else:
		_update_animation(facing_input)


## Applies an instantaneous force that decays smoothly over time (Level 3
## style), instead of the Top-Down knockback's hard velocity override. Only
## meaningful in Platformer mode — external_velocity is only read/decayed in
## _physics_process_platformer above.
func apply_force(direction: Vector2, strength: float) -> void:
	external_velocity += direction.normalized() * strength


# =====================================================
# FAIL-SAFES / AUTO RESTART (new — both modes, see notes per function)
# =====================================================
## Platformer-only: restarts the level if the player has been falling
## (moving downward, not on the floor) for longer than fall_restart_time, or
## if they've dropped below the optional fall_kill_y plane. Guards against
## bottomless pits / falling out of the level.
func _check_fall_restart(delta: float) -> void:
	if fall_kill_y > 0.0 and global_position.y > fall_kill_y:
		restart_level()
		return

	if not is_on_floor() and _platformer_vertical_velocity > 0.0:
		_fall_timer += delta
		if fall_restart_time > 0.0 and _fall_timer >= fall_restart_time:
			restart_level()
	else:
		_fall_timer = 0.0


## Both modes: restarts the level if the player has been holding a movement
## direction for stuck_restart_time seconds while barely moving at all
## (wedged in geometry, clipped into a wall, etc). Idle time (no input)
## never counts toward this, so standing still on purpose is safe.
func _check_stuck_restart(delta: float, input_dir: Vector2) -> void:
	if stuck_restart_time <= 0.0:
		return
	# Don't count death, hiding, or knockback as "stuck" — those already
	# freeze/override movement intentionally.
	if is_dead or is_hidden or _knockback_timer > 0.0:
		_stuck_timer = 0.0
		_stuck_reference_position = global_position
		return

	if input_dir.length() < 0.1:
		_stuck_timer = 0.0
		_stuck_reference_position = global_position
		return

	_stuck_timer += delta
	if _stuck_timer >= stuck_restart_time:
		if global_position.distance_to(_stuck_reference_position) < stuck_min_distance:
			restart_level()
		_stuck_timer = 0.0
		_stuck_reference_position = global_position


## Reloads the current scene. Called by the fall/stuck checks above; feel
## free to call this directly too (e.g. from a debug "Restart" button).
func restart_level() -> void:
	get_tree().reload_current_scene()


# =====================================================
# FACING / ANIMATION (shared — unchanged)
# =====================================================
func _update_facing(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		return
	if absf(input_dir.x) > absf(input_dir.y):
		facing = Facing.RIGHT if input_dir.x > 0 else Facing.LEFT
	else:
		facing = Facing.DOWN if input_dir.y > 0 else Facing.UP


func _update_animation(input_dir: Vector2) -> void:
	if anim == null:
		return

	var moving := input_dir != Vector2.ZERO

	if sprite:
		sprite.scale.x = 1.0

	match facing:
		Facing.RIGHT:
			anim.play("walk_right" if moving else "idle_right")
		Facing.LEFT:
			if moving:
				if sprite:
					sprite.scale.x = -1.0
				anim.play("walk_right")
			else:
				anim.play("idle_left")
		Facing.UP:
			anim.play("walk_up" if moving else "idle_up")
		Facing.DOWN:
			anim.play("walk_down" if moving else "idle_down")


## Airborne-only animation override (Platformer mode). Plays idle_up while
## rising (jump) and idle_down while falling, instead of the normal walk/idle
## cycle — a walk animation looks wrong while the player is in the air.
## Sprite flip still tracks horizontal input so facing direction is preserved.
func _update_airborne_animation(horizontal: float) -> void:
	if anim == null:
		return

	if sprite and horizontal != 0.0:
		sprite.scale.x = -1.0 if horizontal < 0.0 else 1.0

	anim.play("idle_up" if _platformer_vertical_velocity < 0.0 else "idle_down")


func _facing_vector() -> Vector2:
	match facing:
		Facing.RIGHT: return Vector2.RIGHT
		Facing.LEFT: return Vector2.LEFT
		Facing.UP: return Vector2.UP
		_: return Vector2.DOWN


# =====================================================
# HIDING (Top-Down only — unchanged)
# =====================================================
## Called by a HidingSpot when the player enters its trigger area — makes this
## spot available to hide in, but does NOT hide automatically. Press hide_action
## (space) while standing inside to actually duck into cover.
func set_nearby_hide_spot(spot: HidingSpot) -> void:
	_nearby_hide_spot = spot


## Called by a HidingSpot when the player's collider leaves its trigger area.
## Just clears availability — does NOT un-hide. If the player is currently
## hidden, they stay hidden until they press hide_action to break cover.
func clear_nearby_hide_spot(spot: HidingSpot) -> void:
	if _nearby_hide_spot == spot:
		_nearby_hide_spot = null


## Ducks the player into cover: dash-locks movement briefly, tints the sprite,
## and makes sure the prop draws in front of the player.
func hide_at(spot: HidingSpot) -> void:
	if is_dead or _current_hide_spot == spot:
		return

	_current_hide_spot = spot
	set_hidden_state(true)

	# Make sure the prop draws in front of the player, not just a color tint.
	if spot.occluder:
		_saved_z_index = z_index
		_saved_z_as_relative = z_as_relative
		z_as_relative = false
		z_index = spot.occluder.z_index - 1

	_dash_to(spot.get_hide_position())


## Restores visibility/z-order. Used internally by _break_cover(); HidingSpot no
## longer calls this on body_exited since exiting cover is now a manual action.
func unhide_from(spot: HidingSpot) -> void:
	if _current_hide_spot != spot:
		return

	_current_hide_spot = null
	set_hidden_state(false)
	z_as_relative = _saved_z_as_relative
	z_index = _saved_z_index

	if sprite:
		sprite.position = Vector2.ZERO
		sprite.rotation = 0.0
		var pop_tween := create_tween()
		pop_tween.tween_property(sprite, "scale", Vector2(1.15, 0.85), 0.08)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		pop_tween.tween_property(sprite, "scale", Vector2.ONE, 0.14)\
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _dash_to(target_pos: Vector2) -> void:
	_is_dashing_to_hide = true

	var pos_tween := create_tween()
	pos_tween.tween_property(self, "global_position", target_pos, hide_dash_time)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pos_tween.finished.connect(func(): _is_dashing_to_hide = false)

	if sprite:
		sprite.scale = Vector2.ONE
		var squash_tween := create_tween()
		squash_tween.tween_property(sprite, "scale", hide_squash_scale, hide_dash_time * 0.5)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		squash_tween.tween_property(sprite, "scale", Vector2.ONE, hide_dash_time * 0.5)\
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## While hidden, movement is normal (real velocity from input) so you can walk
## around inside cover. Exiting only happens via hide_action (handled in
## _physics_process above) — walking to the edge of the zone no longer un-hides.
func _process_hidden(_delta: float) -> void:
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	velocity = input_dir * speed * hide_move_speed_multiplier
	move_and_slide()

	_update_facing(input_dir)
	_update_animation(input_dir)


## Manual break-cover, triggered by pressing hide_action while hidden: restores
## visibility/z-order immediately, then a short committed step-out dash before
## free movement resumes — mirroring the dash into hiding.
func _break_cover(exit_dir: Vector2) -> void:
	var spot := _current_hide_spot
	if spot:
		unhide_from(spot)

	if exit_dir.length() < 0.1:
		return

	_is_exiting_hide = true
	_update_facing(exit_dir)
	if anim:
		_update_animation(exit_dir)

	var exit_target := global_position + exit_dir.normalized() * hide_exit_dash_distance
	var pos_tween := create_tween()
	pos_tween.tween_property(self, "global_position", exit_target, hide_exit_dash_time)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pos_tween.finished.connect(func(): _is_exiting_hide = false)


# =====================================================
# DAMAGE / HEALTH (shared — unchanged)
# =====================================================
func _on_hurt_box_area_entered(area: Area2D) -> void:
	if is_dead or is_invulnerable:
		return
	if area.has_method("do_damage"):
		_start_invulnerability()


func _start_invulnerability() -> void:
	is_invulnerable = true
	_invuln_timer.start(invulnerable_time)
	# Flash the sprite node, not the AnimationPlayer
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.3, 0.1)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
		tween.set_loops(int(invulnerable_time / 0.2))


func take_level_damage(damage: int, source_position: Vector2) -> void:
	if is_dead or is_invulnerable or not hurt_box:
		return
	hurt_box.apply_damage(damage)

	var away := global_position - source_position

	if movement_mode == MovementMode.PLATFORMER:
		# Smooth knockback (Level 3 style): apply_force layers a decaying
		# force on top of normal movement instead of freezing input and
		# overriding velocity outright for knockback_time. Doesn't touch
		# _knockback_velocity/_knockback_timer at all, so the Top-Down
		# branch below is completely unaffected.
		var knock_dir := away.normalized() if away.length() > 0.0 else Vector2.UP
		apply_force(knock_dir, knockback_strength)
	else:
		# Original Top-Down knockback — byte-for-byte unchanged.
		_knockback_velocity = away.normalized() * knockback_strength if away.length() > 0.0 else Vector2.DOWN * knockback_strength
		_knockback_timer = knockback_time

	_start_invulnerability()


func set_hidden_state(value: bool) -> void:
	if is_hidden == value:
		return
	is_hidden = value
	hidden_state_changed.emit(is_hidden)
	if sprite:
		sprite.modulate = hidden_tint if is_hidden else Color.WHITE


func _on_health_updated(current_health: float) -> void:
	damaged.emit(current_health)


func _on_health_depleated() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	external_velocity = Vector2.ZERO
	_platformer_vertical_velocity = 0.0
	if sprite:
		sprite.modulate.a = 1.0
	if anim:
		anim.stop()
	died.emit()

func _draw() -> void:
	if OS.is_debug_build():
		draw_line(Vector2(-8, 0), Vector2(8, 0), Color.CYAN, 1.5)
