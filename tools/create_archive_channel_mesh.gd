extends SceneTree
## Offline native VFX authoring. Runtime instances share these immutable meshes.

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3) -> void:
    if Plane(a, b, c).normal.dot(outward) < 0.0:
        var swap := b
        b = c
        c = swap
    var normal := Plane(a, b, c).normal
    for point: Vector3 in [a, b, c]:
        surface.set_normal(normal)
        # One metre per UV repeat, consistent across the shared iron rails.
        if absf(normal.y) >= absf(normal.x) and absf(normal.y) >= absf(normal.z):
            surface.set_uv(Vector2(point.x, point.z))
        elif absf(normal.x) >= absf(normal.z):
            surface.set_uv(Vector2(point.z, point.y))
        else:
            surface.set_uv(Vector2(point.x, point.y))
        surface.add_vertex(point)


func _profile(width: float, height: float, bevel: float, z: float, offset: float) -> Array[Vector3]:
    var x := width * 0.5
    var y := height * 0.5
    return [Vector3(-x + bevel + offset, -y, z), Vector3(x - bevel + offset, -y, z),
        Vector3(x + offset, -y + bevel, z), Vector3(x + offset, y - bevel, z),
        Vector3(x - bevel + offset, y, z), Vector3(-x + bevel + offset, y, z),
        Vector3(-x + offset, y - bevel, z), Vector3(-x + offset, -y + bevel, z)]


func _extrusion(surface: SurfaceTool, width: float, height: float, offset: float) -> void:
    var end := 0.002
    var rings: Array[Array] = [
        _profile(width - end * 2.0, height - end * 2.0, 0.003, -2.35, offset),
        _profile(width, height, 0.003, -2.35 + end, offset),
        _profile(width, height, 0.003, 2.35 - end, offset),
        _profile(width - end * 2.0, height - end * 2.0, 0.003, 2.35, offset)]
    for ring in 3:
        for index in 8:
            var next := (index + 1) % 8
            var a: Vector3 = rings[ring][index]
            var b: Vector3 = rings[ring][next]
            var c: Vector3 = rings[ring + 1][next]
            var d: Vector3 = rings[ring + 1][index]
            var outward := (a + b + c + d) * 0.25 - Vector3(offset, 0, 0)
            # Bevel faces also slope toward their respective end cap.
            if ring == 1:
                outward.z = 0.0
            _triangle(surface, a, b, c, outward)
            _triangle(surface, a, c, d, outward)
    for index in range(1, 7):
        _triangle(surface, rings[0][0], rings[0][index], rings[0][index + 1], Vector3.BACK * -1.0)
        _triangle(surface, rings[3][0], rings[3][index], rings[3][index + 1], Vector3.BACK)


func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1 or not args[0].is_absolute_path() or DirAccess.dir_exists_absolute(args[0]):
        push_error("Expected one new absolute output directory")
        quit(1)
        return
    if DirAccess.make_dir_recursive_absolute(args[0]) != OK:
        quit(1)
        return
    var total := 0
    for part: String in ["core", "rails"]:
        var surface := SurfaceTool.new()
        surface.begin(Mesh.PRIMITIVE_TRIANGLES)
        if part == "core":
            _extrusion(surface, 0.12, 0.03, 0.0)
        else:
            _extrusion(surface, 0.03, 0.028, -0.075)
            _extrusion(surface, 0.03, 0.028, 0.075)
        surface.generate_tangents()
        var mesh := surface.commit()
        mesh.resource_name = "Archive channel " + part + " v1"
        var count := int((mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3)
        total += count
        if ResourceSaver.save(mesh, args[0].path_join("archive_channel_" + part + "_mesh.tres")) != OK:
            quit(1)
            return
        print("ARCHIVE_CHANNEL_MESH PART: ", part, "; triangles=", count, "; bounds=", mesh.get_aabb())
    if total > 200:
        push_error("Channel exceeds its 200-triangle local ceiling")
        quit(1)
        return
    print("ARCHIVE_CHANNEL_MESH PASS: ", total, " triangles per channel")
    quit(0)
