extends Node

# ─────────────────────────────────────────────────────────────────────────────
#  GameData.gd  —  Autoload  (res://Scripts/GameData.gd)
#
#  Stores all persistent player state:
#    • coins, unlocked chapters, scroll positions
#    • per-segment play/complete timestamps and coins earned
#    • achievements
#    • settings
#
#  Segment tracking schema  (stored under "segment_data"):
#    key  =  "<chapter>_<game_index>"   e.g. "3_1"
#    value = {
#        "played_at":    "<ISO-like timestamp string>",   # first time TAP TO PLAY was pressed
#        "completed_at": "<ISO-like timestamp string>",   # first time ExitZone reached (or "" if skipped)
#        "play_count":   <int>,                           # total times launched (skips + completions)
#        "complete_count": <int>,                         # total times reached ExitZone
#        "coins_earned": <int>                            # coins awarded on first completion
#    }
# ─────────────────────────────────────────────────────────────────────────────

const SAVE_PATH = "user://save_data.json"

var data = {
	"coins":                    0,
	"current_chapter":          1,
	"unlocked_chapters":        [1],
	"chapter_progress":         {},   # str(chapter) -> scroll float
	"chapter_games_completed":  {},   # str(chapter) -> [game_index, ...]
	"chapters_fully_completed": [],   # [chapter_num, ...]
	"segment_data":             {},   # "<ch>_<gi>" -> segment record (see above)
	"achievements":             {},   # achievement_id -> true
	"settings": {
		"music_volume": 1.0,
		"sfx_volume":   1.0,
	}
}

func _ready():
	load_data()


# ─────────────────────────────────────────────────────────────────────────────
#  SAVE / LOAD
# ─────────────────────────────────────────────────────────────────────────────
func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("GameData: Cannot open save file for writing.")
		return
	file.store_string(JSON.stringify(data))
	file.close()

func save_chapter_zoom(chapter: int, zoom: float):
	data["zoom_ch_" + str(chapter)] = zoom
	save_data()

func get_chapter_zoom(chapter: int) -> float:
	return data.get("zoom_ch_" + str(chapter), 0.0)  # 0.0 = no saved zoom

func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		save_data()
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("GameData: Cannot open save file for reading.")
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		# Deep-merge so any new keys added in code are never clobbered
		_deep_merge(data, parsed)

# Recursively merge src into dst — dst keys win for non-Dict values.
func _deep_merge(dst: Dictionary, src: Dictionary):
	for k in src.keys():
		if dst.has(k) and dst[k] is Dictionary and src[k] is Dictionary:
			_deep_merge(dst[k], src[k])
		else:
			dst[k] = src[k]


# ─────────────────────────────────────────────────────────────────────────────
#  COINS
# ─────────────────────────────────────────────────────────────────────────────
func add_coins(amount: int):
	data.coins += amount
	save_data()

func spend_coins(amount: int) -> bool:
	if data.coins >= amount:
		data.coins -= amount
		save_data()
		return true
	return false


# ─────────────────────────────────────────────────────────────────────────────
#  CHAPTER UNLOCK
# ─────────────────────────────────────────────────────────────────────────────
func unlock_chapter(num: int):
	if num not in data.unlocked_chapters:
		data.unlocked_chapters.append(num)
		save_data()

func is_chapter_unlocked(num: int) -> bool:
	return num in data.unlocked_chapters

func is_chapter_fully_completed(num: int) -> bool:
	return num in data.chapters_fully_completed


# ─────────────────────────────────────────────────────────────────────────────
#  SCROLL PROGRESS
# ─────────────────────────────────────────────────────────────────────────────
func save_chapter_progress(chapter: int, scroll_pos: float):
	data.chapter_progress[str(chapter)] = scroll_pos
	save_data()

func get_chapter_progress(chapter: int) -> float:
	return float(data.chapter_progress.get(str(chapter), 0.0))


# ─────────────────────────────────────────────────────────────────────────────
#  SEGMENT DATA  —  internal helper
# ─────────────────────────────────────────────────────────────────────────────
func _segment_key(chapter: int, game_index: int) -> String:
	return str(chapter) + "_" + str(game_index)

func _ensure_segment(key: String) -> Dictionary:
	if not data.segment_data.has(key):
		data.segment_data[key] = {
			"played_at":      "",
			"completed_at":   "",
			"play_count":     0,
			"complete_count": 0,
			"coins_earned":   0
		}
	return data.segment_data[key]

## Returns a human-readable UTC-like timestamp string.
func _now_string() -> String:
	var t = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		t.year, t.month, t.day, t.hour, t.minute, t.second
	]


# ─────────────────────────────────────────────────────────────────────────────
#  SEGMENT TRACKING  —  public API
# ─────────────────────────────────────────────────────────────────────────────

## Call this the moment the player taps TAP TO PLAY (before game loads).
func record_segment_played(chapter: int, game_index: int):
	var key = _segment_key(chapter, game_index)
	var seg = _ensure_segment(key)
	seg.play_count += 1
	if seg.played_at == "":
		seg.played_at = _now_string()
	data.segment_data[key] = seg
	save_data()

## Call this when the player reaches ExitZone (success == true).
## Returns how many coins were awarded (0 if already completed before).
func record_segment_completed(chapter: int, game_index: int, coins_reward: int) -> int:
	var key         = _segment_key(chapter, game_index)
	var seg         = _ensure_segment(key)
	var first_time  = (seg.completed_at == "")

	seg.complete_count += 1
	if first_time:
		seg.completed_at = _now_string()
		seg.coins_earned  = coins_reward
		data.coins        += coins_reward      # add directly so one save covers everything

	data.segment_data[key] = seg

	# Also mark in the legacy completed list so is_game_completed() still works
	var ch_key = str(chapter)
	if not data.chapter_games_completed.has(ch_key):
		data.chapter_games_completed[ch_key] = []
	if game_index not in data.chapter_games_completed[ch_key]:
		data.chapter_games_completed[ch_key].append(game_index)

	save_data()
	return coins_reward if first_time else 0


## True if the player has ever reached ExitZone for this segment.
func is_game_completed(chapter: int, game_index: int) -> bool:
	var key = _segment_key(chapter, game_index)
	if not data.segment_data.has(key):
		return false
	return data.segment_data[key].completed_at != ""

## True if the player has ever launched this segment (even if they skipped).
func is_game_played(chapter: int, game_index: int) -> bool:
	var key = _segment_key(chapter, game_index)
	if not data.segment_data.has(key):
		return false
	return data.segment_data[key].play_count > 0

## Returns the full segment record dict, or empty dict if never touched.
func get_segment_data(chapter: int, game_index: int) -> Dictionary:
	var key = _segment_key(chapter, game_index)
	if data.segment_data.has(key):
		return data.segment_data[key].duplicate()
	return {}

## How many segments in this chapter have been completed.
func get_completed_games_count(chapter: int) -> int:
	var ch_key = str(chapter)
	if not data.chapter_games_completed.has(ch_key):
		return 0
	return data.chapter_games_completed[ch_key].size()

## Total coins earned across all segments (informational).
func get_total_coins_earned_from_segments() -> int:
	var total = 0
	for key in data.segment_data.keys():
		total += int(data.segment_data[key].get("coins_earned", 0))
	return total


# ─────────────────────────────────────────────────────────────────────────────
#  CHAPTER COMPLETION
# ─────────────────────────────────────────────────────────────────────────────

## Returns true if the chapter was *newly* completed by this call.
func check_chapter_complete(chapter: int, total_games: int) -> bool:
	if get_completed_games_count(chapter) >= total_games:
		if chapter not in data.chapters_fully_completed:
			data.chapters_fully_completed.append(chapter)
			unlock_chapter(chapter + 1)
			save_data()
			return true
	return false


# ─────────────────────────────────────────────────────────────────────────────
#  ACHIEVEMENTS
# ─────────────────────────────────────────────────────────────────────────────
func unlock_achievement(id: String) -> bool:
	if not data.achievements.get(id, false):
		data.achievements[id] = true
		save_data()
		return true
	return false

func has_achievement(id: String) -> bool:
	return data.achievements.get(id, false)
