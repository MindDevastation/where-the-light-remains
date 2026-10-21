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
        push_error("ARCHIVE_HUB_CONTROLS FAIL: " + message)

func _inside_target(visual: MeshInstance3D, area: Node3D) -> bool:
    var transform := area.global_transform.affine_inverse()*visual.global_transform
    for surface in visual.mesh.get_surface_count():
        var arrays := visual.mesh.surface_get_arrays(surface)
        for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
            var point := transform*vertex
            if absf(point.x)>.225 or absf(point.y)>.225 or absf(point.z)>.15:
                return false
    return true

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    await get_tree().physics_frame
    var hub := world.get_node("Hub/Onboarding") as ArchiveOnboarding
    var panel := hub.get_node("Panel/Visual") as Node3D
    var lever := hub.get_node("Lever/Visual") as Node3D
    var cover := hub.get_node("Panel/Visual/Cover") as Node3D
    var handle := hub.get_node("Lever/Visual/Handle") as Node3D
    _check(panel.global_position.is_equal_approx(Vector3(-.65,1.25,.9)) and lever.global_position.is_equal_approx(Vector3(.95,1.15,.45)), "Original control target poses")
    _check(cover.position.is_equal_approx(Vector3(-.157,0,.02)) and handle.position.is_equal_approx(Vector3(0,-.08,0)), "Authored cover hinge and lever pivot")
    var objects := [panel.get_node("Base"),cover.get_node("Art"),lever.get_node("Base"),handle.get_node("Art")]
    var meshes: Array[MeshInstance3D] = []
    var expected := [[preload("res://art/materials/m_dark_iron.tres"),preload("res://art/materials/m_aged_brass.tres")],
        [preload("res://art/materials/m_dark_walnut.tres"),preload("res://art/materials/m_aged_brass.tres")],
        [preload("res://art/materials/m_dark_iron.tres"),preload("res://art/materials/m_aged_brass.tres")],
        [preload("res://art/materials/m_aged_brass.tres"),preload("res://art/materials/m_dark_walnut.tres")]]
    for i in 4:
        var prop: Node3D = objects[i]
        _check(prop.get_script()==null and prop.rotation==Vector3.ZERO and prop.scale==Vector3.ONE and prop.position==Vector3.ZERO and prop.find_children("*","CollisionObject3D",true,false).is_empty() and prop.find_children("*","Light3D",true,false).is_empty(), "Identity cosmetic part without collision/light/script " + str(i))
        var visuals := prop.find_children("*","MeshInstance3D",true,false)
        _check(visuals.size()==1, "One imported mesh " + str(i))
        var visual := visuals[0] as MeshInstance3D
        meshes.append(visual)
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
        _check(triangles==[664,360,484,432][i], "Measured imported triangle count " + str(i))
    var plate_front := -INF
    var cover_back := INF
    var plate_arrays := meshes[0].mesh.surface_get_arrays(0)
    var cover_arrays := meshes[1].mesh.surface_get_arrays(0)
    for v: Vector3 in plate_arrays[Mesh.ARRAY_VERTEX]:
        plate_front = maxf(plate_front,v.z)
    for v: Vector3 in cover_arrays[Mesh.ARRAY_VERTEX]:
        cover_back = minf(cover_back,(cover.transform*v).z)
    _check(absf(cover_back-plate_front-.02)<.00001, "Actual closed wood cover clears iron backing by 20mm")
    for path in hub.target_paths:
        var target := hub.get_node(path) as InteractionTarget
        var area := target.get_parent() as Area3D
        var shape := area.get_node("CollisionShape3D").shape as BoxShape3D
        _check(shape.size==Vector3(.45,.45,.3) and area.collision_layer==2 and area.collision_mask==0, "Original interaction envelope/masks " + str(path))
    for phase in 5:
        _check(cover.rotation.is_equal_approx(Vector3(0,0 if phase==0 else deg_to_rad(-18),0)) and handle.rotation.is_equal_approx(Vector3(0 if phase<4 else deg_to_rad(25),0,0)), "Actual cosmetic phase poses " + str(phase))
        var inside := true
        for i in 4:
            inside = inside and _inside_target(meshes[i],panel.get_parent() if i<2 else lever.get_parent())
        _check(inside, "Every assembled imported vertex stays inside original target " + str(phase))
        if phase<4:
            _check(hub.advance(phase)==OK, "Existing ordered step " + str(phase))
    hub.retry_activation()
    _check(handle.rotation==Vector3.ZERO and absf(cover.rotation.y-deg_to_rad(-18))<.00001, "Retry releases lever while preserving open cover")
    hub.restore_awakened(true)
    _check(absf(handle.rotation.x-deg_to_rad(25))<.00001 and absf(cover.rotation.y-deg_to_rad(-18))<.00001, "Quiet awakened pose restore")
    hub.restore_awakened(false)
    _check(handle.rotation==Vector3.ZERO and cover.rotation==Vector3.ZERO, "Quiet reset closes cover and releases lever")
    var without_art := ArchiveOnboarding.new()
    add_child(without_art)
    without_art.restore_awakened(true)
    without_art.retry_activation()
    _check(without_art.phase==ArchiveOnboarding.Phase.LENS_INSTALLED, "Existing unbound onboarding remains supported")
    without_art.queue_free()
    _check(world.slice_bindings_valid() and GameState.capture_save().to_dict()==before and SaveManager.get("_dirty")==dirty, "Original bindings and read-only progression/dirty state")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_HUB_CONTROLS PASS: %d assertions; actual imported fitting arrays, full pose envelopes and quiet/retry states" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)
