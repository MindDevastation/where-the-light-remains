extends SceneTree
## Rebuild the shared opaque Hearth VFX mesh; no Blender or gameplay ownership.

const SIDES := 8
const PROFILE := [Vector2(-.36, .065), Vector2(-.24, .14),
    Vector2(-.08, .13), Vector2(.08, .08), Vector2(.22, .035)]

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1:
        push_error("Expected one absolute .tres output path")
        quit(1)
        return
    var mesh := _make_mesh()
    var error := ResourceSaver.save(mesh, args[0])
    if error == OK:
        print("HEARTH_FLAME_MESH PASS: 80 triangles")
    quit(0 if error == OK else 1)

func _make_mesh() -> ArrayMesh:
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    surface.set_smooth_group(0)
    var rings: Array[PackedVector3Array] = []
    for section: Vector2 in PROFILE:
        var ring := PackedVector3Array()
        for index in SIDES:
            var angle := TAU * float(index) / SIDES
            var lean := pow((section.x + .36) / .72, 2.0) * .07
            ring.append(Vector3(cos(angle) * section.y + lean,
                section.x, sin(angle) * section.y * .72))
        rings.append(ring)
    for row in rings.size() - 1:
        for index in SIDES:
            var next := (index + 1) % SIDES
            _triangle(surface, rings[row][index], rings[row + 1][index], rings[row][next])
            _triangle(surface, rings[row][next], rings[row + 1][index], rings[row + 1][next])
    for index in SIDES:
        var next := (index + 1) % SIDES
        _triangle(surface, rings[0][next], Vector3(0, -.36, 0), rings[0][index])
        _triangle(surface, rings[-1][index], Vector3(.07, .36, 0), rings[-1][next])
    surface.generate_normals()
    return surface.commit()

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    surface.add_vertex(a)
    surface.add_vertex(b)
    surface.add_vertex(c)
