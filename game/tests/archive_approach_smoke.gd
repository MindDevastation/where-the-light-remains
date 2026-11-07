extends Node
## Imported level paving/guards, original physical containment and read-only state.

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
    _run.call_deferred()

func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures.append(message)
        push_error("ARCHIVE_APPROACH FAIL: " + message)

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    await get_tree().physics_frame
    var prologue := world.get_node("Prologue") as ArchivePrologue
    var owners := ["Floor","LeftGuard","RightGuard","RearGuard"]
    var sizes := [Vector3(4,.3,8),Vector3(.3,1.2,8.3),Vector3(.3,1.2,8.3),Vector3(4.6,1.2,.3)]
    var positions := [Vector3(0,-.15,12),Vector3(-2.15,.6,12),Vector3(2.15,.6,12),Vector3(0,.6,16.15)]
    var expected := [preload("res://art/materials/m_observatory_stone.tres"),preload("res://art/materials/m_dark_iron.tres"),preload("res://art/materials/m_aged_brass.tres")]
    var meshes: Array[Mesh] = []
    for i in 4:
        var body := prologue.get_node(owners[i]) as StaticBody3D
        var shape := body.get_node("CollisionShape3D").shape as BoxShape3D
        _check(body.position.is_equal_approx(positions[i]) and body.rotation==Vector3.ZERO and body.scale==Vector3.ONE and shape.size.is_equal_approx(sizes[i]) and body.collision_layer==1 and body.collision_mask==4, "Original floor/guard body pose, shape and layers " + owners[i])
        var prop := body.get_node("Mesh") as Node3D
        _check(prop.get_script()==null and prop.transform.is_equal_approx(Transform3D.IDENTITY) and prop.find_children("*","CollisionObject3D",true,false).is_empty() and prop.find_children("*","Light3D",true,false).is_empty(), "Unit cosmetic part without imported collision/light/script " + owners[i])
        var visuals := prop.find_children("*","MeshInstance3D",true,false)
        _check(visuals.size()==1, "One actual imported mesh " + owners[i])
        var visual := visuals[0] as MeshInstance3D
        _check(visual.transform.is_equal_approx(Transform3D.IDENTITY) and visual.mesh.get_surface_count()==3, "Centered metric import and exact three surfaces " + owners[i])
        meshes.append(visual.mesh)
        var triangles := 0
        var maximum := -INF
        for surface in 3:
            _check(visual.mesh.surface_get_material(surface)==expected[surface], "Exact shared material identity " + owners[i] + "/" + str(surface))
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
                var p := vertices[n]
                inside = inside and absf(p.x)<=sizes[i].x/2+.00001 and absf(p.z)<=sizes[i].z/2+.00001 and p.y>=-sizes[i].y/2-.00001 and p.y<=(.15601 if i==0 else sizes[i].y/2+.00001)
                maximum=maxf(maximum,(visual.global_transform*p).y)
                var tangent := Vector3(tangents[n*4],tangents[n*4+1],tangents[n*4+2])
                valid = valid and p.is_finite() and uv[n].is_finite() and absf(normals[n].length()-1)<.001 and absf(tangent.length()-1)<.001 and absf(tangent.dot(normals[n]))<.003
            for n in range(0,indices.size(),3):
                var a := indices[n]
                var b := indices[n+1]
                var c := indices[n+2]
                var area := (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a]).length()/2
                valid = valid and area>1e-10 and absf(absf((uv[b]-uv[a]).cross(uv[c]-uv[a]))/2/area-1)<.004
            _check(inside, "Actual imported path/guard vertices in unchanged envelope " + owners[i] + "/" + str(surface))
            _check(valid, "Actual metric UV/unit normals/tangents/nondegenerate triangles " + owners[i] + "/" + str(surface))
        _check(triangles<=(6000 if i==0 else 4000), "Measured imported local triangle budget " + owners[i])
        _check(absf(maximum-.006)<.00002 if i==0 else maximum<1.20001, "Six-mm level paving or contained guard height " + owners[i])
    _check(meshes[1]==meshes[2] and meshes[1]!=meshes[3], "Both side guards share one master; rear has original shorter crosswise envelope")
    var planes: Array[Array] = []
    for owner in ["RightGuard","RearGuard"]:
        var visual := prologue.get_node(owner+"/Mesh").find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
        var horizontal: Array[Vector4] = []
        var heights: Array[float] = []
        for surface in 3:
            var arrays := visual.mesh.surface_get_arrays(surface)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
            for n in range(0,indices.size(),3):
                var a := visual.global_transform*vertices[indices[n]]
                var b := visual.global_transform*vertices[indices[n+1]]
                var c := visual.global_transform*vertices[indices[n+2]]
                var normal := (b-a).cross(c-a).normalized()
                if absf(normal.y)>.99999:
                    horizontal.append(Vector4(minf(a.x,minf(b.x,c.x)),maxf(a.x,maxf(b.x,c.x)),minf(a.z,minf(b.z,c.z)),maxf(a.z,maxf(b.z,c.z))))
                    heights.append(a.y)
        planes.append([horizontal,heights])
    var separated := true
    for a in planes[0][0].size():
        for b in planes[1][0].size():
            var first: Vector4 = planes[0][0][a]
            var second: Vector4 = planes[1][0][b]
            if minf(first.y,second.y)-maxf(first.x,second.x)>.00001 and minf(first.w,second.w)-maxf(first.z,second.z)>.00001:
                separated = separated and absf(planes[0][1][a]-planes[1][1][b])>.00001
    _check(separated, "Actual imported overlapping corner horizontal planes are separated; rear source offset stays inside unchanged body")
    var space := world.get_world_3d().direct_space_state
    var down := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,1,12),Vector3(0,-1,12),1))
    _check(not down.is_empty() and down["collider"]==prologue.get_node("Floor") and absf(down["position"].y)<.00001, "Original flat collision plane remains exactly Y0")
    var side := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,.9,12),Vector3(3,.9,12),1))
    var rear := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,.9,15),Vector3(0,.9,17),1))
    _check(not side.is_empty() and side["collider"]==prologue.get_node("RightGuard") and not rear.is_empty() and rear["collider"]==prologue.get_node("RearGuard"), "Original guard bodies still contain actor; decorative open bars introduce no gameplay gap")
    prologue._apply_timeline_pose(8.0)
    var rail := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,1.624,15),Vector3(0,1.624,4),1))
    _check(rail.is_empty() and prologue.camera.position.is_equal_approx(Vector3(0,1.624,4)) and is_equal_approx(prologue.camera.fov,75), "Original opened rail and camera pose/FOV clear")
    _check(world.slice_bindings_valid() and GameState.capture_save().to_dict()==before and SaveManager.get("_dirty")==dirty, "Original bindings and read-only projection/dirty state")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_APPROACH PASS: %d assertions; imported flat paving/shared guards, unchanged floor and containment, camera/player route" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)
