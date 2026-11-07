extends SceneTree
## Private reconstructed geometry/query fixture; never loads ArchiveMain/autoload/save.
var failures: Array[String] = []
var assertions := 0
var sample_count := 8192
var contract: Dictionary
var audit: Dictionary
var metric: Dictionary
var world: Node3D

func check(value: bool, label: String) -> void:
    assertions += 1
    if not value:
        failures.append(label)

func vec(values: Array) -> Vector3:
    return Vector3(float(values[0]), float(values[1]), float(values[2]))

func arr(value: Vector3) -> Array:
    return [value.x,value.y,value.z]

func segment_gap(point: Vector3, start: Vector3, finish: Vector3) -> float:
    var delta := finish-start
    var alpha := clampf((point-start).dot(delta)/delta.length_squared(),0.0,1.0)
    return point.distance_to(start+alpha*delta)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    contract=JSON.parse_string(FileAccess.get_file_as_string("res://contract.json"))
    audit=JSON.parse_string(FileAccess.get_file_as_string("res://interfaces.json"))
    metric=JSON.parse_string(FileAccess.get_file_as_string("res://metric.json"))
    var pivot := vec(contract.pivot_world_m)
    var curves: Array[PackedVector3Array] = []
    var native_bases: Array = []
    for index in contract.orbits.size():
        var orbit: Dictionary=contract.orbits[index]
        var basis := Basis.from_euler(vec(orbit.euler_degrees)*PI/180.0)
        native_bases.append([arr(basis.x),arr(basis.y),arr(basis.z)])
        var expected: Array=metric.measurements[index].native_basis_columns
        check(basis.x.distance_to(vec(expected[0]))<0.000002 and basis.y.distance_to(vec(expected[1]))<0.000002 and basis.z.distance_to(vec(expected[2]))<0.000002,"native basis "+str(index))
        var curve := PackedVector3Array()
        for n in sample_count:
            var theta := TAU*float(n)/sample_count
            curve.append(pivot+basis*Vector3(cos(theta)*float(orbit.radius_m),0,sin(theta)*float(orbit.radius_m)))
        curves.append(curve)
    var comparisons: Array = []
    var revision_rows: Array = []
    var own_joint_rows: Array = []
    for index in contract.orbits.size():
        var anchor := vec(metric.measurements[index].upper_bridge_anchor_world_m)
        var legacy: Array[Vector3] = [pivot,anchor]
        var revised: Array[Vector3] = [pivot]
        for point in contract.mounts.upper_bridge_waypoints_world_m[contract.orbits[index].id]:
            revised.append(vec(point))
        revised.append(anchor)
        check(revised.all(func(point: Vector3): return point.y-float(contract.mounts.support_radius_m)>=float(contract.mounts.upper_bridge_min_world_y_m)-0.000001),"upper bridge Y slab "+str(index))
        var paths: Array = []
        for point in revised: paths.append(arr(point))
        revision_rows.append({"id":contract.orbits[index].id,"path_world_m":paths})
        var own_distance := INF
        for point in curves[index]:
            if point.distance_to(anchor)<=float(contract.mounts.terminal_joint_radius_m): continue
            for step in revised.size()-1:
                own_distance=minf(own_distance,segment_gap(point,revised[step],revised[step+1]))
        # After removing the joint neighborhood, nearest admissible sample at the
        # boundary can be a full step away, rather than a half step.
        var own_allowance := 2.0*float(contract.orbits[index].radius_m)*PI/sample_count
        var own_gap := own_distance-float(contract.tube_support_radius_m)-float(contract.mounts.support_radius_m)-own_allowance-float(contract.mounts.numerical_margin_m)
        check(own_gap>float(contract.mounts.own_orbit_outside_terminal_joint_clearance_floor_m),"own ring outside intended terminal joint "+str(index))
        own_joint_rows.append({"id":contract.orbits[index].id,"terminal_joint_radius_m":contract.mounts.terminal_joint_radius_m,"clearance_outside_joint_lower_bound_m":own_gap})
        for other in contract.orbits.size():
            if other==index: continue
            var row := {"bridge":contract.orbits[index].id,"other_orbit":contract.orbits[other].id}
            for route_type in ["legacy","revised"]:
                var route: Array[Vector3] = legacy if route_type=="legacy" else revised
                var smallest := INF
                for point in curves[other]:
                    for step in route.size()-1:
                        smallest=minf(smallest,segment_gap(point,route[step],route[step+1]))
                var allowance := float(contract.orbits[other].radius_m)*PI/sample_count
                var lower := smallest-float(contract.tube_support_radius_m)-float(contract.mounts.support_radius_m)-allowance-float(contract.mounts.numerical_margin_m)
                row[route_type+"_center_distance_m"]=smallest
                row[route_type+"_support_gap_lower_bound_m"]=lower
            check(float(row.revised_support_gap_lower_bound_m)>=float(contract.mounts.nonconnected_orbit_clearance_floor_m),"nonconnected ring/bridge clearance "+str(index)+"/"+str(other))
            comparisons.append(row)
    var old_outer_third: Dictionary=comparisons.filter(func(row: Dictionary):return row.bridge=="orbit_outer" and row.other_orbit=="orbit_third")[0]
    check(float(old_outer_third.legacy_center_distance_m)<float(contract.tube_support_radius_m)+float(contract.mounts.support_radius_m),"reproduced legacy support intersection")
    var orbit_pair_bounds: Array = []
    for index in contract.orbits.size():
        for other in range(index+1,contract.orbits.size()):
            var bound := absf(float(contract.orbits[index].radius_m)-float(contract.orbits[other].radius_m))-2.0*float(contract.tube_support_radius_m)
            check(bound>=0.02,"orbit pair concentric sphere reverse-triangle bound")
            orbit_pair_bounds.append({"a":contract.orbits[index].id,"b":contract.orbits[other].id,"clearance_lower_bound_m":bound})
    world=Node3D.new()
    root.add_child(world)
    var actor := Node3D.new()
    world.add_child(actor)
    var core := StaticBody3D.new()
    core.collision_layer=int(audit.core_body.layer)
    core.collision_mask=int(audit.core_body.mask)
    world.add_child(core)
    core.position=vec(audit.core_body.position)
    var core_shape := CylinderShape3D.new()
    core_shape.radius=float(audit.core_body.radius)
    core_shape.height=float(audit.core_body.height)
    var core_collision := CollisionShape3D.new()
    core_collision.shape=core_shape
    core.add_child(core_collision)
    var target_script = load("res://interaction_target.gd")
    var targets: Array[Area3D] = []
    for item in audit.controls:
        var area := Area3D.new()
        area.name=String(item.path).get_file()
        area.collision_layer=int(item.layer)
        area.collision_mask=int(item.mask)
        world.add_child(area)
        area.position=vec(item.position)
        var shape := BoxShape3D.new()
        shape.size=vec(item.target_box)
        var collision := CollisionShape3D.new()
        collision.shape=shape
        area.add_child(collision)
        var component: Node=target_script.new()
        component.name="InteractionTarget"
        component.set("enabled",false)
        area.add_child(component)
        targets.append(area)
    await physics_frame
    await physics_frame
    var access: Array = []
    # Continuous-yaw solid enclosure: entire orbit+support assembly in a .601m sphere.
    # Collar/spindle and all bridge endpoints are inside; line segments stay inside by convexity.
    var envelope_radius := 0.601
    for row in revision_rows:
        for point in row.path_world_m:
            check(vec(point).distance_to(pivot)+float(contract.mounts.support_radius_m)<envelope_radius,"bridge endpoint in all-yaw enclosure")
    var collar_y: Array=contract.mounts.base_collar_world_y_m
    var collar_bound := sqrt(pow(float(contract.mounts.base_collar_outer_radius_m),2)+pow(float(collar_y[0])-pivot.y,2))
    var spindle_bound := sqrt(pow(float(contract.mounts.spindle_radius_m),2)+pow(float(contract.mounts.spindle_world_y_m[0])-pivot.y,2))
    check(collar_bound<envelope_radius and spindle_bound<envelope_radius,"collar/spindle in all-yaw enclosure")
    for orbit in contract.orbits:
        check(float(orbit.radius_m)+float(contract.tube_support_radius_m)<envelope_radius,"orbit in all-yaw enclosure")
    for area in targets:
        var component=area.get_node("InteractionTarget")
        component.set("enabled",true) # A hypothetical already-enabled onboarding step;no sequence simulation.
        var heading := Vector3(area.position.x,0,area.position.z).normalized()
        for angle in contract.access_probe.approach_offsets_degrees:
            var from := area.position+heading.rotated(Vector3.UP,deg_to_rad(float(angle)))*float(contract.access_probe.feet_offset_from_target_m)
            from.y=1.62
            actor.position=Vector3(from.x,0,from.z)
            var direction := (area.position-from).normalized()
            var to := from+direction*2.5
            var query := PhysicsRayQueryParameters3D.create(from,to,3)
            query.collide_with_areas=true
            query.hit_from_inside=true
            var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
            check(not hit.is_empty() and hit.collider==area,"native target query "+area.name+" "+str(angle))
            check(bool(component.call("is_available_to",actor)),"actual component enabled availability")
            var hit_position: Vector3=hit.get("position",area.position)
            var visual_gap := segment_gap(pivot,from,hit_position)-envelope_radius
            var capsule_gap := Vector2(from.x,from.z).length()-float(audit.core_body.radius)-0.35
            check(visual_gap>0.02,"continuous-yaw visual-enclosure ray gap")
            check(capsule_gap>0.02,"standpoint capsule/CoreBody radial gap")
            check(from.distance_to(hit_position)<=2.5,"ray reach unchanged")
            access.append({"target":area.name,"offset_degrees":angle,"camera_world_m":arr(from),"feet_world_m":[from.x,0,from.z],"native_hit":String(hit.collider.name) if not hit.is_empty() else "NONE","hit_world_m":arr(hit_position),"ray_distance_m":from.distance_to(hit_position),"continuous_yaw_visual_ray_clearance_lower_bound_m":visual_gap,"capsule_core_clearance_lower_bound_m":capsule_gap})
        component.set("enabled",false)
        check(not bool(component.call("is_available_to",actor)),"actual disabled component unavailable "+area.name)
    check(access.size()==20,"twenty fixed approach probes")
    var result := {"status":"PASS_RECONSTRUCTED_ACCESS_AND_MOUNT_BRIEF" if failures.is_empty() else "FAIL","assertions":assertions,"failures":failures,"native_bases":native_bases,"bridge_routes":revision_rows,"bridge_orbit_comparisons":comparisons,"orbit_pair_bounds":orbit_pair_bounds,"own_terminal_joint_checks":own_joint_rows,"access_queries":access,"all_yaw_visual_enclosure_radius_m":envelope_radius,"scope":"New measured v2 proposal;reconstructed target/CoreBody native queries and copied InteractionTarget availability. No FirstPersonPlayer/E input, ArchiveMain/gameplay/save/progression, production mesh, LFS or style acceptance"}
    var file := FileAccess.open(OS.get_environment("WLR_PROBE_RESULT"),FileAccess.WRITE)
    file.store_string(JSON.stringify(result,"  ")+"\n")
    file.close()
    print("WLR_MOUNT_ACCESS "+JSON.stringify({"status":result.status,"assertions":assertions,"failures":failures,"access_queries":access.size()}))
    world.queue_free()
    await process_frame
    quit(0 if failures.is_empty() else 1)
