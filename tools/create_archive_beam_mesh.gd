extends SceneTree
## Persist two shared beam meshes; no production scene builds meshes at entry.

func _initialize() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() != 1 or DirAccess.dir_exists_absolute(args[0]):
        push_error("Expected one new absolute output directory")
        quit(1)
        return
    if DirAccess.make_dir_recursive_absolute(args[0]) != OK:
        quit(1)
        return
    var total := 0
    for part: String in ["core","halo"]:
        var cylinder := CylinderMesh.new()
        cylinder.height = 1.0
        cylinder.top_radius = .017 if part == "core" else .05
        cylinder.bottom_radius = cylinder.top_radius
        cylinder.radial_segments = 12
        cylinder.rings = 0
        cylinder.cap_top = part == "core"
        cylinder.cap_bottom = part == "core"
        var mesh := ArrayMesh.new()
        var arrays := cylinder.surface_get_arrays(0)
        mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
        var count := int((arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size()/3)
        total += count
        if ResourceSaver.save(mesh,args[0].path_join("archive_beam_"+part+"_mesh.tres")) != OK:
            quit(1)
            return
        print("ARCHIVE_BEAM_MESH PART: ",part,"; triangles=",count,"; bounds=",mesh.get_aabb())
    if total > 100:
        push_error("Beam mesh pair exceeds its 100-triangle ceiling")
        quit(1)
        return
    print("ARCHIVE_BEAM_MESH PASS: ",total," triangles per core+halo pair")
    quit(0)
