extends MeshInstance3D
## Immutable imported cosmetic mesh. Existing gate bindings need it before tree entry.
const SOURCE := preload("res://art/meshes/archive_kit/sm_archive_wing_gate.glb")

func _init() -> void:
    var source := SOURCE.instantiate()
    var visuals := source.find_children("*","MeshInstance3D",true,false)
    assert(visuals.size()==1)
    mesh = (visuals[0] as MeshInstance3D).mesh
    source.free()
