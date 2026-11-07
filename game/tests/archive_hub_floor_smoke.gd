extends Node
## Imported original Hub floor, corridor ownership notch and physical support.
var _checks := 0
var _failures: Array[String] = []
func _ready() -> void:
    _run.call_deferred()
func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures.append(message)
        push_error("ARCHIVE_HUB_FLOOR FAIL: "+message)
func _clip(poly: Array[Vector2], axis: int, bound: float, sign_value: float) -> Array[Vector2]:
    var result: Array[Vector2] = []
    for i in poly.size():
        var a:=poly[i];var b:=poly[(i+1)%poly.size()]
        var da:=sign_value*(a[axis]-bound);var db:=sign_value*(b[axis]-bound)
        if da>=0:
            result.append(a)
        if (da>=0)!=(db>=0):
            result.append(a+(b-a)*da/(da-db))
    return result
func _notch_area(points: Array[Vector2]) -> float:
    points=_clip(_clip(_clip(points,0,-2,1),0,2,-1),1,-8,-1)
    var area:=0.0
    for i in points.size():
        area+=points[i].cross(points[(i+1)%points.size()])
    return absf(area)/2
func _run() -> void:
    var before:=GameState.capture_save().to_dict()
    var dirty: bool=SaveManager.get("_dirty")
    var world:=preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    await get_tree().physics_frame
    var floor_body:=world.get_node("Hub/Floor") as StaticBody3D
    var shape:=floor_body.get_node("CollisionShape3D").shape as CylinderShape3D
    _check(floor_body.position.is_equal_approx(Vector3(0,-.15,0)) and floor_body.rotation==Vector3.ZERO and shape.radius==10 and is_equal_approx(shape.height,.3) and floor_body.collision_layer==1 and floor_body.collision_mask==4,"Original floor body/cylinder/plane/layers")
    var prop:=floor_body.get_node("Mesh") as Node3D
    _check(prop.get_script()==null and prop.position==Vector3.ZERO and prop.rotation==Vector3.ZERO and prop.scale==Vector3.ONE and prop.find_children("*","CollisionObject3D",true,false).is_empty() and prop.find_children("*","Light3D",true,false).is_empty(),"Cosmetic unit floor without collision/light/script")
    var visuals:=prop.find_children("*","MeshInstance3D",true,false)
    _check(visuals.size()==1,"One actual imported master")
    var visual:=visuals[0] as MeshInstance3D
    _check(visual.position==Vector3.ZERO and visual.rotation==Vector3.ZERO and visual.scale==Vector3.ONE and visual.mesh.get_surface_count()==2,"Imported scale/orientation/pivot/surfaces")
    var expected: Array[Material]=[preload("res://art/materials/m_observatory_stone.tres"),preload("res://art/materials/m_aged_brass.tres")]
    var triangles:=0
    var top:=-INF
    for surface in visual.mesh.get_surface_count():
        _check(visual.mesh.surface_get_material(surface)==expected[surface],"Shared material identity "+str(surface))
        var arrays:=visual.mesh.surface_get_arrays(surface)
        var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
        var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
        var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
        var tangents: PackedFloat32Array=arrays[Mesh.ARRAY_TANGENT]
        var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
        triangles+=int(indices.size()/3)
        var valid:=vertices.size()==normals.size() and vertices.size()==uv.size() and tangents.size()==vertices.size()*4
        var inside:=true
        var notch:=true
        for n in vertices.size():
            var p:=vertices[n]
            var tangent:=Vector3(tangents[n*4],tangents[n*4+1],tangents[n*4+2])
            valid=valid and p.is_finite() and uv[n].is_finite() and absf(normals[n].length()-1)<.001 and absf(tangent.length()-1)<.001 and absf(tangent.dot(normals[n]))<.003
            inside=inside and Vector2(p.x,p.z).length()<=9.98002 and p.y>=-.14501 and p.y<=.15351
            top=maxf(top,(visual.global_transform*p).y)
        for n in range(0,indices.size(),3):
            var a:=indices[n];var b:=indices[n+1];var c:=indices[n+2]
            var area: float=(vertices[b]-vertices[a]).cross(vertices[c]-vertices[a]).length()/2
            valid=valid and area>1e-10 and absf(absf((uv[b]-uv[a]).cross(uv[c]-uv[a]))/2/area-1)<.004
            notch=notch and _notch_area([Vector2(vertices[a].x,vertices[a].z),Vector2(vertices[b].x,vertices[b].z),Vector2(vertices[c].x,vertices[c].z)])<.000001
        _check(valid,"Actual nondegenerate triangles/metric UV/unit normals/tangents "+str(surface))
        _check(inside,"Actual floor bounds and low top "+str(surface))
        _check(notch,"Actual triangle projection leaves retained corridor notch empty "+str(surface))
    _check(triangles==6928 and absf(top-.0035)<.00001,"Measured imported triangle count and global top")
    for i in 5:
        var channel:=world.get_node("Routes/Wing%02d/Channel/Mesh"%(i+1)) as MeshInstance3D
        var bottom:=channel.global_position.y-(channel.mesh as BoxMesh).size.y*.5*channel.global_basis.y.length()
        _check(is_equal_approx(bottom,.005) and bottom-top>=.00149,"Original state-owned channel clears new floor "+str(i))
    var core_visual:=world.get_node("Hub/Mechanism").find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
    var core_bottom:=INF
    for surface in core_visual.mesh.get_surface_count():
        for p: Vector3 in core_visual.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:core_bottom=minf(core_bottom,(core_visual.global_transform*p).y)
    _check(is_equal_approx(core_bottom,.006) and core_bottom-top>=.00249,"Accepted core underside stays above new inlays")
    var prologue:=world.get_node("Prologue") as ArchivePrologue
    var approach:=prologue.get_node("Floor/Mesh").find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
    var approach_top:=-INF
    for surface in approach.mesh.get_surface_count():
        for p: Vector3 in approach.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:approach_top=maxf(approach_top,(approach.global_transform*p).y)
    _check(is_equal_approx(approach_top,.006) and approach_top-top>=.00249,"Accepted approach overlap is never coplanar with new skin")
    var space:=world.get_world_3d().direct_space_state
    for p in [Vector3(-6,0,0),Vector3(6,0,0),Vector3(0,0,6),Vector3(0,0,-6)]:
        var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*.2,p-Vector3.UP*.2,1))
        _check(not hit.is_empty() and hit["collider"]==floor_body and is_zero_approx(hit["position"].y),"Original physical plane supports Hub sector "+str(p))
    _check(world.slice_bindings_valid() and GameState.capture_save().to_dict()==before and SaveManager.get("_dirty")==dirty,"Original bindings/read-only DTO/dirty state")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_HUB_FLOOR PASS: %d assertions; actual metric floor/corridor notch, original cylinder and channel/core/approach clearance"%_checks)
    get_tree().quit(0 if _failures.is_empty() else 1)
