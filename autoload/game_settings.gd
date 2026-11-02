extends Node
## Ajustes del jugador (volúmenes, pantalla completa). Se guardan en user://settings.cfg.

const PATH := "user://settings.cfg"

var master_volume := 0.8
var music_volume := 0.7
var sfx_volume := 0.9
var fullscreen := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	master_volume = float(config.get_value("audio", "master", 0.8))
	music_volume = float(config.get_value("audio", "music", 0.7))
	sfx_volume = float(config.get_value("audio", "sfx", 0.9))
	fullscreen = bool(config.get_value("video", "fullscreen", true))

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("video", "fullscreen", fullscreen)
	config.save(PATH)

func apply() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
	_set_bus("Music", music_volume)
	_set_bus("SFX", sfx_volume)
	_set_bus("Ambience", sfx_volume)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1280, 720))

func _set_bus(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index != -1:
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
