extends Resource
class_name SegmentConfig

## Story placement and gameplay metadata for one playable chapter segment.
@export var before_page: int = 1
@export_multiline var transition_text: String
@export var game_index: int = 0
@export var coins_reward: int = 0
@export_file("*.tscn") var scene_path: String
