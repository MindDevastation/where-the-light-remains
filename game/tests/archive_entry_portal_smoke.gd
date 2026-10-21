extends Node
## Actual imported wall masters and crown; original walls, door sweep and player rail.

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
    _run.call_deferred()

func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures.append(message)
        push_error("ARCHIVE_ENTRY_PORTAL FAIL: " + message)

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    await get_tree().physics_frame
    var objects := [world.get_node("Hub/Wall2L/Mesh"),world.get_node("Hub/Wall3R/Mesh"),world.get_node("Hub/EntryArch")]
    var stone := preload("res://art/materials/m_observatory_stone.tres")
    var walnut := preload("res://art/materials/m_dark_walnut.tres")
    var iron := preload("res://art/materials/m_dark_iron.tres")
    var brass := preload("res://art/materials/m_aged_brass.tres")
    var crimson := preload("res://art/materials/m_crimson_textile.tres")
    var expected := [[stone,walnut,iron,brass,crimson],[stone,walnut,iron,brass,crimson],[stone,iron,brass]]
    var meshes: Array[Mesh] = []
    for i in 3:
        var prop := objects[i] as Node3D
        _check(prop.get_script()==null and prop.rotation==Vector3.ZERO and prop.scale==Vector3.ONE and prop.position.is_equal_approx(Vector3(0,0,9) if i==2 else Vector3.ZERO) and prop.find_children("*","CollisionObject3D",true,false).is_empty() and prop.find_children("*","Light3D",true,false).is_empty(), "Unit cosmetic root without collision/light/script " + str(i))
        var visuals := prop.find_children("*","MeshInstance3D",true,false)
        _check(visuals.size()==1, "One imported mesh " + str(i))
        var visual := visuals[0] as MeshInstance3D
        meshes.append(visual.mesh)
        _check(visual.position==Vector3.ZERO and visual.rotation==Vector3.ZERO and visual.scale==Vector3.ONE and visual.mesh.get_surface_count()==expected[i].size(), "Original metric export pivot and surface count " + str(i))
        var triangles := 0
        var floor := INF
        var front := -INF
        for surface in visual.mesh.get_surface_count():
            _check(visual.mesh.surface_get_material(surface)==expected[i][surface], "Exact shared material identity " + str(i) + "/" + str(surface))
            var arrays := visual.mesh.surface_get_arrays(surface)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
            var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
            var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
            var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
            triangles += int(indices.size()/3)
            var valid := vertices.size()==normals.size() and vertices.size()==uv.size() and tangents.size()==vertices.size()*4
            var inside := true
            for n in vertices.size():
                var point := vertices[n]
                var tangent := Vector3(tangents[n*4],tangents[n*4+1],tangents[n*4+2])
                valid = valid and point.is_finite() and uv[n].is_finite() and absf(normals[n].length()-1)<.001 and absf(tangent.length()-1)<.001 and absf(tangent.dot(normals[n]))<.003
                if i<2:
                    inside = inside and absf(point.x)<=1.12901 and absf(point.y)<=2.40001 and absf(point.z)<=.17501
                    floor = minf(floor,(visual.global_transform*point).y)
                else:
                    var wp := visual.global_transform*point
                    inside = inside and wp.y>=3.83999 and wp.y<=5.93001 and absf(wp.x)<=1.83001
                    front = maxf(front,wp.z)
            for n in range(0,indices.size(),3):
                var a := indices[n]
                var b := indices[n+1]
                var c := indices[n+2]
                var area := (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a]).length()/2
                valid = valid and area>1e-10 and absf(absf((uv[b]-uv[a]).cross(uv[c]-uv[a]))/2/area-1)<.004
            _check(inside, "Actual imported facade body/crown profile containment " + str(i) + "/" + str(surface))
            _check(valid, "Actual nondegenerate triangles, metric UV and unit normals/tangents " + str(i) + "/" + str(surface))
        _check(triangles==(984 if i==2 else 3840), "Measured imported triangle count " + str(i))
        _check(front<=9.16001 if i==2 else absf(floor-.008)<.00002, "Actual crown rear-leaf gap or eight-mm facade floor gap " + str(i))
    _check(meshes[0]==meshes[1], "Both front walls instance exactly one facade master")
    for side in ["Wall2L","Wall3R"]:
        var body := world.get_node("Hub/"+side) as StaticBody3D
        var shape := body.get_node("CollisionShape3D").shape as BoxShape3D
        var sign_x := -1.0 if side=="Wall2L" else 1.0
        _check(body.position.is_equal_approx(Vector3(sign_x*2.4139,2.4,8.1347)) and is_equal_approx(body.rotation.y,deg_to_rad(144 if sign_x<0 else 216)) and shape.size.is_equal_approx(Vector3(2.258,4.8,.35)) and body.collision_layer==1 and body.collision_mask==4, "Original wall body pose/size/layers " + side)
    var practical := world.get_node("Hub/Wall3R/EntryPractical") as Node3D
    _check(practical.position.is_equal_approx(Vector3(.72,.35,-.175)) and is_equal_approx(practical.rotation.y,PI), "Accepted lantern remains on original outward backing face")
    var prologue := world.get_node("Prologue") as ArchivePrologue
    for seconds in [0.0,1.2,2.0,2.5,3.5,7.9,8.0]:
        prologue.camera.position=Vector3(0,1.624,15)
        prologue._apply_timeline_pose(seconds)
        var clear := true
        for leaf in [prologue.left_door,prologue.right_door]:
            var box := leaf.get_node("CollisionShape3D").shape as BoxShape3D
            clear = clear and box.size.is_equal_approx(Vector3(1.3,3.8,.25)) and is_equal_approx(leaf.position.y,1.9) and is_equal_approx(leaf.position.z,9.4)
        _check(clear and prologue.camera.position.x==0 and is_equal_approx(prologue.camera.position.y,1.624), "Original leaf sweep and camera rail pose " + str(seconds))
    var space := world.get_world_3d().direct_space_state
    var ray := PhysicsRayQueryParameters3D.create(Vector3(0,1.624,15),Vector3(0,1.624,4),1)
    _check(space.intersect_ray(ray).is_empty(), "No added physical blocker on fully opened camera/player route")
    _check(world.slice_bindings_valid() and GameState.capture_save().to_dict()==before and SaveManager.get("_dirty")==dirty, "Original bindings and read-only projection/dirty state")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_ENTRY_PORTAL PASS: %d assertions; imported shared facades/crown, original wall bodies, leaf and player-rail clearance" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)
