class_name ChapterData
extends Node


enum PanelType { STATIC, PLAYABLE }

const PANEL_WIDTH = 720.0

const PROTO_LEVEL = "res://Scenes/Environments/Proto_Levels/proto_level.tscn"

# ── PAGE COUNTS (real asset counts) ──────────────────────────────────────────
const CHAPTER_PAGE_COUNTS = {
	1: 85,
	2: 156,
	3: 120,
	4: 100,
	5: 125,
	6: 150,
	7: 107,
	8: 127,
}

# ── CHAPTER UNLOCK COSTS ──────────────────────────────────────────────────────
const CHAPTER_UNLOCK_COSTS = {
	1: 0,
	2: 50,
	3: 100,
	4: 150,
	5: 200,
	6: 250,
	7: 300,
	8: 350,
}

const CHAPTER_CONFIG_PATHS = {
	1: "res://Resources/Levels/chapter_01_config.tres",
	2: "res://Resources/Levels/chapter_02_config.tres",
	3: "res://Resources/Levels/chapter_03_config.tres",
	4: "res://Resources/Levels/chapter_04_config.tres",
	5: "res://Resources/Levels/chapter_05_config.tres",
	6: "res://Resources/Levels/chapter_06_config.tres",
	7: "res://Resources/Levels/chapter_07_config.tres",
	8: "res://Resources/Levels/chapter_08_config.tres",
}

static func get_config(chapter: int) -> ChapterConfig:
	var path := String(CHAPTER_CONFIG_PATHS.get(chapter, ""))
	if path.is_empty():
		return null
	return ResourceLoader.load(path) as ChapterConfig

static func get_unlock_cost(chapter: int) -> int:
	var config := get_config(chapter)
	if config:
		return config.unlock_cost
	return CHAPTER_UNLOCK_COSTS.get(chapter, (chapter - 1) * 50)


# ── PANEL ENTRY ───────────────────────────────────────────────────────────────
class PanelEntry:
	var type:             int
	var image_path:       String
	var playable_scene:   String
	var transition_text:  String
	var game_index:       int
	var coins_reward:     int

	func _init(t, img = "", scene = "", text = "", idx = 0, coins = 0):
		type            = t
		image_path      = img
		playable_scene  = scene
		transition_text = text
		game_index      = idx
		coins_reward    = coins


# ── MAIN ENTRY POINT ──────────────────────────────────────────────────────────
static func get_chapter(num: int) -> Array:
	var panels: Array = []

	var config := get_config(num)
	if config == null:
		push_error("ChapterData: Chapter %d page count not set!" % num)
		return panels

	var page_count    = config.page_count
	var playable_defs = ChapterData.get_playable_definitions(num)

	for page in range(1, page_count + 1):
		for pd in playable_defs:
			if pd.before_page == page:
				panels.append(PanelEntry.new(
					PanelType.PLAYABLE, "",
					pd.get("scene", PROTO_LEVEL),
					pd.text, pd.game_index, pd.coins_reward
				))
		var path = ChapterData.get_page_path(num, page)
		if path != "":
			panels.append(PanelEntry.new(PanelType.STATIC, path))

	# Triggers with before_page > page_count appended at the very end
	for pd in playable_defs:
		if pd.before_page > page_count:
			panels.append(PanelEntry.new(
				PanelType.PLAYABLE, "",
				pd.get("scene", PROTO_LEVEL),
				pd.text, pd.game_index, pd.coins_reward
			))

	return panels


# ── IMAGE PATH RESOLVER ───────────────────────────────────────────────────────
# ── IMAGE PATH RESOLVER ───────────────────────────────────────────────────────
static func get_page_path(chapter: int, page: int) -> String:
	var page_str = str(page - 1).pad_zeros(2)
	var base = ""
	match chapter:
		1: base = "res://Assets/webtoon/ch1/" + page_str
		2: base = "res://Assets/webtoon/ch2/" + page_str
		3: base = "res://Assets/webtoon/ch3/" + page_str
		4: base = "res://Assets/webtoon/ch4/" + page_str
		5: base = "res://Assets/webtoon/ch5/" + page_str
		6: base = "res://Assets/webtoon/ch6/" + page_str
		7: base = "res://Assets/webtoon/ch7/" + page_str
		8: base = "res://Assets/webtoon/ch8/" + page_str
		_:
			push_error("ChapterData: No path pattern for chapter %d" % chapter)
			return ""

	if ResourceLoader.exists(base + ".jpg"):
		return base + ".jpg"
	elif ResourceLoader.exists(base + ".png"):
		return base + ".png"	
	elif ResourceLoader.exists(base + ".webp"):
		return base + ".webp"
	else:
		# Webtoon folder intentionally missing during segment-only testing —
		# skip silently instead of erroring.
		return ""


# ── CONVENIENCE HELPERS ───────────────────────────────────────────────────────
static func get_total_games(chapter: int) -> int:
	return get_playable_definitions(chapter).size()

static func get_total_chapters() -> int:
	return CHAPTER_PAGE_COUNTS.size()


# ─────────────────────────────────────────────────────────────────────────────
#  GAME SEGMENT DEFINITIONS  —  Chapters 1–8
#
#  Each entry:
#    before_page   → trigger panel inserted just BEFORE this real page number
#    text          → narrative teaser shown on the PlayableTriggerPanel
#    game_index    → 0-based index within the chapter (save key)
#    coins_reward  → coins awarded on FIRST successful completion only
#    scene         → scene path for this segment (swap out PROTO_LEVEL when ready)
# ─────────────────────────────────────────────────────────────────────────────
static func get_playable_definitions(chapter: int) -> Array:
	var config := get_config(chapter)
	if config:
		var definitions: Array = []
		for segment in config.segments:
			definitions.append({
				"before_page": segment.before_page,
				"text": segment.transition_text,
				"game_index": segment.game_index,
				"coins_reward": segment.coins_reward,
				"scene": segment.scene_path,
			})
		return definitions

	# Legacy fallback for an absent or malformed chapter config.
	match chapter:

		# ══════════════════════════════════════════════════════════════════════
		# CHAPTER 1  |  2 segments  |  19 real pages
		#
		# Story beats:
		#   Pages  1–6   CT sneaks through bush maze, grabs coins, dodges skulls
		#   Pages  7–12  CT spots treasure chest, climbs tower, sees rival
		#   Pages 13–15  CT races through bush maze toward chest
		#   Pages 16–17  CT bursts chest open — glowing suit, not coins
		#   Pages 18–19  Big Boss furious, jumps from castle window
		# ══════════════════════════════════════════════════════════════════════
		1: return [
			{
				# Type      : Light platforming, coin collecting, slow skull patrol
				# Character : CT
				# NPCs      : Skull enemies (fixed patrol, contact damage)
				# Level     : Hedge maze — narrow corridors, small jumps
				#             25–35 coins along safe routes
				# Win       : Collect 20 coins OR reach maze exit
				# Difficulty: Very low — onboarding / movement tutorial
				"before_page":  15,
				"text":         "Time to grab those coins before anyone notices...",
				"game_index":   0,
				"coins_reward": 30,
				"scene":        PROTO_LEVEL, # TODO: replace with hedge maze scene
			},
			{
				# Type      : Timed chase, obstacle dodging, enemy combat
				# Character : CT  |  Rival as background silhouette
				# NPCs      : Faster skulls, 1 Elite Skull blocking path
				# Level     : Bush maze reconfigured — falling hedges, moving skulls,
				#             elevated platforms, 60-second timer pressure
				# Win       : Reach glowing chest marker OR survive 60 seconds
				# Difficulty: Medium spike — urgency and required combat
				"before_page":  48,
				"text":         "Those coins are MINE — gotta beat him there!",
				"game_index":   1,
				"coins_reward": 30,
				"scene":        PROTO_LEVEL, # TODO: replace with timed chase scene
			},
		]

		# ══════════════════════════════════════════════════════════════════════
		# CHAPTER 2  |  3 segments  |  34 real pages
		#
		# Story beats:
		#   Pages  1–5   World goes online — shadow avatars flood in, title page
		#   Pages  6–10  Big Boss jumps castle, attacks CT with sword slashes
		#   Pages 11–15  CT cornered; Big Boss full attack; big clash
		#   Pages 16–19  Sigih (Pink Girl) appears with shield, blocks Big Boss
		#   Pages 20–34  Sigih vs Big Boss full battle — Sigih KOs Big Boss
		# ══════════════════════════════════════════════════════════════════════
		2: return [
			{
				# Type      : Coin collecting + obstacle dodging (chaotic open map)
				# Character : CT
				# NPCs      : Shadow Avatars — spawn flash 2 sec before, shockwave
				#             on land, 40 coins scattered, despawn after 8 sec
				# Win       : Collect 30 coins, avoid 5 collision bursts
				# Difficulty: Low-medium — controlled chaos, no direct combat
				#"before_page":  6,
				#"text":         "New players flooding in... better grab what I can before it gets crazy!",
				#"game_index":   0,
				#"coins_reward": 35,
				#"scene":        PROTO_LEVEL, # TODO: replace with shadow avatar arena scene
			#},
			#{
				# Type      : Pure survival — dodge Big Boss sword slashes + shockwaves
				# Character : CT
				# NPCs      : Big Boss (non-killable) — horizontal slash + ground slam,
				#             all attacks telegraphed 0.8 sec before impact
				# Level     : Circular arena, 90-second survival timer
				# Win       : Survive full duration — no coins (pure tension)
				# Difficulty: Medium — dodge timing and pattern recognition
				"before_page":  24,
				"text":         "Big Boss is coming — MOVE!",
				"game_index":   0,
				"coins_reward": 35,
				"scene":        PROTO_LEVEL, # TODO: replace with circular arena scene
			},
			{
				# Type      : Wave defense — fight skull reinforcements in 3 waves
				# Character : CT
				# NPCs      : Skull reinforcements — 3 escalating waves
				# Background: Sigih vs Big Boss fight animation
				# Level     : Side corridor — stop skulls reaching the main arena
				# Win       : Clear all 3 waves
				# Difficulty: Medium — wave management, increasing enemy pressure
				"before_page":  95,
				"text":         "She's holding her own... but Big Boss has one more trick!",
				"game_index":   2,
				"coins_reward": 35,
				"scene":        PROTO_LEVEL, # TODO: replace with wave defense corridor scene
			},
		]

		# ══════════════════════════════════════════════════════════════════════
		# CHAPTER 3  |  2 segments  |  22 real pages
		#
		# Story beats:
		#   Pages  1–4   Alex & Felix flying machine; Felix ejected into forest
		#   Pages  5–8   Sigih meets CT, offers training, leaves via portal
		#   Pages  9–13  CT daydreams; Horn ambush; Sword warns; CT falls off cliff
		#   Pages 14–18  CT lands on Felix — funny first meeting, banter
		#   Pages 19–22  CT & Felix walk forest; Felix gives map; they bond
		# ══════════════════════════════════════════════════════════════════════
		3: return [
			{
				# Type      : Obstacle dodging + enemy combat (narrow cliff platforms)
				# Character : CT
				# NPCs      : Horn (non-killable, charge attack, knockback)
				#             Skull enemies (minor support)
				# Mechanic  : Hit near edge → forced fall, scripted segment end
				# Win       : Survive 60 seconds OR get knocked off cliff (scripted)
				# Difficulty: Medium — spatial awareness, Horn charge timing
				"before_page":  61,
				"text":         "Better snap out of it... something doesn't feel right.",
				"game_index":   0,
				"coins_reward": 35,
				"scene":        PROTO_LEVEL, # TODO: replace with cliff platform scene
			},
			{
				# Type      : Exploration + coin collecting (new forest biome)
				# Character : CT  |  Felix (AI companion — follows, idle comments)
				# NPCs      : Light forest enemies (minimal)
				# Level     : Open forest — hidden coin clusters, 50 total coins
				# Win       : Collect 35 coins
				# Difficulty: Very low — relaxed, matches CT & Felix bonding tone
				"before_page":  120,
				"text":         "Alright Flex, lead the way — but watch out for what's in these woods!",
				"game_index":   1,
				"coins_reward": 35,
				"scene":        PROTO_LEVEL, # TODO: replace with open forest scene
			},
		]

		# ══════════════════════════════════════════════════════════════════════
		# CHAPTER 4  |  2 segments  |  18 real pages
		#
		# Story beats:
		#   Pages  1–4   Horn dives after CT; Sword follows via stairs
		#   Pages  5–6   Title page + forest establishing shot
		#   Pages  7–12  CT & Flex run through Barreldugo territory; Flex teaches
		#                combat type system (Tank / Speed / Projectile)
		#   Pages 13–15  Flex tames Barreldugo; they ride toward the flying ship
		#   Pages 16–17  Alex arrives chased by armored beasts; Queen descends
		#   Page  18     Credits + bonus Horn gag
		# ══════════════════════════════════════════════════════════════════════
		4: return [
			#{
				## Type      : Auto-scrolling chase (left-to-right) + obstacle dodging
				## Character : CT  |  Felix (runs alongside)
				## NPCs      : Projectile enemies, Horn in background
				## Level     : Auto-scroll forest — tree trunks, falling logs, restart if caught
				## Win       : Reach end of auto-scroll without being caught
				## Difficulty: Medium — reaction timing, varied obstacles
				#"before_page":  7,
				#"text":         "Horn is somewhere in these woods... keep moving!",
				#"game_index":   0,
				#"coins_reward": 40,
				#"scene":        PROTO_LEVEL, # TODO: replace with auto-scroll forest scene
			#},
			{
				# Type      : Enemy combat + puzzle (apply type-weakness system)
				# Character : CT  |  Felix (combat advisor)
				# Enemies   : Tank type (slow, high HP)
				#             Speed type (fast, low HP)
				#             Barreldugo / Projectile type (close-range weakness)
				# Win       : Defeat all 3 enemy types
				# Difficulty: Medium — must exploit type weaknesses
				"before_page":  34,
				"text":         "A Barreldugo! Flex says get close — let's try it!",
				"game_index":   0,
				"coins_reward": 40,
				"scene":        PROTO_LEVEL, # TODO: replace with type-weakness combat scene
			},
		]

		# ══════════════════════════════════════════════════════════════════════
		# CHAPTER 5  |  2 segments  |  24 real pages
		#
		# Story beats:
		#   Pages  1–6   Queen intercepts armored bulls chasing Alex; bulls retreat
		#   Pages  7–8   Ship traveling; crew reunites on deck
		#   Pages  9–14  CT meets Lala; she analyzes CT's suit and the Queen
		#   Pages 15–20  Lala explains Queen's powers + CT's rare suit in depth
		#   Pages 21–24  Sacavuelo challenges Alex to a duel; everyone gathers
		# ══════════════════════════════════════════════════════════════════════
		5: return [
			{
				# Type      : Obstacle dodging + enemy combat
				# Character : CT (ground level watching chaos)
				# Background: Queen fighting main bull boss, Alex present
				# NPCs      : Charging Bulls — straight-line charge, turn on collision
				# Win       : Survive 4 bull charges + defeat 2 minor bulls
				# Difficulty: Medium — dodge timing, direction prediction
				"before_page":  1,
				"text":         "The Queen stepped in — but those bulls aren't done yet!",
				"game_index":   0,
				"coins_reward": 40,
				"scene":        PROTO_LEVEL, # TODO: replace with bull charge arena scene
			},
			{
				# Type      : Enemy combat + coin collecting (warm-up before duel)
				# Character : CT
				# Present   : Alex, Felix, Lala on deck, crowd hyped
				# NPCs      : Flying ship creatures — 2 waves, light projectile hazards
				# Win       : Collect 25 coins + clear 2 enemy waves
				# Difficulty: Low-medium — energy booster before Chapter 6
				"before_page":  117,
				"text":         "Alex accepted the duel... somebody's gotta warm up for him!",
				"game_index":   1,
				"coins_reward": 40,
				"scene":        PROTO_LEVEL, # TODO: replace with ship deck combat scene
			},
		]

		# ══════════════════════════════════════════════════════════════════════
		# CHAPTER 6  |  2 segments  |  26 real pages
		#
		# Story beats:
		#   Pages  1–5   Big Boss recovers; rages; vows revenge
		#   Pages  6–12  Duel begins; Big Bird goes boomerang; Alex uses shield
		#   Pages 13–19  Alex's bow shot overshoots crowd; Queen blasts it
		#   Pages 20–25  Big Bird flanks shield, hits Alex; Alex on one knee
		#   Page  26     Alex draws batons — fierce comeback cliffhanger
		# ══════════════════════════════════════════════════════════════════════
		6: return [
			{
				# Type      : Obstacle dodging + enemy combat (close-range boss fight)
				# Character : ALEX  ← plays as Alex, not CT — unique segment
				# NPCs      : Big Bird (boss) — boomerang projectile tracking,
				#             shield-break mechanic
				# Mechanic  : Must close distance to deal damage; shield pickup;
				#             projectile pressure increases if too slow
				# Background: Queen observing, CT & Lala doing commentary
				# Win       : Land 5 close-range hits on Big Bird
				# Difficulty: Medium-hard — tracking projectiles + positioning
				"before_page":  12,
				"text":         "Big Bird went straight for projectiles — dodge and get close!",
				"game_index":   0,
				"coins_reward": 45,
				"scene":        PROTO_LEVEL, # TODO: replace with Big Bird boss fight scene
			},
			{
				# Type      : Coin collecting + obstacle dodging (emotional low point)
				# Character : CT (crowd area, frantic scavenge)
				# Present   : Alex (on one knee, injured)
				# Hazards   : Falling debris, heavy boomerang projectile arcs
				# Win       : Survive 60 seconds + collect 20 coins
				# Difficulty: Medium — multi-hazard dodge while collecting
				"before_page":  26,
				"text":         "Alex is on one knee... he's not done yet. Neither are we!",
				"game_index":   1,
				"coins_reward": 45,
				"scene":        PROTO_LEVEL, # TODO: replace with debris dodge scene
			},
		]

		# ══════════════════════════════════════════════════════════════════════
		# CHAPTER 7  |  2 segments  |  18 real pages
		#
		# Story beats:
		#   Pages  1–6   Alex baton comeback; combos Big Bird; wins; crowd wild
		#   Pages  7–10  Night; Alex & Flex sell items; CT realizes items = coins
		#   Pages 11–13  Alex demos Doodaboom; rocket backfires, hits ship
		#   Pages 14–16  Ship tilting; everyone holding poles for dear life
		#   Pages 17–18  Queen levitates; orders guards; emergency landing attempt
		# ══════════════════════════════════════════════════════════════════════
		7: return [
			{
				# Type      : Coin collecting + exploration (celebratory rush)
				# Character : CT
				# Present   : Alex & Felix selling items on ship deck at night
				# NPCs      : Crowd (coin drop effect only — no combat)
				# Level     : Ship deck, coins raining from sky + crowd drops
				# Win       : Collect 40 coins
				# Difficulty: Very low — joyful reward after duel victory
				"before_page":  6,
				"text":         "Alex won! Now the coins are flowing — grab what you can!",
				"game_index":   0,
				"coins_reward": 45,
				"scene":        PROTO_LEVEL, # TODO: replace with ship deck celebration scene
			},
			{
				# Type      : Obstacle dodging + puzzle (tilting ship survival)
				# Character : CT
				# Background: Queen performing emergency rescue
				# Mechanics : Slanted deck physics — sliding crates, moving platforms,
				#             hold-to-grab poles, reach top deck safety zone
				# NPCs      : Physics obstacles only — no enemies
				# Win       : Reach safety zone at top deck
				# Difficulty: Medium-high — spatial orientation + moving hazards
				"before_page":  13,
				"text":         "The ship is going DOWN — hold on and get to safety!",
				"game_index":   1,
				"coins_reward": 45,
				"scene":        PROTO_LEVEL, # TODO: replace with tilting ship scene
			},
		]

		# ══════════════════════════════════════════════════════════════════════
		# CHAPTER 8  |  3 segments  |  26 real pages
		#
		# Story beats:
		#   Pages  1–7   Diskoreck cold open — extorts desert town, rides off
		#   Pages  8–10  Ship crash-lands; Queen exhausted; Flex & Alex bolt
		#   Pages 11–16  Queen furious; Lala explains Sand Land + Ahrena
		#   Pages 17–20  Mayor offers coin bag; CT signs contract without reading
		#   Pages 21–24  CT realizes the trap; ring can't be removed (explodes)
		#   Pages 25–26  CT stewing; massive sand wormfish charges toward town
		# ══════════════════════════════════════════════════════════════════════
		8: return [
			{
				# Type      : Exploration + coin collecting (new desert biome intro)
				# Character : CT  |  No active characters present
				# Mechanics : Sand slows movement; collapsing ruins; hidden coin piles
				# Win       : Explore 60% of map + collect 30 coins
				# Difficulty: Low — environment focus, biome introduction
				"before_page":  8,
				"text":         "Welcome to Sand Land... and it does NOT look friendly.",
				"game_index":   0,
				"coins_reward": 50,
				"scene":        PROTO_LEVEL, # TODO: replace with desert exploration scene
			},
			{
				# Type      : Coin collecting + obstacle dodging (frantic scramble)
				# Character : CT
				# Present   : Mayor (cutscene only), Lala (non-playable, mouth sealed)
				# Hazards   : Quicksand pits, projectile collapsing ruins, sand traps
				# Win       : Reach mayor's coin bag + collect 25 coins
				# Difficulty: Medium — multi-trap awareness, fast pacing
				"before_page":  21,
				"text":         "I signed WHAT?! Gotta do something — find those coins first!",
				"game_index":   1,
				"coins_reward": 50,
				"scene":        PROTO_LEVEL, # TODO: replace with quicksand trap scene
			},
			{
				# Type      : Chase + obstacle dodging (pure panic sprint)
				# Character : CT
				# NPCs      : Sand Wormfish (chase AI — erupts from sand behind player)
				# Level     : Auto-scrolling desert — falling rocks, worm eruptions
				# Win       : Survive the full chase sequence — no combat
				# Difficulty: Medium-high — pure reaction sprint
				"before_page":  26,
				"text":         "A sand wormfish?! Everyone scatter!",
				"game_index":   2,
				"coins_reward": 50,
				"scene":        PROTO_LEVEL, # TODO: replace with wormfish chase scene
			},
		]

		_: return []
