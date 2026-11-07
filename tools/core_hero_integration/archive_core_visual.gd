class_name ArchiveCoreHeroVisual
extends Node3D
## Cosmetic projection only. ArchiveMain's existing clock/durable state owns it.

var warmth := 0.0
var _energy: MeshInstance3D
var _source: StandardMaterial3D
var _instance: StandardMaterial3D
var _previous_override: Material
var _peak := 1.0


func _enter_tree() -> void:
    request_ready()


func _ready() -> void:
    warmth = 0.0
    _energy = get_node("VisualCore/ArchiveCentralMechanism/CoreAssembly/CoreEnergy") as MeshInstance3D
    _source = _energy.get_active_material(0) as StandardMaterial3D
    assert(_source != null, "Recovered core requires its original emissive material")
    _previous_override = _energy.get_surface_override_material(0)
    _peak = _source.emission_energy_multiplier
    _instance = _source.duplicate() as StandardMaterial3D
    _instance.emission_energy_multiplier = 0.0
    _energy.set_surface_override_material(0, _instance)


func project_energy(amount: float) -> void:
    warmth = clampf(amount, 0.0, 1.0)
    if is_instance_valid(_energy) and _instance != null and _energy.get_surface_override_material(0) == _instance:
        _instance.emission_energy_multiplier = _peak * warmth


func _exit_tree() -> void:
    if is_instance_valid(_energy) and _instance != null and _energy.get_surface_override_material(0) == _instance:
        _energy.set_surface_override_material(0, _previous_override)
