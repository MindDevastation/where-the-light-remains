shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded, shadows_disabled;

uniform vec3 dust_tint : source_color = vec3(0.74, 0.69, 0.58);
uniform float opacity : hint_range(0.0, 0.3) = 0.22;

void vertex() {
    // Camera-facing quads, retaining the particle's authored instance scale.
    mat4 facing = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
    facing[0].xyz *= length(MODEL_MATRIX[0].xyz);
    facing[1].xyz *= length(MODEL_MATRIX[1].xyz);
    facing[2].xyz *= length(MODEL_MATRIX[2].xyz);
    MODELVIEW_MATRIX = VIEW_MATRIX * facing;
}

void fragment() {
    float radius = length(UV - vec2(0.5)) * 2.0;
    float feather = 1.0 - smoothstep(0.12, 1.0, radius);
    ALBEDO = dust_tint * COLOR.rgb;
    ALPHA = feather * feather * opacity * COLOR.a;
}
