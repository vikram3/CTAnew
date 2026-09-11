extends Node2D

func _ready() -> void:
	$CanvasLayer/Label.text = "Coins: " + str(CollectedItems.coins_amount)
	CollectedItems.connect("coins_collected", on_coins_collected)

func _on_trigger_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		Global.boss.decision_locked = false
		Global.boss._active()
		$Enviroment/walls/AnimationPlayer.play("activate")
		$Enviroment/trigger/CollisionShape2D.call_deferred("set_disabled", true)

func on_coins_collected():
	$CanvasLayer/Label.text = "Coins: " + str(CollectedItems.coins_amount)
