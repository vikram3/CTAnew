extends Resource
class_name ChapterConfig

## Data-only definition of a chapter's webtoon placement and playable segments.
@export_range(1, 8) var chapter_number: int = 1
@export var page_count: int = 0
@export var unlock_cost: int = 0
@export var segments: Array[SegmentConfig] = []
