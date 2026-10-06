extends Node
## Actual new upper drum/dome arrays, original camera, wall bodies and state.

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
    _run.call_deferred()

func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures.append(message)
        push_error("ARCHIVE_HUB_DOME FAIL: " + message)

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    await get_tree().physics_frame
    var prologue := world.get_node("Prologue") as ArchivePrologue
    var camera := prologue.camera
    _check(camera.position.is_equal_approx(Vector3(0,1.624,15)) and camera.rotation==Vector3.ZERO and is_equal_approx(camera.fov,75), "Original shipping S00 camera/rail/FOV")
    var owners := ["DomeDrum","DomeFrame","DomeGlass","DomeSky"]
    var stone := preload("res://art/materials/m_observatory_stone.tres")
    var wood := preload("res://art/materials/m_dark_walnut.tres")
    var iron := preload("res://art/materials/m_dark_iron.tres")
    var brass := preload("res://art/materials/m_aged_brass.tres")
    var glass := preload("res://art/materials/m_clear_glass.tres")
    var sky := preload("res://art/materials/m_hub_night_sky.tres")
    var expected := [[stone,wood,iron,brass],[wood,iron,brass],[glass],[sky]]
    var counts := [12492,2784,2396,2396]
    var source_total := 0
    for i in 4:
        var prop := world.get_node("Hub/"+owners[i]) as Node3D
        _check(prop.get_script()==null and prop.transform.is_equal_approx(Transform3D.IDENTITY) and prop.find_children("*","CollisionObject3D",true,false).is_empty() and prop.find_children("*","Light3D",true,false).is_empty(), "Unit origin cosmetic root without collision/light/script " + owners[i])
        var visuals := prop.find_children("*","MeshInstance3D",true,false)
        _check(visuals.size()==1, "One actual imported mesh " + owners[i])
        var visual := visuals[0] as MeshInstance3D
        _check(visual.transform.is_equal_approx(Transform3D.IDENTITY) and visual.mesh.get_surface_count()==expected[i].size(), "Unit source orientation/pivot and surfaces " + owners[i])
        var triangles := 0
        var profile := true
        var frame := true
        var min_y := INF
        for surface in visual.mesh.get_surface_count():
            _check(visual.mesh.surface_get_material(surface)==expected[i][surface], "Exact external material identity " + owners[i] + "/" + str(surface))
            var arrays := visual.mesh.surface_get_arrays(surface)
            var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
            var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
            var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
            var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
            triangles += int(indices.size()/3)
            var valid := vertices.size()==normals.size() and vertices.size()==uv.size() and tangents.size()==vertices.size()*4
            for n in vertices.size():
                var p := visual.global_transform*vertices[n]
                min_y=minf(min_y,p.y)
                profile = profile and p.y>4.799 and p.y<9.4 and absf(p.x)<=11.11 and p.z<9.19
                frame = frame and camera.is_position_in_frustum(p)
                var tangent := Vector3(tangents[n*4],tangents[n*4+1],tangents[n*4+2])
                valid = valid and p.is_finite() and uv[n].is_finite() and absf(normals[n].length()-1)<.001 and absf(tangent.length()-1)<.001 and absf(tangent.dot(normals[n]))<.003
            for n in range(0,indices.size(),3):
                var a := indices[n]
                var b := indices[n+1]
                var c := indices[n+2]
                var area := (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a]).length()/2
                valid = valid and area>1e-10 and absf(absf((uv[b]-uv[a]).cross(uv[c]-uv[a]))/2/area-1)<.004
            _check(valid, "Actual nondegenerate metric UV/unit shading arrays " + owners[i] + "/" + str(surface))
        _check(profile and (min_y>4.799 if i==0 else min_y>=6.15), "Actual upper support/roof player and portal profile " + owners[i])
        _check(frame, "Every actual imported roof vertex inside unchanged original75degree camera frustum " + owners[i])
        _check(triangles==counts[i], "Measured imported triangle count " + owners[i])
        source_total+=triangles
    _check(source_total==20068, "Actual total upper family triangle count")
    _check(sky.shader==preload("res://art/shaders/hub_night_sky.gdshader") and sky.shader.code.find("TIME")==-1, "New static Hub-local sky mapping; no event/time ownership")
    var crown := world.get_node("Hub/EntryArch").find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
    var crown_top := -INF
    for surface in crown.mesh.get_surface_count():
        for p: Vector3 in crown.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
            crown_top=maxf(crown_top,(crown.global_transform*p).y)
    _check(crown_top<5.95 and 5.95-crown_top>.04, "Measured accepted crown top separates from fixed collar/glass/frame")
    var gate_paths := ["Routes/Wing01/Gate","Routes/Wing02/Gate","Routes/Wing03/Gate","Routes/Wing04/Gate","Routes/Wing05/Gate"]
    for path in gate_paths:
        var gate := world.get_node(path) as Node3D
        _check(gate.position.is_equal_approx(Vector3(0,1.7,-8)), "Original route aperture center " + path)
    # Body snapshots are emitted into constants from the already-pinned canonical scene.
    _check_wall_bodies(world)
    prologue._apply_timeline_pose(8.0)
    var ray := world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,1.624,15),Vector3(0,1.624,4),1))
    _check(ray.is_empty() and prologue.camera.position.is_equal_approx(Vector3(0,1.624,4)), "No new physical blocker and original opened camera/player route")
    _check(world.slice_bindings_valid() and GameState.capture_save().to_dict()==before and SaveManager.get("_dirty")==dirty, "Original bindings and read-only state/dirty projection")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_HUB_DOME PASS: %d assertions; actual unit upper drum/dome arrays, original camera frustum/walls/apertures and actor/crown clearance" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)

func _check_wall_bodies(world: Node3D) -> void:
    var b0 := world.get_node("Hub/Wall0L") as StaticBody3D
    _check(b0.position.is_equal_approx(Vector3(-4.6,2.4,-8.0)) and is_equal_approx(b0.rotation.y,0.0) and (b0.get_node("CollisionShape3D").shape as BoxShape3D).size.is_equal_approx(Vector3(5.8,4.8,0.35)) and b0.collision_layer==1 and b0.collision_mask==4, "Original wall body Wall0L")
    var b1 := world.get_node("Hub/Wall0R") as StaticBody3D
    _check(b1.position.is_equal_approx(Vector3(4.6,2.4,-8.0)) and is_equal_approx(b1.rotation.y,0.0) and (b1.get_node("CollisionShape3D").shape as BoxShape3D).size.is_equal_approx(Vector3(5.8,4.8,0.35)) and b1.collision_layer==1 and b1.collision_mask==4, "Original wall body Wall0R")
    var b2 := world.get_node("Hub/Wall1L") as StaticBody3D
    _check(b2.position.is_equal_approx(Vector3(-9.029930304485987,2.4,1.902724019958126)) and is_equal_approx(b2.rotation.y,1.256637061) and (b2.get_node("CollisionShape3D").shape as BoxShape3D).size.is_equal_approx(Vector3(5.8,4.8,0.35)) and b2.collision_layer==1 and b2.collision_mask==4, "Original wall body Wall1L")
    var b3 := world.get_node("Hub/Wall1R") as StaticBody3D
    _check(b3.position.is_equal_approx(Vector3(-6.18697395623647,2.4,-6.846995929957285)) and is_equal_approx(b3.rotation.y,1.256637061) and (b3.get_node("CollisionShape3D").shape as BoxShape3D).size.is_equal_approx(Vector3(5.8,4.8,0.35)) and b3.collision_layer==1 and b3.collision_mask==4, "Original wall body Wall1R")
    var b4 := world.get_node("Hub/Wall2L") as StaticBody3D
    _check(b4.position.is_equal_approx(Vector3(-2.4139,2.4,8.1347)) and is_equal_approx(b4.rotation.y,2.513274123) and (b4.get_node("CollisionShape3D").shape as BoxShape3D).size.is_equal_approx(Vector3(2.258,4.8,0.35)) and b4.collision_layer==1 and b4.collision_mask==4, "Original wall body Wall2L")
    var b5 := world.get_node("Hub/Wall2R") as StaticBody3D
    _check(b5.position.is_equal_approx(Vector3(-8.423760192464544,2.4,3.768323794454202)) and is_equal_approx(b5.rotation.y,2.513274123) and (b5.get_node("CollisionShape3D").shape as BoxShape3D).size.is_equal_approx(Vector3(5.8,4.8,0.35)) and b5.collision_layer==1 and b5.collision_mask==4, "Original wall body Wall2R")
    var b6 := world.get_node("Hub/Wall3L") as StaticBody3D
    _check(b6.position.is_equal_approx(Vector3(8.423760192464542,2.4,3.7683237944542047)) and is_equal_approx(b6.rotation.y,3.769911184) and (b6.get_node("CollisionShape3D").shape as BoxShape3D).size.is_equal_approx(Vector3(5.8,4.8,0.35)) and b6.collision_layer==1 and b6.collision_mask==4, "Original wall body Wall3L")
    var b7 := world.get_node("Hub/Wall3R") as StaticBody3D
    _check(b7.position.is_equal_approx(Vector3(2.4139,2.4,8.1347)) and is_equal_approx(b7.rotation.y,3.769911184) and (b7.get_node("CollisionShape3D").shape as BoxShape3D).size.is_equal_approx(Vector3(2.258,4.8,0.35)) and b7.collision_layer==1 and b7.collision_mask==4, "Original wall body Wall3R")
    var b8 := world.get_node("Hub/Wall4L") as StaticBody3D
    _check(b8.position.is_equal_approx(Vector3(6.186973956236472,2.4,-6.846995929957284)) and is_equal_approx(b8.rotation.y,5.026548246) and (b8.get_node("CollisionShape3D").shape as BoxShape3D).size.is_equal_approx(Vector3(5.8,4.8,0.35)) and b8.collision_layer==1 and b8.collision_mask==4, "Original wall body Wall4L")
    var b9 := world.get_node("Hub/Wall4R") as StaticBody3D
    _check(b9.position.is_equal_approx(Vector3(9.029930304485987,2.4,1.9027240199581286)) and is_equal_approx(b9.rotation.y,5.026548246) and (b9.get_node("CollisionShape3D").shape as BoxShape3D).size.is_equal_approx(Vector3(5.8,4.8,0.35)) and b9.collision_layer==1 and b9.collision_mask==4, "Original wall body Wall4R")
