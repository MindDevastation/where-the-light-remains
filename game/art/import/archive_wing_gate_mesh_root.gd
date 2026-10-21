@tool
extends EditorScenePostImport
## This GLB's single unit mesh is the existing gate's MeshInstance3D target.
func _post_import(scene: Node) -> Object:
    var visuals := scene.find_children("*","MeshInstance3D",true,false)
    assert(visuals.size()==1)
    var result := visuals[0] as MeshInstance3D
    assert(result.transform.is_equal_approx(Transform3D.IDENTITY))
    assert((scene as Node3D).transform.is_equal_approx(Transform3D.IDENTITY))
    result.get_parent().remove_child(result)
    result.owner = null
    scene.free()
    return result
