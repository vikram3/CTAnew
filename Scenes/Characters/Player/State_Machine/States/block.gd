extends Node
@export var counter_timer: Timer
var hit: bool = false
var block_end_requested := false
var can_parry_now: bool = false

func _on_block_state_entered() -> void:
	counter_timer.start()
	block_end_requested = false
	hit = false
	
	get_parent().check_hit.disabled = false
	get_parent().hurt_box.disabled = true
	get_parent().parent.can_attack = true
	get_parent().parent.can_ground_dash = true
	get_parent().anim.play("Block")

func _on_block_state_physics_processing(delta: float) -> void:
	get_parent().parent.velocity = Vector2.ZERO
	
	# Perfect parry during window
	if can_parry_now and hit:
		hit = false
		can_parry_now = false
		get_parent().parent.parried = true
		block_end_requested = true
		_show_perfect_parry_feedback()
		return
	
	if hit and counter_timer.time_left > 0:
		hit = false
		get_parent().parent.parried = true
		block_end_requested = true
		return
	
	if !block_end_requested and counter_timer.time_left <= 0:
		block_end_requested = true
	
	if block_end_requested:
		_end_block()

func _end_block():
	block_end_requested = false
	get_parent().parent.can_block = true
	get_parent().check_hit.disabled = true
	get_parent().hurt_box.disabled = false

func _on_check_hit_area_entered(area: Area2D) -> void:
	hit = true

func enable_parry_window() -> void:
	can_parry_now = true
	await get_tree().create_timer(0.5, false).timeout
	can_parry_now = false

func _show_perfect_parry_feedback() -> void:
	# Extra dramatic slow motion for perfect parry
	Global._freeze(0.25, 0.05)  # 0.25 seconds at 5% speed (super slow!)
	
	if Global.cam:
		Global.cam.screen_shake(15, 0.3)
	
	# Show "PERFECT!" text
	_spawn_perfect_text()
	
	# Add white flash effect
	_spawn_flash_effect()

func _spawn_perfect_text() -> void:
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 102
	get_tree().root.add_child(canvas_layer)
	
	# Container for perfect text
	var perfect_container = Control.new()
	perfect_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(perfect_container)
	
	var perfect_label = Label.new()
	perfect_label.text = "PERFECT!"
	perfect_label.add_theme_font_size_override("font_size", 48)
	perfect_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.0))  # Bright gold
	perfect_label.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.0))
	perfect_label.add_theme_constant_override("outline_size", 8)
	perfect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	perfect_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	perfect_label.set_anchors_preset(Control.PRESET_CENTER)
	perfect_label.position = Vector2(-150, -30)
	perfect_label.size = Vector2(300, 60)
	perfect_container.add_child(perfect_label)
	
	# Get viewport center for pivot
	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size / 2.0
	perfect_container.pivot_offset = center
	perfect_container.scale = Vector2(0.0, 0.0)
	
	# Animate - explosive pop from center
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	# Pop in from center with overshoot
	tween.tween_property(perfect_container, "scale", Vector2(1.3, 1.3), 0.12)
	tween.tween_property(perfect_container, "scale", Vector2(1.0, 1.0), 0.08)
	
	# Hold for a moment
	tween.tween_interval(0.1)
	
	# Rise and fade
	tween.tween_property(perfect_label, "position:y", perfect_label.position.y - 40, 0.4)
	tween.parallel().tween_property(perfect_container, "modulate:a", 0.0, 0.4)
	
	# Cleanup
	await tween.finished
	canvas_layer.queue_free()

func _spawn_flash_effect() -> void:
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 103  # Above everything
	get_tree().root.add_child(canvas_layer)
	
	var flash = ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 0.0)  # White flash
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(flash)
	
	# Quick flash in and out
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.6, 0.05)  # Flash in
	tween.tween_property(flash, "color:a", 0.0, 0.15)  # Fade out
	
	# Cleanup
	await tween.finished
	canvas_layer.queue_free()
