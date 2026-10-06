extends MeshInstance3D
## Immutable imported cosmetic mesh. Existing gate bindings need it before tree entry.
const SOURCE := preload("res://art/meshes/archive_kit/sm_archive_wing_gate.glb")

func _init() -> void:
    # Read the imported resource without nested Node allocation during threaded loads.
    var state := SOURCE.get_state()
    for node in state.get_node_count():
        if state.get_node_type(node)!=&"MeshInstance3D":
            continue
        for property in state.get_node_property_count(node):
            if state.get_node_property_name(node,property)==&"mesh":
                mesh = state.get_node_property_value(node,property) as Mesh
                return
    push_error("Shared imported gate has no mesh resource")
