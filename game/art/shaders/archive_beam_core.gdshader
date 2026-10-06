shader_type spatial;
render_mode unshaded, shadows_disabled, cull_back;

instance uniform vec4 beam_tint : source_color = vec4(0.3, 0.78, 1.0, 1.0);
instance uniform float beam_energy : hint_range(0.0, 3.0) = 1.4;

void fragment() {
    ALBEDO = beam_tint.rgb;
    EMISSION = beam_tint.rgb * beam_energy;
}
