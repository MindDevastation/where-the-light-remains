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
        push_error("ARCHIVE_CORE_PEDESTAL FAIL: " + message)

func _run() -> void:
    var before := GameState.capture_save().to_dict()
    var dirty: bool = SaveManager.get("_dirty")
    var world := preload("res://worlds/archive/archive_main.tscn").instantiate() as ArchiveMain
    add_child(world)
    await get_tree().physics_frame
    var base := world.get_node("Hub/Mechanism") as Node3D
    var objects := [base]
    var expected := [[preload("res://art/materials/m_observatory_stone.tres"),preload("res://art/materials/m_dark_walnut.tres"),preload("res://art/materials/m_dark_iron.tres"),preload("res://art/materials/m_aged_brass.tres"),preload("res://art/materials/m_crimson_textile.tres")]]
    _check(base.position.is_equal_approx(Vector3(0,.7,0)), "Original core visual center")
    for i in 1:
        var prop: Node3D = objects[i]
        _check(prop.get_script()==null and prop.rotation==Vector3.ZERO and prop.scale==Vector3.ONE and prop.position.is_equal_approx(Vector3(0,.7,0)) and prop.find_children("*","CollisionObject3D",true,false).is_empty() and prop.find_children("*","Light3D",true,false).is_empty(), "Identity cosmetic part without collision/light/script " + str(i))
        var visuals := prop.find_children("*","MeshInstance3D",true,false)
        _check(visuals.size()==1, "One imported mesh " + str(i))
        var visual := visuals[0] as MeshInstance3D
        _check(visual.position==Vector3.ZERO and visual.rotation==Vector3.ZERO and visual.scale==Vector3.ONE and visual.mesh.get_surface_count()==5, "Unit local export, five surfaces " + str(i))
        var triangles := 0
        for surface in 5:
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
                inside = inside and Vector2(point.x,point.z).length()<=1.00001 and absf(point.y)<=.70001
            _check(inside, "Actual imported vertices inside the original core cylinder " + str(i) + "/" + str(surface))
            _check(valid, "Actual nondegenerate metric UV and unit shading arrays " + str(i) + "/" + str(surface))
        _check(triangles==2144, "Measured imported triangle count " + str(i))
    var visual := base.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
    var floor := INF
    var profile := true
    for surface in visual.mesh.get_surface_count():
        for point: Vector3 in visual.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
            var world_point := visual.global_transform*point
            floor = minf(floor,world_point.y)
            profile = profile and (world_point.y<=.64001 or Vector2(world_point.x,world_point.z).length()<=.20001)
    _check(absf(floor-.006)<.00001 and profile, "Actual six-mm floor gap, broad lower platform and narrow upper axle")
    var body := world.get_node("Hub/CoreBody") as StaticBody3D
    var shape := body.get_node("CollisionShape3D").shape as CylinderShape3D
    _check(is_equal_approx(shape.radius,1) and is_equal_approx(shape.height,1.4) and body.position.is_equal_approx(Vector3(0,.7,0)) and body.collision_layer==1 and body.collision_mask==4, "Original core body remains the only blocker")
    var astrolabe := world.get_node("Hub/Astrolabe") as Node3D
    for yaw in [0.0,.4,1.2,2.4,3.8,5.0]:
        astrolabe.rotation.y = yaw
        var clear := true
        for ring_name in ["OuterRing","InnerRing"]:
            var ring := astrolabe.get_node(ring_name) as MeshInstance3D
            for point: Vector3 in ring.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
                var world_point := ring.global_transform*point
                clear = clear and world_point.y>.80 and Vector2(world_point.x,world_point.z).length()>.40
        _check(clear, "Actual ring vertex profile separates from lower housing/axle during parent yaw " + str(yaw))
    _check(world.slice_bindings_valid() and GameState.capture_save().to_dict()==before and SaveManager.get("_dirty")==dirty, "Original bindings and read-only progression/dirty state")
    world.queue_free()
    await get_tree().process_frame
    if _failures.is_empty():
        print("ARCHIVE_CORE_PEDESTAL PASS: %d assertions; imported five-surface housing, cylinder/floor and actual ring-array clearance" % _checks)
    get_tree().quit(0 if _failures.is_empty() else 1)
