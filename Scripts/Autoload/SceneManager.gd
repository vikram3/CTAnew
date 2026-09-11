extends Node

func go_to_title() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/TitleScreen.tscn")

func go_to_chapter_select() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/chapter_select.tscn")

func go_to_chapter(num: int) -> void:
	GameData.data.current_chapter = num
	GameData.save_data()
	get_tree().change_scene_to_file("res://Scenes/UI/WebtoonReader.tscn")

func go_to_settings() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/settings_screen.tscn")


## The only public entry point from story UI into a gameplay segment.
func start_gameplay_segment(scene_path: String, reader: Node) -> void:
	if not is_gameplay_segment_available(scene_path):
		push_error("SceneManager: gameplay segment scene is unavailable: %s" % scene_path)
		if reader and reader.has_method("restore_scroll_only"):
			reader.restore_scroll_only()
		return
	TransitionManager.start_game_segment(scene_path, reader)


func is_gameplay_segment_available(scene_path: String) -> bool:
	return not scene_path.is_empty() and ResourceLoader.exists(scene_path)
