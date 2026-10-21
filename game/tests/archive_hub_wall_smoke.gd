extends Node
## Actual eight imported lower wall instances, original bodies and apertures.
var _checks := 0
var _failures: Array[String] = []
func _ready() -> void:
    _run.call_deferred()
func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures.append(message)
        push_error("ARCHIVE_HUB_WALL FAIL: " + message)
func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    await get_tree().physics_frame
    var walls := [
        ["Wall0L",Vector3(-4.6,2.4,-8),0.0],
        ["Wall0R",Vector3(4.6,2.4,-8),0.0],
        ["Wall1L",Vector3(-9.0299303045,2.4,1.90272402),1.256637061],
        ["Wall1R",Vector3(-6.1869739562,2.4,-6.84699593),1.256637061],
        ["Wall2R",Vector3(-8.4237601925,2.4,3.7683237945),2.513274123],
        ["Wall3L",Vector3(8.4237601925,2.4,3.7683237945),3.769911184],
        ["Wall4L",Vector3(6.1869739562,2.4,-6.84699593),5.026548246],
        ["Wall4R",Vector3(9.0299303045,2.4,1.90272402),5.026548246]
    ]
    var expected := [preload("res://art/materials/m_observatory_stone.tres"),preload("res://art/materials/m_dark_walnut.tres"),preload("res://art/materials/m_dark_iron.tres"),preload("res://art/materials/m_aged_brass.tres"),preload("res://art/materials/m_navy_textile.tres")]
    var master: Mesh
    var bodies: Array[Node] = []
    for row: Array in walls:
        var body := world.get_node("Hub/"+row[0]) as StaticBody3D
        bodies.append(body)
        var shape := body.get_node("CollisionShape3D").shape as BoxShape3D
        _check(body.position.is_equal_approx(row[1]) and is_equal_approx(body.rotation.y,row[2]) and shape.size.is_equal_approx(Vector3(5.8,4.8,.35)) and body.collision_layer==1 and body.collision_mask==4,"Original wall body pose/shape/layers "+row[0])
        var prop := body.get_node("Mesh") as Node3D
        _check(prop.get_script()==null and prop.position==Vector3.ZERO and prop.rotation==Vector3.ZERO and prop.scale==Vector3.ONE and prop.find_children("*","CollisionObject3D",true,false).is_empty() and prop.find_children("*","Light3D",true,false).is_empty(),"Cosmetic unit root without physics/light/script "+row[0])
        var visuals := prop.find_children("*","MeshInstance3D",true,false)
        _check(visuals.size()==1,"One imported mesh "+row[0])
        var visual := visuals[0] as MeshInstance3D
        if master==null:
            master=visual.mesh
        _check(visual.mesh==master and visual.position==Vector3.ZERO and visual.rotation==Vector3.ZERO and visual.scale==Vector3.ONE and visual.mesh.get_surface_count()==5,"Exact shared wall master and local pivot "+row[0])
        var triangles := 0
        var floor := INF
        for surface in visual.mesh.get_surface_count():
            _check(visual.mesh.surface_get_material(surface)==expected[surface],"Shared material identity "+row[0]+"/"+str(surface))
            var arrays := visual.mesh.surface_get_arrays(surface)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
            var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
            var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
            var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
            triangles+=int(indices.size()/3)
            var valid := vertices.size()==normals.size() and vertices.size()==uv.size() and tangents.size()==vertices.size()*4
            var inside := true
            for n in vertices.size():
                var p := vertices[n]
                var tangent := Vector3(tangents[n*4],tangents[n*4+1],tangents[n*4+2])
                valid=valid and p.is_finite() and uv[n].is_finite() and absf(normals[n].length()-1)<.001 and absf(tangent.length()-1)<.001 and absf(tangent.dot(normals[n]))<.003
                inside=inside and absf(p.x)<=2.90001 and absf(p.y)<=2.40001 and absf(p.z)<=.17501
                floor=minf(floor,(visual.global_transform*p).y)
            for n in range(0,indices.size(),3):
                var a:=indices[n];var b:=indices[n+1];var c:=indices[n+2]
                var area: float=(vertices[b]-vertices[a]).cross(vertices[c]-vertices[a]).length()/2
                valid=valid and area>1e-10 and absf(absf((uv[b]-uv[a]).cross(uv[c]-uv[a]))/2/area-1)<.004
            _check(inside,"Actual imported body containment "+row[0]+"/"+str(surface))
            _check(valid,"Actual triangles/metric UV/unit normals/tangents "+row[0]+"/"+str(surface))
        _check(triangles==6708 and absf(floor-.008)<.00002,"Measured triangles/eight-mm floor gap "+row[0])
    var prologue := world.get_node("Prologue") as ArchivePrologue
    prologue._apply_timeline_pose(8.0)
    var space := world.get_world_3d().direct_space_state
    for i in 5:
        var a:=i*TAU/5
        var direction:=Vector3(-sin(a),0,-cos(a))
        var query:=PhysicsRayQueryParameters3D.create(direction*6+Vector3.UP*1.624,direction*10+Vector3.UP*1.624,1)
        var hit:=space.intersect_ray(query)
        _check(hit.is_empty() or not bodies.has(hit["collider"]),"No wall intrudes into original aperture; existing dormant gate may block "+str(i))
    var ray:=PhysicsRayQueryParameters3D.create(Vector3(0,1.624,15),Vector3(0,1.624,4),1)
    _check(space.intersect_ray(ray).is_empty(),"Original fully opened player/camera rail remains physically clear")
    _check(world.slice_bindings_valid() and GameState.capture_save().to_dict()==before and SaveManager.get("_dirty")==dirty,"Original bindings/read-only DTO and dirty state")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_HUB_WALL PASS: %d assertions; actual eight shared wall masters/materials, original bodies/apertures and opened route" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)
