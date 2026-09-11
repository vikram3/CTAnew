extends Node2D
class_name Chapter34Scenario

signal level_completed(success: bool)

@export_enum("cliff", "exploration", "escape", "tutorial") var scenario: String = "cliff"
@export var player: Node2D
@export var survival_time: float = 60.0
@export var required_coins: int = 35

var _timer: float = 0.0
var _finished: bool = false


func _ready() -> void:
	if player:
		player.add_to_group("player")
		if player.has_signal("died"):
			player.connect("died", _fail)
	CollectedItems.reset()
	if scenario == "exploration":
		CollectedItems.coins_collected.connect(_on_coin)
		_spawn_coins(50)
		_spawn_companion()
	elif scenario == "cliff":
		_spawn_pursuer()
		_spawn_fall_zone()
	elif scenario == "escape":
		_spawn_companion()
		_spawn_escape_system()


func _process(delta: float) -> void:
	if _finished:
		return
	if scenario == "cliff":
		_timer += delta
		if _timer >= survival_time:
			_complete()


func _on_coin() -> void:
	if CollectedItems.coins_amount >= required_coins:
		_complete()


func _spawn_coins(count: int) -> void:
	var scene := preload("res://Scenes/Collectables/Coin/coin.tscn")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3401
	for index in count:
		var coin := scene.instantiate() as Node2D
		add_child(coin)
		coin.position = Vector2(rng.randf_range(-410, 410), rng.randf_range(-200, 200))


func _spawn_companion() -> void:
	var companion := CompanionFollow.new()
	companion.comments = ["Keep moving, CT.", "That cluster looks promising.", "I will stay out of your way."]
	companion.position = Vector2(-90, 30)
	add_child(companion)


func _spawn_pursuer() -> void:
	var pursuer := PursuerController.new()
	pursuer.position = Vector2(300, 0)
	add_child(pursuer)


func _spawn_fall_zone() -> void:
	var hazard := FallDeathHazard.new()
	hazard.position = Vector2(0, 360)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(1100, 80)
	shape.shape = rectangle
	hazard.add_child(shape)
	hazard.level_controller = null
	hazard.body_entered.connect(_on_fall_body_entered)
	add_child(hazard)


func _spawn_escape_system() -> void:
	var scroll := AutoScrollController.new()
	scroll.player = player
	scroll.speed = 135.0
	scroll.start_edge_x = -420.0
	scroll.player_fell_behind.connect(_fail)
	add_child(scroll)
	var goal := Area2D.new()
	goal.position = Vector2(860, 0)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(40, 440)
	shape.shape = rectangle
	goal.add_child(shape)
	goal.body_entered.connect(_on_goal_body_entered)
	add_child(goal)


func _complete() -> void:
	if _finished:
		return
	_finished = true
	level_completed.emit(true)


func _on_fall_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_fail()


func _on_goal_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_complete()


func _fail(_unused = null) -> void:
	if _finished:
		return
	_finished = true
	level_completed.emit(false)
