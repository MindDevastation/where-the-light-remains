shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled, cull_back;

instance uniform vec4 beam_tint : source_color = vec4(0.3, 0.78, 1.0, 1.0);
instance uniform float beam_energy : hint_range(0.0, 3.0) = 1.4;

void fragment() {
    float facing = abs(dot(normalize(NORMAL), normalize(VIEW)));
    ALBEDO = beam_tint.rgb * min(beam_energy, 1.4);
    ALPHA = pow(facing, 2.0) * 0.18 * beam_tint.a;
}
