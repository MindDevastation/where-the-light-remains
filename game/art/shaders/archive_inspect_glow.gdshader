shader_type spatial;
render_mode blend_add, depth_draw_never, cull_back, unshaded, shadows_disabled;

uniform vec3 wash_color : source_color = vec3(0.78, 0.52, 0.22);
uniform float wash_alpha : hint_range(0.0, 0.1) = 0.055;

void fragment() {
    ALBEDO = wash_color;
    ALPHA = wash_alpha;
}
