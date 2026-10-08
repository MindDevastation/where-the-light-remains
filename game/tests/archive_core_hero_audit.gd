extends Node
## Readonly native inventory of current hero interfaces, not hero acceptance.

func vector(value: Vector3) -> Array:
    return [value.x,value.y,value.z]

func mesh_record(mesh: MeshInstance3D) -> Dictionary:
    var low := Vector3(INF,INF,INF)
    var high := Vector3(-INF,-INF,-INF)
    var triangles := 0
    for surface in mesh.mesh.get_surface_count():
        var arrays := mesh.mesh.surface_get_arrays(surface)
        var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
        var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
        triangles += int(indices.size()/3) if not indices.is_empty() else int(vertices.size()/3)
        for point: Vector3 in vertices:
            var world_point := mesh.global_transform*point
            low=low.min(world_point);high=high.max(world_point)
    return {"path":str(mesh.get_path()),"mesh_class":mesh.mesh.get_class(),"triangles":triangles,
        "position":vector(mesh.global_position),"rotation":vector(mesh.rotation),"scale":vector(mesh.scale),
        "world_vertex_bounds":{"min":vector(low),"max":vector(high)},
        "material":mesh.get_active_material(0).resource_path}

func _ready() -> void:
    _run.call_deferred()

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    world.set_process(false)
    world.get_node("Prologue").set_process(false)
    await get_tree().physics_frame
    var ring_data: Array = []
    for name in ["OuterRing","InnerRing"]:
        ring_data.append(mesh_record(world.get_node("Hub/Astrolabe/"+name)))
    var controls: Array = []
    for name in ["Panel","Lens","Socket","Lever"]:
        var target := world.get_node("Hub/Onboarding/"+name) as Area3D
        var shape := target.get_node("CollisionShape3D").shape as BoxShape3D
        controls.append({"path":str(target.get_path()),"position":vector(target.global_position),
            "target_box":vector(shape.size),"layer":target.collision_layer,"mask":target.collision_mask})
    var body := world.get_node("Hub/CoreBody") as StaticBody3D
    var shape := body.get_node("CollisionShape3D").shape as CylinderShape3D
    var data := {"purpose":"Actual native interface audit only; two primitive rings do not satisfy authored3–5-piece hero",
        "rings":ring_data,"controls":controls,"core_body":{"position":vector(body.global_position),
        "radius":shape.radius,"height":shape.height,"layer":body.collision_layer,"mask":body.collision_mask},
        "astrolabe_pivot":vector((world.get_node("Hub/Astrolabe") as Node3D).global_position),
        "lower_housing":mesh_record(world.get_node("Hub/Mechanism").find_children("*","MeshInstance3D",true,false)[0])}
    if GameState.capture_save().to_dict()!=before or SaveManager.get("_dirty")!=dirty:
        push_error("Core audit changed logical save state")
        get_tree().quit(1)
        return
    print("CORE_HERO_AUDIT_DATA ",JSON.stringify(data))
    world.queue_free()
    await get_tree().process_frame
    print("ARCHIVE_CORE_HERO_AUDIT PASS: native arrays/interfaces collected; readonly state")
    get_tree().quit()
