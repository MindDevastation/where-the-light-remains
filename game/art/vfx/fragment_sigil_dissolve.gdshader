shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform float amount : hint_range(0.0, 1.0) = 1.0;
uniform vec4 edge_color : source_color = vec4(0.98, 0.79, 0.42, 1.0);

float cell_noise(vec2 cell) {
    return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    // Fragment COLOR already includes the texture and CanvasItem modulation.
    vec4 original = COLOR;
    float coverage = 1.0;
    float edge = 0.0;
    if (amount <= 0.0001) {
        coverage = 0.0;
    } else if (amount < 0.9999) {
        float threshold = clamp(mix(cell_noise(floor(UV * 14.0)), 1.0 - UV.y, 0.55), 0.02, 0.98);
        coverage = smoothstep(threshold - 0.035, threshold + 0.035, amount);
        edge = max(0.0, 1.0 - abs(amount - threshold) / 0.06) * coverage;
    }
    COLOR = vec4(original.rgb + edge_color.rgb * edge * 0.18, original.a * coverage);
}
