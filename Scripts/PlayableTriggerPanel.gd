extends PanelContainer

signal play_pressed

@onready var description_label = $VBoxContainer/Description
@onready var play_button       = $VBoxContainer/PlayButton
@onready var anim_player       = $AnimationPlayer

var is_completed: bool = false

func _ready():
	play_button.pressed.connect(func(): play_pressed.emit())
	anim_player.play("pulse")
	# Fill the width assigned by WebtoonReader
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER


# Called by WebtoonReader with the panel width and text
func setup(text: String, panel_width: float = 720.0):
	description_label.text  = text
	custom_minimum_size     = Vector2(panel_width, 220)


# Called by WebtoonReader when zoom changes
func set_width(panel_width: float):
	custom_minimum_size.x = panel_width


func set_play_again_mode():
	is_completed       = true
	play_button.text   = "🔄 Play Again"
	description_label.text = "✅ Completed! " + description_label.text

	if anim_player.has_animation("completed"):
		anim_player.play("completed")
	else:
		anim_player.stop()
