class_name ArchivePrologue
extends Node3D
## Graybox S00 in the persistent Archive. Timings are engineering parameters.

signal finished(error: Error)
signal spark_ignited(audio_error: Error)
const SPARK_MUSIC_STATE: StringName = &"spark_first_note"
@export_range(6.0, 20.0, .5) var duration := 8.0
@onready var camera: Camera3D = $Camera3D
@onready var spark: MeshInstance3D = $Spark
@onready var left_door: StaticBody3D = $LeftDoor
@onready var right_door: StaticBody3D = $RightDoor
var elapsed := 0.0
var _started := false
var _completed := true
var _finishing := false
var _mode_revision := -1
var _paused_owned := false
var _spark_ignited := false


func _ready() -> void:
    InputManager.pause_changed.connect(_on_pause_changed)
    EventBus.settings_changed.connect(_apply_camera_settings)
    restore(true)


func restore(completed: bool) -> void:
    _completed = completed
    _started = false
    _finishing = false
    elapsed = 0.0
    _mode_revision = -1
    _paused_owned = false
    _spark_ignited = completed
    spark.visible = completed
    _set_door(1.0 if completed else 0.0)
    camera.position = Vector3(0, 1.624, 15)
    camera.rotation = Vector3.ZERO
    _apply_camera_settings()
    if completed and camera.is_current():
        camera.clear_current(false)
    elif not completed and is_inside_tree():
        camera.make_current()


func _apply_camera_settings() -> void:
    camera.fov = SettingsManager.fov


func _set_door(amount: float) -> void:
    left_door.position.x = -.65 - amount * 1.4
    right_door.position.x = .65 + amount * 1.4


func _on_pause_changed(paused: bool) -> void:
    if not _started or _completed:
        return
    if paused:
        _paused_owned = InputManager.mode == InputManager.Mode.CINEMATIC and InputManager.mode_revision == _mode_revision
    elif _paused_owned and InputManager.mode == InputManager.Mode.CINEMATIC:
        _mode_revision = InputManager.mode_revision
        _paused_owned = false


func _process(delta: float) -> void:
    var world := get_parent() as ArchiveMain
    if _completed or _finishing or world.stage_id != ArchiveProgress.PROLOGUE:
        return
    if not _started:
        if InputManager.mode != InputManager.Mode.CINEMATIC:
            return
        _started = true
        _mode_revision = InputManager.mode_revision
        var player := world.get_node_or_null("../../PlayerContainer/Player") as FirstPersonPlayer
        if player != null:
            camera.fov = player.camera.fov
        camera.make_current()
    if InputManager.mode != InputManager.Mode.CINEMATIC or InputManager.mode_revision != _mode_revision:
        return
    if DisplayServer.get_name() != "headless" and not get_window().has_focus():
        return
    elapsed = minf(duration, elapsed + delta)
    if elapsed >= 1.0 and not _spark_ignited:
        _ignite_spark()
    _set_door(clampf((elapsed - 2.0) / 1.5, 0.0, 1.0))
    var travel := clampf((elapsed - 3.5) / (duration - 3.5), 0.0, 1.0)
    camera.position.z = lerpf(15.0, 4.0, smoothstep(0.0, 1.0, travel))
    if elapsed >= duration:
        _finish()


func _ignite_spark() -> void:
    _spark_ignited = true
    spark.visible = true
    # The Director owns all global players. An absent approved binding remains
    # silent; never substitute a full source take or retry the event every frame.
    var error: Error = ERR_UNCONFIGURED
    if AudioDirector.current_stage == ArchiveProgress.PROLOGUE:
        if AudioDirector.playback_snapshot()["pending_stage"]:
            error = ERR_BUSY
        else:
            error = AudioDirector.set_music_state(SPARK_MUSIC_STATE, 0.0)
    spark_ignited.emit(error)


func _finish() -> void:
    _finishing = true
    var world := get_parent() as ArchiveMain
    var player := world.get_node_or_null("../../PlayerContainer/Player") as FirstPersonPlayer
    if player == null:
        finished.emit(ERR_UNCONFIGURED)
        return
    # Match the real persistent player's feet/head before the synchronous
    # IN_PLACE transaction switches the current camera and input mode.
    player.spawn_at(Transform3D(world.global_basis, world.to_global(Vector3(0, .004, 4))))
    camera.global_transform = player.camera.global_transform
    var error := await world.complete_prologue()
    _finishing = false
    if error != OK and world.stage_id == ArchiveProgress.PROLOGUE:
        # Keep a failed handoff frozen for its caller; never retry every frame.
        _started = true
        _mode_revision = -1
    finished.emit(error)
