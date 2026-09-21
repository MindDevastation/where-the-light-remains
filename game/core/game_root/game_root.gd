extends Node

@onready var world_slot: Node3D = $WorldSlot

func _ready() -> void:
    SceneRouter.bind_world_slot(world_slot)
    EventBus.stage_changed.emit(GameState.current_stage_id)
    # No preload/type dependency on development resources in the shipping path.
    if OS.is_debug_build() and App.BUILD_FLAVOR == "development" and OS.get_cmdline_user_args().has("--dev-tools"):
        var tools_path := "res://core/debug/debug_overlay.tscn"
        if ResourceLoader.exists(tools_path):
            var tools_scene := load(tools_path) as PackedScene
            if tools_scene != null:
                add_child(tools_scene.instantiate())
        else:
            push_warning("Панель разработки запрошена, но ее ресурс отсутствует.")
