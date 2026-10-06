extends Node3D
## Local Hearth presentation only. Visibility remains owned by ArchiveMain.

const GOLD = preload("res://art/materials/m_archive_emissive_gold.tres")
const SIDES := 8
const PROFILE := [Vector2(-.36, .065), Vector2(-.24, .14),
    Vector2(-.08, .13), Vector2(.08, .08), Vector2(.22, .035)]

var _phase := 0.0
var _lobes: Array[MeshInstance3D] = []
var _rest: Array[Transform3D] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_PAUSABLE
    var mesh := _make_mesh()
    for index in 3:
        var lobe := MeshInstance3D.new()
        lobe.name = "Tongue%d" % index
        lobe.mesh = mesh
        lobe.material_override = GOLD
        lobe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
        add_child(lobe)
        if index == 1:
            lobe.scale = Vector3(.65, .68, .65)
            lobe.position = Vector3(-.105, -.115, .015)
            lobe.rotation.y = 2.0
        elif index == 2:
            lobe.scale = Vector3(.55, .8, .55)
            lobe.position = Vector3(.10, -.072, -.025)
            lobe.rotation.y = -1.8
        _lobes.append(lobe)
        _rest.append(lobe.transform)
    visibility_changed.connect(_sync_visibility)
    _sync_visibility()

func _sync_visibility() -> void:
    # Every projection starts from a reproducible quiet pose. No burst, signal,
    # audio request, light or save mutation is owned by this effect.
    _phase = 0.0
    for index in _lobes.size():
        _lobes[index].transform = _rest[index]
    set_process(is_visible_in_tree())

func _process(delta: float) -> void:
    if not is_visible_in_tree():
        return
    _phase = fmod(_phase + delta, TAU * 10.0)
    for index in _lobes.size():
        var pose := _rest[index]
        var sway := sin(_phase * .8 + index * 1.7) * .018
        pose.basis = pose.basis.scaled_local(Vector3(1.0, 1.0 + sway, 1.0))
        pose.origin.x += sway * .35
        _lobes[index].transform = pose

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
