extends Node
## Imported shared gate through unchanged pre-tree binding and opening-ghost contract.
var _checks:=0
var _failures: Array[String]=[]
func _ready() -> void:
    _run.call_deferred()
func _check(value: bool,message: String) -> void:
    _checks+=1
    if not value:
        _failures.append(message)
        push_error("ARCHIVE_WING_GATE FAIL: "+message)
func _run() -> void:
    var before:=GameState.capture_save().to_dict()
    var dirty: bool=SaveManager.get("_dirty")
    var world:=preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    var gates: Array[ArchiveGate]=[]
    for i in 5:
        var gate:=world.get_node("Routes/Wing%02d/Gate"%(i+1)) as ArchiveGate
        gates.append(gate)
        _check(gate.bindings_valid() and not gate.is_inside_tree(),"Original MeshInstance binding works before tree insertion "+str(i))
    add_child(world)
    await get_tree().physics_frame
    var expected: Array[Material]=[preload("res://art/materials/m_dark_walnut.tres"),preload("res://art/materials/m_dark_iron.tres"),preload("res://art/materials/m_aged_brass.tres")]
    var master: Mesh
    for i in 5:
        var gate:=gates[i]
        var body:=gate.get_node("Barrier") as StaticBody3D
        var shape:=body.get_node("CollisionShape3D").shape as BoxShape3D
        var visual:=body.get_node("Mesh") as MeshInstance3D
        if master==null:master=visual.mesh
        _check(gate.bindings_valid() and gate.status==ArchiveGate.Status.DORMANT and is_equal_approx(gate.opening_duration,.45) and is_equal_approx(gate.opening_height,3.3),"Original dormant binding/timing/height "+str(i))
        _check(body.position.is_equal_approx(Vector3(0,1.6,0)) and body.rotation==Vector3.ZERO and body.scale==Vector3.ONE and shape.size.is_equal_approx(Vector3(3.4,3.2,.24)) and body.collision_layer==1 and body.collision_mask==4,"Original barrier body/shape/layers "+str(i))
        _check(visual.mesh==master and visual.position==Vector3.ZERO and visual.rotation==Vector3.ZERO and visual.scale==Vector3.ONE and visual.material_override==null and visual.mesh.get_surface_count()==3,"Exact shared GLB mesh, unit target pivot and imported surfaces "+str(i))
        var triangles:=0
        var bottom:=INF
        for surface in visual.mesh.get_surface_count():
            _check(visual.mesh.surface_get_material(surface)==expected[surface],"Shared imported material identity "+str(i)+"/"+str(surface))
            var arrays:=visual.mesh.surface_get_arrays(surface)
            var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
            var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
            var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
            var tangents: PackedFloat32Array=arrays[Mesh.ARRAY_TANGENT]
            var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
            triangles+=int(indices.size()/3)
            var valid:=vertices.size()==normals.size() and vertices.size()==uv.size() and tangents.size()==vertices.size()*4
            var inside:=true
            for n in vertices.size():
                var p:=vertices[n]
                var tangent:=Vector3(tangents[n*4],tangents[n*4+1],tangents[n*4+2])
                valid=valid and p.is_finite() and uv[n].is_finite() and absf(normals[n].length()-1)<.001 and absf(tangent.length()-1)<.001 and absf(tangent.dot(normals[n]))<.003
                inside=inside and absf(p.x)<=1.70001 and absf(p.y)<=1.60001 and absf(p.z)<=.12001
                bottom=minf(bottom,(visual.global_transform*p).y)
            for n in range(0,indices.size(),3):
                var a:=indices[n];var b:=indices[n+1];var c:=indices[n+2]
                var area: float=(vertices[b]-vertices[a]).cross(vertices[c]-vertices[a]).length()/2
                valid=valid and area>1e-10 and absf(absf((uv[b]-uv[a]).cross(uv[c]-uv[a]))/2/area-1)<.004
            _check(valid,"Actual triangles/metric UV/unit normals/tangents "+str(i)+"/"+str(surface))
            _check(inside,"Actual original barrier envelope containment "+str(i)+"/"+str(surface))
        _check(triangles==3596 and absf(bottom-.008)<.00002,"Measured triangles/eight-mm floor gap "+str(i))
        for state in [ArchiveGate.Status.UNLOCKED,ArchiveGate.Status.OPEN,ArchiveGate.Status.COMPLETED,ArchiveGate.Status.DORMANT]:
            _check(gate.apply_state(state,false)==OK and gate.bindings_valid(),"Original quiet state and binding "+str(i)+"/"+str(state))
            await get_tree().physics_frame
            _check(body.get_node("CollisionShape3D").disabled==(state in [ArchiveGate.Status.OPEN,ArchiveGate.Status.COMPLETED]) and body.visible==(state not in [ArchiveGate.Status.OPEN,ArchiveGate.Status.COMPLETED]),"Original state-owned physical/visual visibility "+str(i)+"/"+str(state))
    var opening:=gates[0]
    _check(opening.apply_state(ArchiveGate.Status.UNLOCKED)==OK and opening.apply_state(ArchiveGate.Status.OPEN,true)==OK,"Actual unchanged animated-open API")
    var ghost:=opening.get_node_or_null("OpeningVisual") as MeshInstance3D
    _check(ghost!=null and ghost.mesh==master and ghost.material_override==null and ghost.mesh.get_surface_count()==3 and ghost.transform.is_equal_approx(opening.get_node("Barrier").transform*opening.get_node("Barrier/Mesh").transform),"Original real opening ghost carries exact imported mesh/surfaces/transform")
    await get_tree().physics_frame
    _check(opening.get_node("Barrier/CollisionShape3D").disabled and opening.animation_running,"Logically open passage disabled while original ghost animates")
    await get_tree().create_timer(.6).timeout
    _check(not opening.animation_running and not is_instance_valid(ghost),"Original duration releases owned ghost")
    _check(opening.apply_state(ArchiveGate.Status.DORMANT)==OK,"Restore original dormant test presentation")
    _check(world.slice_bindings_valid() and GameState.capture_save().to_dict()==before and SaveManager.get("_dirty")==dirty,"Original world bindings/read-only DTO/dirty state")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_WING_GATE PASS: %d assertions; five actual GLB meshes, pre-tree binding, original quiet states/body and real opening ghost"%_checks)
    get_tree().quit(0 if _failures.is_empty() else 1)
