extends CanvasLayer

@onready var popup_panel = $PopupPanel
@onready var icon_label = $PopupPanel/HBoxContainer/IconLabel
@onready var achievement_title = $PopupPanel/HBoxContainer/VBoxContainer/AchievementTitle
@onready var achievement_desc = $PopupPanel/HBoxContainer/VBoxContainer/AchievementDesc
@onready var close_btn = $PopupPanel/HBoxContainer/VBoxContainer/CloseButton
var auto_close_timer: SceneTreeTimer = null

func _ready():
	# Start hidden and off screen
	popup_panel.position.y = -200
	popup_panel.modulate.a = 0.0
	close_btn.pressed.connect(_on_close)

func show_achievement(icon: String, title: String, desc: String):
	icon_label.text = icon
	achievement_title.text = title
	achievement_desc.text = desc
	
	# Slide in from top - comic style
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup_panel, "position:y", 20, 0.4)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(popup_panel, "modulate:a", 1.0, 0.3)
	
	await tween.finished
	
	# Auto close after 3 seconds
	auto_close_timer = get_tree().create_timer(3.0)
	auto_close_timer.timeout.connect(_on_close)

func _on_close():
	# Slide out to top
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup_panel, "position:y", -200, 0.3)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(popup_panel, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	queue_free()
