extends Node

const SETTINGS_PATH := "user://settings.cfg"
var music_volume := 0.8
var sfx_volume := 0.9
var mouse_sensitivity := 0.5
var invert_y := false
var fov := 75.0

func load_settings() -> void:
    pass

func save_settings() -> void:
    EventBus.settings_changed.emit()
