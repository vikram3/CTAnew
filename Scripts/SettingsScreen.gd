extends Node2D

@onready var music_slider = $CanvasLayer/VBox/MusicSlider
@onready var sfx_slider = $CanvasLayer/VBox2/SFXSlider

func _ready():
	music_slider.value = GameData.data.settings.music_volume
	sfx_slider.value = GameData.data.settings.sfx_volume
	
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	
	$CanvasLayer/BackButton.pressed.connect(SceneManager.go_to_title)

func _on_music_changed(value: float):
	GameData.data.settings.music_volume = value
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(value)
	)
	GameData.save_data()

func _on_sfx_changed(value: float):
	GameData.data.settings.sfx_volume = value
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(value)
	)
	GameData.save_data()
