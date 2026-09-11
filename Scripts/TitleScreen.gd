extends Control

@onready var coin_label   = $CanvasLayer/RootLayout/ButtonsPanel/CoinDisplay/HBoxContainer2/CoinLabel
@onready var continue_btn = $CanvasLayer/RootLayout/ButtonsPanel/HBoxContainer/ContinueButton
@onready var anim_player  = $AnimationPlayer
@onready var background: TextureRect = $Background
@onready var quit: Button = $CanvasLayer/RootLayout/ButtonsPanel/HBoxContainer2/quit


func _ready():
	_setup_background()
	coin_label.text = str(GameData.data.coins)
	continue_btn.visible = not GameData.data.chapter_progress.is_empty()
	anim_player.play("title_entrance")

	$CanvasLayer/RootLayout/ButtonsPanel/HBoxContainer/StartButton.pressed.connect(_on_start)
	$CanvasLayer/RootLayout/ButtonsPanel/HBoxContainer/ContinueButton.pressed.connect(_on_continue)
	$CanvasLayer/RootLayout/ButtonsPanel/HBoxContainer/ChaptersButton.pressed.connect(_on_chapters)
	$CanvasLayer/RootLayout/ButtonsPanel/HBoxContainer2/SettingsButton.pressed.connect(_on_settings)
	get_viewport().size_changed.connect(_setup_background)


# ── Background fitting ────────────────────────────────────────
#
#  Strategy: "cover" — scale the image so it fills the whole
#  viewport with no empty bars, then centre it.
#  Works like CSS  background-size: cover; background-position: center.
#
func _setup_background():
	if background == null or background.texture == null:
		return

	var vp      : Vector2 = get_viewport().get_visible_rect().size
	var tex_sz  : Vector2 = background.texture.get_size()

	if tex_sz.x <= 0 or tex_sz.y <= 0:
		return

	# Scale factor needed to cover the viewport in each axis
	var scale_x : float = vp.x / tex_sz.x
	var scale_y : float = vp.y / tex_sz.y

	# "Cover" = use the LARGER scale so no axis has empty space
	var scale   : float = max(scale_x, scale_y)

	var new_size : Vector2 = tex_sz * scale

	# Apply
	background.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
	background.size                = new_size
	background.custom_minimum_size = new_size

	# Centre within the viewport (may be slightly larger than vp on one axis)
	background.position = (vp - new_size) * 0.5

	# Make sure it renders behind the CanvasLayer UI
	background.z_index = -1
	move_child(background, 0)


# ── Navigation ────────────────────────────────────────────────
func _on_start():
	GameData.data.chapter_progress.clear()
	SceneManager.go_to_chapter(1)

func _on_continue():
	SceneManager.go_to_chapter(GameData.data.current_chapter)

func _on_chapters():
	SceneManager.go_to_chapter_select()

func _on_settings():
	SceneManager.go_to_settings()


func _on_quit_pressed() -> void:
	get_tree().quit()
