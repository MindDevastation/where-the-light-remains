extends Node
## Actual imported four-part fittings, full pose envelopes and restoration.

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
    _run.call_deferred()

func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures.append(message)
        push_error("ARCHIVE_ENTRANCE_LEAF FAIL: " + message)

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    await get_tree().physics_frame
    var prologue := world.get_node("Prologue") as ArchivePrologue
    var objects := [prologue.get_node("LeftDoor/Mesh"),prologue.get_node("RightDoor/Mesh")]
    var expected := [[preload("res://art/materials/m_dark_walnut.tres"),preload("res://art/materials/m_dark_iron.tres"),preload("res://art/materials/m_aged_brass.tres")],
        [preload("res://art/materials/m_dark_walnut.tres"),preload("res://art/materials/m_dark_iron.tres"),preload("res://art/materials/m_aged_brass.tres")]]
    for i in 2:
        var prop: Node3D = objects[i]
        _check(prop.get_script()==null and prop.rotation==Vector3.ZERO and prop.scale==Vector3.ONE and prop.position==Vector3.ZERO and prop.find_children("*","CollisionObject3D",true,false).is_empty() and prop.find_children("*","Light3D",true,false).is_empty(), "Identity cosmetic part without collision/light/script " + str(i))
        var visuals := prop.find_children("*","MeshInstance3D",true,false)
        _check(visuals.size()==1, "One imported mesh " + str(i))
        var visual := visuals[0] as MeshInstance3D
        _check(visual.position==Vector3.ZERO and visual.rotation==Vector3.ZERO and visual.scale==Vector3.ONE and visual.mesh.get_surface_count()==3, "Unit local export, three surfaces " + str(i))
        var triangles := 0
        for surface in 3:
            _check(visual.mesh.surface_get_material(surface)==expected[i][surface], "Exact shared surface identity " + str(i) + "/" + str(surface))
            var arrays := visual.mesh.surface_get_arrays(surface)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
            var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
            var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
            var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
            triangles += int(indices.size()/3)
            var valid := vertices.size()==normals.size() and vertices.size()==uv.size() and tangents.size()==vertices.size()*4
            for n in vertices.size():
                var tangent := Vector3(tangents[n*4],tangents[n*4+1],tangents[n*4+2])
                valid = valid and vertices[n].is_finite() and uv[n].is_finite() and absf(normals[n].length()-1)<.001 and absf(tangent.length()-1)<.001 and absf(tangent.dot(normals[n]))<.003
            for n in range(0,indices.size(),3):
                var a := indices[n]
                var b := indices[n+1]
                var d := indices[n+2]
                var area := (vertices[b]-vertices[a]).cross(vertices[d]-vertices[a]).length()/2
                valid = valid and area>1e-10 and absf(absf((uv[b]-uv[a]).cross(uv[d]-uv[a]))/2/area-1)<.004
            var inside := true
            for point: Vector3 in vertices:
                inside = inside and absf(point.x)<=.65001 and absf(point.y)<=1.90001 and absf(point.z)<=.12501
            _check(inside, "Actual imported vertices inside the original blocking shape " + str(i) + "/" + str(surface))
            _check(valid, "Actual nondegenerate metric UV and unit shading arrays " + str(i) + "/" + str(surface))
        _check(triangles==2100, "Measured imported triangle count " + str(i))
    var a := objects[0].find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
    var b := objects[1].find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
    _check(a.mesh==b.mesh, "Both leaves use the exact same imported master")
    prologue.restore(false)
    for door: StaticBody3D in [prologue.left_door,prologue.right_door]:
        var shape := door.get_node("CollisionShape3D").shape as BoxShape3D
        _check(shape.size==Vector3(1.3,3.8,.25) and door.collision_layer==1 and door.collision_mask==4, "Original leaf collision/masks")
    var front := -INF
    for surface in a.mesh.get_surface_count():
        for point: Vector3 in a.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
            front = maxf(front,(a.global_transform*point).z)
    _check(9.54-front>=.01499 and 9.535-front>=.00999, "Actual outside timber/metal clears preserved lock plates >=15/10mm")
    prologue._apply_timeline_pose(3.8)
    _check(a.global_position.distance_to(prologue.left_door.global_position)<.0001 and b.global_position.distance_to(prologue.right_door.global_position)<.0001, "Art follows each real opened parent body")
    _check(world.slice_bindings_valid() and GameState.capture_save().to_dict()==before and SaveManager.get("_dirty")==dirty, "Original bindings and read-only progression/dirty state")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_ENTRANCE_LEAF PASS: %d assertions; shared imported original leaf fits retained body and lock interface" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)
