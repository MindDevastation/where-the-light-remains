extends Node

const SAVE_PATH := "user://savegame.json"
const BACKUP_PATH := "user://savegame.backup.json"
var _dirty := false

func mark_dirty() -> void:
    _dirty = true

func flush_if_dirty() -> void:
    if not _dirty:
        return
    # Full validated/atomic SaveGame serialization is implemented in the save milestone.
    _dirty = false
