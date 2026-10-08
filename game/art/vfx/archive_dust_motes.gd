class_name ArchiveDustMotes
extends Node3D
## Decoration only; existing world stage, settings and pause own visibility.

const COUNTS := {"Low": 12, "Medium": 36, "High": 48}
@export var active_stages: Array[StringName] = [ArchiveProgress.INTRO, ArchiveProgress.WING_ONE]
@onready var particles: GPUParticles3D = $Particles
var _world: WorldScene
var _stage := &""


func _ready() -> void:
    var ancestor := get_parent()
    while ancestor != null and not ancestor is WorldScene:
        ancestor = ancestor.get_parent()
    _world = ancestor as WorldScene
    EventBus.settings_changed.connect(_sync)
    InputManager.pause_changed.connect(_on_pause_changed)
    _sync()


func _process(_delta: float) -> void:
    # Quiet restore can project a stage without issuing a global stage event.
    if is_instance_valid(_world) and _stage != _world.stage_id:
        _sync()


func _sync() -> void:
    if not is_instance_valid(particles):
        return
    _stage = _world.stage_id if is_instance_valid(_world) else &""
    var enabled: bool = SettingsManager.effects and _stage in active_stages
    var count: int = COUNTS.get(SettingsManager.graphics_preset, 12)
    if particles.amount != count:
        particles.amount = count
    visible = enabled
    particles.emitting = enabled
    particles.speed_scale = 1.0 if enabled and not get_tree().paused else 0.0


func _on_pause_changed(_paused: bool) -> void:
    _sync()


func _notification(what: int) -> void:
    # Freeze GPU time as well as the pausable wrapper's process callback.
    if what in [NOTIFICATION_PAUSED, NOTIFICATION_UNPAUSED] and is_node_ready():
        _sync()
