extends CharacterBody2D
class_name CharacterController

@export var character_data: CharacterData
@export var projectile:PackedScene
@export var force_decay:float = 750.0
@export var body:Node2D
@export var projectile_point:Node2D
@export var state_manager:Node
@export var state_chart: StateChart
@export var stats:Stats
@export var anim: AnimationPlayer
@export var health_bar:ProgressBar
@export var hurt_box: CollisionShape2D
@export var check_hit: CollisionShape2D
var input_locked := false
@export var can_double_jump:bool = false
@export var can_attack:bool = true
@export var can_block:bool = true
@export var parried:bool = false
@export var can_ground_dash:bool = true
@export var can_air_dash:bool = true
@export var is_hurt:bool = false
@export var is_dead:bool = false
@export var doing_counter:bool = false
var cam_root:Node2D
var external_velocity: Vector2 = Vector2.ZERO
var input_dir: Vector2 = Vector2.ZERO

# ---------------------------------------------------------------------------
# Compatibility with Enemy.gd / Coin.gd, which only need three things from
# whatever node is in the "player" group: an `is_hidden` property, a
# `take_level_damage(damage, source_position)` method, and a `died` signal.
# This character has no hiding mechanic, so is_hidden just stays false —
# Enemy.gd's checks treat that as "always visible", which is correct here.
# ---------------------------------------------------------------------------
signal died
var is_hidden: bool = false

@export_group("Level Damage / Knockback")
## How long this character is immune to further hits right after taking one.
@export var invulnerable_time: float = 1.0
## Knockback strength applied via apply_force() when hit by an enemy.
@export var knockback_strength: float = 220.0
var is_invulnerable: bool = false
var _invuln_timer: Timer


func _ready() -> void:
	_apply_character_data()
	Global.player = self
	add_to_group("player")
	cam_root = get_tree().get_first_node_in_group("camera")
	if health_bar and stats and stats.stats:
		health_bar._init_health(stats.stats.max_health)

	_invuln_timer = Timer.new()
	_invuln_timer.one_shot = true
	add_child(_invuln_timer)
	_invuln_timer.timeout.connect(func(): is_invulnerable = false)

	# Guarded with is_connected() in case this is also wired up via the
	# editor's Node dock (that's what _on_player_stats_health_updated's
	# naming convention suggests) — connecting twice would just call the
	# handler twice per hit, harmless but wasteful.
	if stats:
		if stats.has_signal("health_updated") and not stats.health_updated.is_connected(_on_player_stats_health_updated):
			stats.health_updated.connect(_on_player_stats_health_updated)
		if stats.has_signal("health_depleated") and not stats.health_depleated.is_connected(_on_health_depleated):
			stats.health_depleated.connect(_on_health_depleated)


func _apply_character_data() -> void:
	if character_data == null:
		return

	if character_data.projectile_scene:
		projectile = character_data.projectile_scene

	if stats and character_data.stats:
		stats.initialize(character_data.stats)


func _physics_process(delta):
	
	state_manager._transition()
	
	if input_locked:
		return
	if is_dead:
		return
	
	if Input.is_action_just_pressed("projectile"):
		_init_projectile()
	
	move_and_slide()
	_smoothing_external_velocity(delta)
	_flip_face()
	
func _smoothing_external_velocity(delta):
	external_velocity = external_velocity.move_toward(Vector2.ZERO, force_decay * delta)
	velocity += external_velocity
func _flip_face():
	if _set_direction().x != 0:
		body.scale.x = _set_direction().x
func _set_direction():
	# checking input of player
	input_dir = Vector2(Input.get_action_strength("right") - Input.get_action_strength("left"), 0).normalized()
	return input_dir
func apply_force(direction: Vector2, strength: float) -> void:
	external_velocity += direction.normalized() * strength
func _on_player_stats_health_updated(health: Variant) -> void:
	health_bar._set_health(health)
func _init_projectile():
	if CollectedItems.coins_amount > 0:
		var p = projectile.instantiate()
		p.global_position = projectile_point.global_position
		get_tree().current_scene.add_child(p)
		CollectedItems.coins_amount -= 1
		CollectedItems.emit_signal("coins_collected")
func lock_input():
	input_locked = true
func unlock_input():
	input_locked = false
# In your coin pickup script or player script
func collect_coin():
	GameData.add_coins(1)
	# Update HUD
	$CanvasLayer/CoinLabel.text = str(GameData.data.coins)


# ---------------------------------------------------------------------------
# Called by Enemy.gd on contact — this is the piece that was completely
# missing before, which is why enemies couldn't damage this character at all.
# ---------------------------------------------------------------------------
func take_level_damage(damage: int, source_position: Vector2) -> void:
	if is_dead or is_invulnerable:
		return

	if stats:
		stats.take_damage(damage)
	else:
		push_warning("Player.take_level_damage: no Stats node is assigned; damage was not applied.")

	var away := global_position - source_position
	var knock_dir := away.normalized() if away.length() > 0.0 else Vector2.LEFT
	apply_force(knock_dir, knockback_strength)

	is_hurt = true
	is_invulnerable = true
	_invuln_timer.start(invulnerable_time)
	if anim and anim.has_animation("hurt"):
		anim.play("hurt")


func _on_health_depleated() -> void:
	if is_dead:
		return
	is_dead = true
	died.emit()
