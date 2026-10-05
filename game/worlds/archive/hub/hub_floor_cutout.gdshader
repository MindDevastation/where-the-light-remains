shader_type spatial;

// Local graybox surface only: the unchanged Hub collider remains continuous.
// Corridor tiles own X=[-2,2], Z<=-8, avoiding coplanar Hub skin in that strip.
uniform vec4 albedo : source_color = vec4(0.13, 0.18, 0.24, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.9;
uniform float opening_half_width = 2.0;
uniform float opening_front_z = -8.0;
varying vec3 floor_position;

void vertex() {
    floor_position = VERTEX;
}

void fragment() {
    if (abs(floor_position.x) <= opening_half_width && floor_position.z <= opening_front_z) {
        discard;
    }
    ALBEDO = albedo.rgb;
    ROUGHNESS = roughness;
}
