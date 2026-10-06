extends "res://tests/archive_dome_smoke.gd"
## Apply the same imported-geometry/capsule oracle to the actual shipping world.

func _ready() -> void:
    _world_scene = preload("res://worlds/archive/archive_main.tscn")
    _dome_path = ^"Wing01/Room/RoofPresentation/DomeCoverage"
    _marker = "ARCHIVE_ROOF_INTEGRATION"
    _run.call_deferred()

func _inspect_world(world: ArchiveMain, dome: Node3D) -> void:
    var roof := dome.get_parent() as Node3D
    _check(roof.name == "RoofPresentation" and roof.get_child_count() == 2, "Exactly one explicit two-part roof assembly")
    _check(roof.position.is_equal_approx(Vector3(0,4,-21)) and roof.scale == Vector3.ONE and roof.get_script() == null,
        "Static unscaled shipping assembly at the accepted wall top")
    var owners := 0
    for node: Node in world.find_children("*","Node3D",true,false):
        if node.scene_file_path == "res://worlds/archive/wing01_dome_coverage.tscn":
            owners += 1
    _check(owners == 1 and dome.is_visible_in_tree(), "One visible dome owner in actual shipping world")
    for type_name in ["CollisionObject3D","Light3D","WorldEnvironment"]:
        _check(roof.find_children("*",type_name,true,false).is_empty(), "Whole shipping roof adds no " + type_name)
    var structure := roof.get_node("Structure") as Node3D
    _check(structure.get_child_count() == 3 and structure.transform.is_equal_approx(Transform3D.IDENTITY), "Unscaled original ribs and transition")
    var triangles := 0
    var surfaces := 0
    for part: Node3D in structure.get_children():
        var visual := part.get_node("Art").get_child(0) as MeshInstance3D
        triangles += int(visual.mesh.get_faces().size()/3)
        surfaces += visual.mesh.get_surface_count()
        _check((part.get_node("Crown") as Node3D).global_position.is_equal_approx(Vector3(0,9.5,-21)), "Original crown meets new coverage " + str(part.name))
    _check(triangles == 6824 and surfaces == 9, "Original structure imports unchanged beside coverage")
