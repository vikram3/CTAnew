# AchievementManager.gd — Autoload  (res://Scripts/AchievementManager.gd)
#
#  All achievements are triggered exclusively from game segment events:
#
#    first_game      → player launches their first segment (tap to play)
#    survivor        → player completes a segment without pressing Back to Story
#    coin_30         → total coins earned from segments reaches 30
#    coin_150        → total coins earned from segments reaches 150
#    coin_500        → total coins earned from segments reaches 500
#    ch1_clear       → all game segments in Chapter 1 completed
#    ch2_clear       → all game segments in Chapter 2 completed
#    speedrun        → a segment completed under 60 seconds
#    half_way        → all segments in Chapters 1–4 completed
#    completionist   → all 20 segments in Chapters 1–8 completed
#
#  HOW TO TRIGGER (call from WebtoonReader after segment events):
#    AchievementManager.on_segment_played(chapter, game_index)
#    AchievementManager.on_segment_completed(chapter, game_index, time_taken_sec)
#    AchievementManager.on_coins_changed()          ← after any coin award
extends Node

# ─────────────────────────────────────────────────────────────────────────────
#  ACHIEVEMENT DEFINITIONS
# ─────────────────────────────────────────────────────────────────────────────
const ACHIEVEMENTS = {
	"first_game": {
		"title": "Game On!",
		"desc":  "Launched your first game segment",
		"icon":  "🎮"
	},
	"survivor": {
		"title": "No Retreat!",
		"desc":  "Completed a segment without pressing Back to Story",
		"icon":  "🛡️"
	},
	"coin_30": {
		"title": "Coin Collector",
		"desc":  "Earned 30 coins from game segments",
		"icon":  "🪙"
	},
	"coin_150": {
		"title": "Coin Hoarder",
		"desc":  "Earned 150 coins from game segments",
		"icon":  "💰"
	},
	"coin_500": {
		"title": "Troll Treasury",
		"desc":  "Earned 500 coins from game segments",
		"icon":  "🏦"
	},
	"ch1_clear": {
		"title": "Chapter 1 Clear!",
		"desc":  "Completed all game segments in Chapter 1",
		"icon":  "⭐"
	},
	"ch2_clear": {
		"title": "Chapter 2 Clear!",
		"desc":  "Completed all game segments in Chapter 2",
		"icon":  "🌟"
	},
	"speedrun": {
		"title": "Speed Troll",
		"desc":  "Completed a segment in under 60 seconds",
		"icon":  "⚡"
	},
	"half_way": {
		"title": "Half Way There!",
		"desc":  "Completed all segments in Chapters 1 through 4",
		"icon":  "🔥"
	},
	"completionist": {
		"title": "True Troll!",
		"desc":  "Completed every game segment in Chapters 1–8",
		"icon":  "👑"
	},
}

# ─────────────────────────────────────────────────────────────────────────────
#  SEGMENT COUNTS  (must match ChapterData segment definitions)
# ─────────────────────────────────────────────────────────────────────────────
const SEGMENTS_PER_CHAPTER = {
	1: 2,
	2: 3,
	3: 2,
	4: 2,
	5: 2,
	6: 2,
	7: 2,
	8: 3,
}
const TOTAL_M1_SEGMENTS = 18   # Chapters 1–8 combined (2+3+2+2+2+2+2+3)

# ─────────────────────────────────────────────────────────────────────────────
#  POPUP QUEUE
# ─────────────────────────────────────────────────────────────────────────────
var popup_queue: Array  = []
var is_showing:  bool   = false


# ─────────────────────────────────────────────────────────────────────────────
#  PUBLIC TRIGGER API  —  called from WebtoonReader
# ─────────────────────────────────────────────────────────────────────────────

## Call immediately when the player taps TAP TO PLAY on any segment.
func on_segment_played(_chapter: int, _game_index: int):
	# first_game — fires once, on the very first segment launch ever
	_check("first_game", not GameData.has_achievement("first_game"))


## Call after a successful segment completion (player reached ExitZone).
## time_taken_sec is how long the player spent in the level (0 if unknown).
func on_segment_completed(chapter: int, game_index: int, time_taken_sec: float = 0.0):
	# survivor — completed without pressing Back to Story (success path always qualifies)
	_check("survivor", true)

	# speedrun — under 60 seconds
	if time_taken_sec > 0.0:
		_check("speedrun", time_taken_sec < 60.0)

	# chapter clears
	_check_chapter_clear(chapter)

	# half_way — all segments in Ch 1–4 done
	var half_done = true
	for ch in [1, 2, 3, 4]:
		if GameData.get_completed_games_count(ch) < SEGMENTS_PER_CHAPTER.get(ch, 999):
			half_done = false
			break
	_check("half_way", half_done)

	# completionist — all M1 segments done
	var total_done = 0
	for ch in SEGMENTS_PER_CHAPTER.keys():
		total_done += GameData.get_completed_games_count(ch)
	_check("completionist", total_done >= TOTAL_M1_SEGMENTS)


## Call after GameData.add_coins() or record_segment_completed() updates coins.
func on_coins_changed():
	var coins = GameData.get_total_coins_earned_from_segments()
	_check("coin_30",  coins >= 30)
	_check("coin_150", coins >= 150)
	_check("coin_500", coins >= 500)


# ─────────────────────────────────────────────────────────────────────────────
#  INTERNAL
# ─────────────────────────────────────────────────────────────────────────────
func _check_chapter_clear(chapter: int):
	var ach_id = "ch%d_clear" % chapter
	if not ACHIEVEMENTS.has(ach_id):
		return
	var needed = SEGMENTS_PER_CHAPTER.get(chapter, 0)
	_check(ach_id, GameData.get_completed_games_count(chapter) >= needed)


## Core unlock check — fires popup only if the achievement was newly unlocked.
func _check(id: String, condition: bool):
	if not condition:
		return
	if not ACHIEVEMENTS.has(id):
		push_warning("AchievementManager: unknown id '%s'" % id)
		return
	if GameData.unlock_achievement(id):
		popup_queue.append(id)
		if not is_showing:
			_show_next_popup()


func _show_next_popup():
	if popup_queue.is_empty():
		is_showing = false
		return

	is_showing  = true
	var id      = popup_queue.pop_front()
	var ach     = ACHIEVEMENTS[id]

	var popup   = preload("res://Scenes/UI/achievement_popup.tscn").instantiate()
	get_tree().root.add_child(popup)
	popup.show_achievement(ach.icon, ach.title, ach.desc)

	await get_tree().create_timer(3.8).timeout
	_show_next_popup()
