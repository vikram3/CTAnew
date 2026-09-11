extends Control


const CHAPTERS = [
	{"num": 1, "title": "The Troll Awakens", "coins_to_unlock": 0},
	{"num": 2, "title": "The Coin Cave",      "coins_to_unlock": 0},
	{"num": 3, "title": "Bridge of Doom",     "coins_to_unlock": 0},
	{"num": 4, "title": "The Final Troll",    "coins_to_unlock": 0},
	{"num": 5, "title": "Shadow Valley",      "coins_to_unlock": 0},
	{"num": 6, "title": "The Dark Cavern",    "coins_to_unlock": 0},
	{"num": 7, "title": "Troll's Peak",       "coins_to_unlock": 0},
	{"num": 8, "title": "Final Reckoning",    "coins_to_unlock": 0},
]

# ── Tunables ───────────────────────────────────────────────────
const TOPBAR_H   = 52     # px  top bar height
const PAD        = 10     # px  grid gap + outer margin
const CARD_H_MIN = 96     # px  card won't go shorter than this
const CARD_H_MAX = 180    # px  card won't grow taller than this
const BTN_H      = 36     # px  action button height

# ── Runtime refs ───────────────────────────────────────────────
var _coin_label : Label
var _grid       : GridContainer
var _toast      : PanelContainer
var _toast_lbl  : Label
var _toast_tw   : Tween


# ══════════════════════════════════════════════════════════════
#  READY
# ══════════════════════════════════════════════════════════════
func _ready():
	# Root fills the whole window
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_skeleton()
	_populate()
	get_viewport().size_changed.connect(_on_resized)


# ══════════════════════════════════════════════════════════════
#  SKELETON  (called once)
# ══════════════════════════════════════════════════════════════
func _build_skeleton():
	# ── Master VBox — top-bar then everything else ─────────────
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	add_child(vbox)

	# ── TOP BAR ────────────────────────────────────────────────
	var topbar = PanelContainer.new()
	topbar.custom_minimum_size.y = TOPBAR_H
	topbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(topbar)

	var tb_hbox = HBoxContainer.new()
	tb_hbox.add_theme_constant_override("separation", 8)
	topbar.add_child(tb_hbox)

	# Back button
	var back = Button.new()
	back.text = "← Back"
	back.custom_minimum_size = Vector2(84, 0)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(SceneManager.go_to_title)
	tb_hbox.add_child(back)

	# Centre title
	var title = Label.new()
	title.text = "SELECT CHAPTER"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	tb_hbox.add_child(title)

	# Coin display
	var coin_hbox = HBoxContainer.new()
	coin_hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coin_hbox.add_theme_constant_override("separation", 4)
	tb_hbox.add_child(coin_hbox)

	var coin_icon = Label.new()
	coin_icon.text = "🪙"
	coin_icon.add_theme_font_size_override("font_size", 13)
	coin_hbox.add_child(coin_icon)

	_coin_label = Label.new()
	_coin_label.add_theme_font_size_override("font_size", 13)
	_coin_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_hbox.add_child(_coin_label)

	var rpad = Control.new()
	rpad.custom_minimum_size.x = 8
	tb_hbox.add_child(rpad)

	# ── SCROLL  (expands to fill the rest) ─────────────────────
	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical    = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)

	# ── Centering wrapper inside scroll ───────────────────────
	var wrapper = MarginContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	wrapper.add_theme_constant_override("margin_left",   PAD)
	wrapper.add_theme_constant_override("margin_right",  PAD)
	wrapper.add_theme_constant_override("margin_top",    PAD)
	wrapper.add_theme_constant_override("margin_bottom", PAD)
	scroll.add_child(wrapper)

	# ── Grid ───────────────────────────────────────────────────
	_grid = GridContainer.new()
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", PAD)
	_grid.add_theme_constant_override("v_separation", PAD)
	wrapper.add_child(_grid)

	# ── Toast (overlay only, separate CanvasLayer) ─────────────
	var toast_layer = CanvasLayer.new()
	toast_layer.layer = 10
	add_child(toast_layer)

	_toast = PanelContainer.new()
	_toast.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_toast.offset_left   = 48
	_toast.offset_right  = -48
	_toast.offset_bottom = -(PAD * 3)
	_toast.offset_top    = _toast.offset_bottom - 46
	_toast.hide()
	toast_layer.add_child(_toast)

	_toast_lbl = Label.new()
	_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_toast_lbl.add_theme_font_size_override("font_size", 13)
	_toast.add_child(_toast_lbl)


# ══════════════════════════════════════════════════════════════
#  POPULATE  (called on ready + resize + after unlock)
# ══════════════════════════════════════════════════════════════
func _populate():
	for c in _grid.get_children():
		c.queue_free()

	_grid.columns    = _cols()
	_coin_label.text = str(GameData.data.coins)

	for ch in CHAPTERS:
		_grid.add_child(_make_card(ch))


func _on_resized():
	_populate()


# ══════════════════════════════════════════════════════════════
#  SIZING HELPERS
# ══════════════════════════════════════════════════════════════
func _cols() -> int:
	var w = get_viewport().get_visible_rect().size.x - PAD * 2
	# One column per ~260 px, clamped 1–4
	return clamp(int(w / 260.0), 1, 4)


func _card_h() -> float:
	# Try to make all cards fit on screen without scrolling
	var rows    = ceil(float(CHAPTERS.size()) / float(_cols()))
	var vp_h    = get_viewport().get_visible_rect().size.y
	var avail   = vp_h - TOPBAR_H - PAD * (rows + 1)
	var ideal   = avail / rows
	return clamp(ideal, CARD_H_MIN, CARD_H_MAX)


# ══════════════════════════════════════════════════════════════
#  CARD FACTORY
# ══════════════════════════════════════════════════════════════
func _make_card(ch: Dictionary) -> Control:
	var unlocked  = GameData.is_chapter_unlocked(ch.num)
	var completed = GameData.is_chapter_fully_completed(ch.num)
	var progress  = GameData.get_chapter_progress(ch.num) > 0
	var unlock_cost := ChapterData.get_unlock_cost(ch.num)

	# ── Shell ──────────────────────────────────────────────────
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size   = Vector2(0, _card_h())

	# ── Inner margin ───────────────────────────────────────────
	var mg = MarginContainer.new()
	mg.add_theme_constant_override("margin_left",   10)
	mg.add_theme_constant_override("margin_right",  10)
	mg.add_theme_constant_override("margin_top",    8)
	mg.add_theme_constant_override("margin_bottom", 8)
	card.add_child(mg)

	# ── Content VBox ───────────────────────────────────────────
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 3)
	mg.add_child(col)

	# Row 1 — chapter number + status icon
	var row1 = HBoxContainer.new()
	row1.add_theme_constant_override("separation", 4)
	col.add_child(row1)

	var num_lbl = Label.new()
	num_lbl.text = "CH %02d" % ch.num
	num_lbl.add_theme_font_size_override("font_size", 10)
	row1.add_child(num_lbl)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(spacer)

	var icon = Label.new()
	icon.add_theme_font_size_override("font_size", 12)
	icon.text = "✅" if completed else ("📖" if progress else ("🔒" if not unlocked else "🆕"))
	row1.add_child(icon)

	# Row 2 — title (expands vertically to push button down)
	var title = Label.new()
	title.text = ch.title
	title.add_theme_font_size_override("font_size", 14)
	title.autowrap_mode      = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	col.add_child(title)

	# Row 3 — sub status
	var sub = Label.new()
	sub.add_theme_font_size_override("font_size", 10)
	if completed:
		sub.text = "Completed"
	elif progress:
		sub.text = "In progress"
	elif not unlocked:
		sub.text = "🪙 %d coins" % unlock_cost
	else:
		sub.text = "Ready"
	col.add_child(sub)

	# Row 4 — full-width action button
	var btn = Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size.y = BTN_H
	if unlocked:
		btn.text = ("↩  Reread" if completed else ("▶  Continue" if progress else "▶  Read"))
		btn.pressed.connect(SceneManager.go_to_chapter.bind(ch.num))
	else:
		btn.text    = "🔓  Unlock"
		btn.disabled = GameData.data.coins < unlock_cost
		if btn.disabled:
			btn.tooltip_text = "Need %d more 🪙" % (unlock_cost - GameData.data.coins)
		btn.pressed.connect(_on_unlock.bind(ch))
	col.add_child(btn)

	return card


# ══════════════════════════════════════════════════════════════
#  UNLOCK
# ══════════════════════════════════════════════════════════════
func _on_unlock(ch: Dictionary):
	var unlock_cost := ChapterData.get_unlock_cost(ch.num)
	if GameData.spend_coins(unlock_cost):
		GameData.unlock_chapter(ch.num)
		_populate()
		_toast_show("🔓 Chapter %d unlocked!" % ch.num)
	else:
		_toast_show("Need %d more 🪙 to unlock" % (unlock_cost - GameData.data.coins))


# ══════════════════════════════════════════════════════════════
#  TOAST
# ══════════════════════════════════════════════════════════════
func _toast_show(msg: String):
	_toast_lbl.text = msg
	_toast.show()
	if _toast_tw: _toast_tw.kill()
	_toast.modulate.a = 0.0
	_toast_tw = create_tween()
	_toast_tw.tween_property(_toast, "modulate:a", 1.0, 0.18)
	_toast_tw.tween_interval(2.2)
	_toast_tw.tween_property(_toast, "modulate:a", 0.0, 0.35)
	_toast_tw.tween_callback(_toast.hide)
