extends Node
## Actual imported optics and original onboarding presentation state contract.

var _checks := 0
var _failures: Array[String] = []

func _ready() -> void:
    _run.call_deferred()

func _check(value: bool, message: String) -> void:
    _checks += 1
    if not value:
        _failures.append(message)
        push_error("ARCHIVE_STARTING_LENS FAIL: " + message)

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    await get_tree().physics_frame
    var hub := world.get_node("Hub/Onboarding") as ArchiveOnboarding
    var loose := hub.get_node("Lens/Visual") as Node3D
    var installed := hub.get_node("InstalledLens") as Node3D
    var socket := hub.get_node("Socket/Visual") as Node3D
    _check(loose.global_position.is_equal_approx(Vector3(-1.7,1.15,.2)) and installed.global_position.is_equal_approx(Vector3(.45,1.4,.8)) and socket.global_position == installed.global_position, "Original pickup and installation poses")
    var lens_visual := loose.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
    var other_visual := installed.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
    _check(lens_visual.mesh == other_visual.mesh, "Pickup and installed lens share exact imported mesh")
    var expected := [[preload("res://art/materials/m_aged_brass.tres"),preload("res://art/materials/m_clear_glass.tres")],
        [preload("res://art/materials/m_dark_iron.tres"),preload("res://art/materials/m_aged_brass.tres")]]
    for i in 2:
        var prop: Node3D = [loose,socket][i]
        _check(prop.get_script()==null and prop.rotation==Vector3.ZERO and prop.scale==Vector3.ONE and prop.find_children("*","CollisionObject3D",true,false).is_empty() and prop.find_children("*","Light3D",true,false).is_empty(), "Cosmetic prop has identity pose and no script/collision/light " + str(i))
        var visuals := prop.find_children("*","MeshInstance3D",true,false)
        _check(visuals.size()==1, "One actual imported mesh " + str(i))
        var visual := visuals[0] as MeshInstance3D
        var mesh := visual.mesh
        _check(visual.position==Vector3.ZERO and visual.rotation==Vector3.ZERO and visual.scale==Vector3.ONE and mesh.get_surface_count()==2, "Two surfaces at identity import " + str(i))
        var box := mesh.get_aabb()
        _check(box.position.x >= -.225 and box.end.x <= .225 and box.position.y >= -.225 and box.end.y <= .225 and box.position.z >= -.15 and box.end.z <= .15, "Geometry stays within original interaction target " + str(i))
        var triangles := 0
        for surface in 2:
            _check(mesh.surface_get_material(surface)==expected[i][surface], "Exact shared material " + str(i) + "/" + str(surface))
            var arrays := mesh.surface_get_arrays(surface)
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
            _check(valid, "Actual finite nondegenerate arrays/unit shading/metric UVs " + str(i) + "/" + str(surface))
        _check(triangles==[1364,1392][i] and triangles<1600, "Measured bounded triangle count " + str(i))
    var socket_mesh := (socket.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D).mesh
    var bore := INF
    var ring := 0.0
    var tab_back := INF
    var socket_arrays := socket_mesh.surface_get_arrays(0)
    var lens_arrays := lens_visual.mesh.surface_get_arrays(0)
    for vertex: Vector3 in socket_arrays[Mesh.ARRAY_VERTEX]:
        bore = minf(bore,Vector2(vertex.x,vertex.y).length())
    for vertex: Vector3 in lens_arrays[Mesh.ARRAY_VERTEX]:
        if absf(vertex.x)>.182:
            tab_back = minf(tab_back,vertex.z)
        if absf(vertex.x)<.17:
            ring = maxf(ring,Vector2(vertex.x,vertex.y).length())
    _check(absf(bore-ring-.002)<.00001, "Measured imported bore/lens radial seating clearance")
    _check(tab_back-socket_mesh.get_aabb().end.z>.0019, "Actual front grip tabs clear socket rim and fasteners")
    for path in hub.target_paths:
        var target := hub.get_node(path) as InteractionTarget
        var area := target.get_parent() as Area3D
        var shape := area.get_node("CollisionShape3D").shape as BoxShape3D
        _check(shape.size==Vector3(.45,.45,.3) and area.collision_layer==2 and area.collision_mask==0, "Original ray target envelope/masks " + str(path))
    for phase in 5:
        _check(loose.visible==(phase<=1) and installed.visible==(phase>=3) and socket.visible, "Real phase visibility " + str(phase))
        for n in 4:
            _check((hub.get_node(hub.target_paths[n]) as InteractionTarget).enabled==(n==phase), "Original ordered target enablement " + str(phase) + "/" + str(n))
        if phase<4:
            _check(hub.advance(phase)==OK, "Actual phase advance " + str(phase))
    hub.retry_activation()
    _check(not loose.visible and installed.visible and hub.phase==ArchiveOnboarding.Phase.LENS_INSTALLED, "Retry retains installed lens")
    hub.restore_awakened(true)
    _check(not loose.visible and installed.visible and hub.phase==ArchiveOnboarding.Phase.AWAKENED, "Quiet awakened restoration")
    hub.restore_awakened(false)
    _check(loose.visible and not installed.visible and hub.phase==ArchiveOnboarding.Phase.CLOSED, "Quiet reset restores loose lens")
    _check(world.slice_bindings_valid(), "Original slice bindings")
    _check(GameState.capture_save().to_dict()==before and SaveManager.get("_dirty")==dirty, "Presentation leaves progression and dirty state unchanged")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_STARTING_LENS PASS: %d assertions; imported prop geometry/materials and real visibility states" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)
