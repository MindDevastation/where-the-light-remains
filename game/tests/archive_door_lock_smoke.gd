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
        push_error("ARCHIVE_DOOR_LOCK FAIL: " + message)

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    await get_tree().physics_frame
    var prologue := world.get_node("Prologue") as ArchivePrologue
    var lock := prologue.get_node("LeftDoor/Lock") as Node3D
    var keeper := prologue.get_node("RightDoor/Keeper") as Node3D
    _check(lock.position.is_equal_approx(Vector3(.65,-.28,.175)) and keeper.position.is_equal_approx(Vector3(-.65,-.28,.175)), "Both fittings attach at the original closed seam")
    var objects := [lock.get_node("Housing"),prologue.lock_bolt.get_node("Art"),keeper.get_node("Keeper")]
    var expected := [[preload("res://art/materials/m_dark_iron.tres"),preload("res://art/materials/m_aged_brass.tres")],
        [preload("res://art/materials/m_aged_brass.tres"),preload("res://art/materials/m_dark_iron.tres")],
        [preload("res://art/materials/m_dark_iron.tres"),preload("res://art/materials/m_aged_brass.tres")]]
    for i in 3:
        var prop: Node3D = objects[i]
        _check(prop.get_script()==null and prop.rotation==Vector3.ZERO and prop.scale==Vector3.ONE and prop.position==Vector3.ZERO and prop.find_children("*","CollisionObject3D",true,false).is_empty() and prop.find_children("*","Light3D",true,false).is_empty(), "Identity cosmetic part without collision/light/script " + str(i))
        var visuals := prop.find_children("*","MeshInstance3D",true,false)
        _check(visuals.size()==1, "One imported mesh " + str(i))
        var visual := visuals[0] as MeshInstance3D
        _check(visual.position==Vector3.ZERO and visual.rotation==Vector3.ZERO and visual.scale==Vector3.ONE and visual.mesh.get_surface_count()==2, "Unit local export, two surfaces " + str(i))
        var triangles := 0
        for surface in 2:
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
            _check(valid, "Actual nondegenerate metric UV and unit shading arrays " + str(i) + "/" + str(surface))
        _check(triangles==[364,152,332][i], "Measured imported triangle count " + str(i))
    prologue.restore(false)
    _check(lock.global_position.is_equal_approx(keeper.global_position) and lock.global_position.is_equal_approx(Vector3(0,1.62,9.575)), "Closed fittings meet at the measured world seam")
    var elapsed := prologue.elapsed
    for seconds in [0.0,1.0,1.5,1.75,2.0,2.5,3.5,8.0]:
        prologue._apply_timeline_pose(seconds)
        var release := clampf((seconds-1.5)/.5,0,1)
        var opening := clampf((seconds-2.0)/1.5,0,1)
        var travel := clampf((seconds-3.5)/(prologue.duration-3.5),0,1)
        _check(is_equal_approx(prologue.lock_bolt.position.x,-.24*release), "Measured cosmetic release at " + str(seconds))
        _check(is_equal_approx(prologue.left_door.position.x,-.65-opening*1.4) and is_equal_approx(prologue.right_door.position.x,.65+opening*1.4) and is_equal_approx(prologue.camera.position.z,lerpf(15,4,smoothstep(0,1,travel))), "Original leaf/rail poses at " + str(seconds))
    _check(prologue.elapsed==elapsed and not prologue.spark.visible, "Pose sampling leaves clock and spark event untouched")
    prologue.restore(true)
    _check(is_equal_approx(prologue.lock_bolt.position.x,-.24) and is_equal_approx(prologue.left_door.position.x,-2.05), "Quiet completed restoration")
    for door: StaticBody3D in [prologue.left_door,prologue.right_door]:
        var shape := door.get_node("CollisionShape3D").shape as BoxShape3D
        _check(shape.size==Vector3(1.3,3.8,.25) and door.collision_layer==1 and door.collision_mask==4, "Original leaf collision and masks")
    _check(world.slice_bindings_valid() and GameState.capture_save().to_dict()==before and SaveManager.get("_dirty")==dirty, "Original bindings and read-only progression/dirty state")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_DOOR_LOCK PASS: %d assertions; actual imported arrays, timed cosmetic poses and quiet restore" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)
