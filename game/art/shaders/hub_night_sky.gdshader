shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque, fog_disabled;

// Static bounded Hub roof backing; own local dome axes. No lighting or time ownership.
uniform vec3 dome_axes = vec3(7.46, 3.075, 7.46);
uniform float spring_y = 6.20;
varying vec3 local_position;

float random_cell(vec2 cell) {
    return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
    local_position = VERTEX;
}

void fragment() {
    vec3 direction = normalize(vec3(local_position.x / dome_axes.x,
        (local_position.y - spring_y) / dome_axes.y, local_position.z / dome_axes.z));
    float altitude = clamp(direction.y, 0.0, 1.0);
    vec2 uv = vec2(atan(direction.z, direction.x) / 6.28318530718 + 0.5,
        asin(altitude) / 1.57079632679);
    vec2 grid = uv * vec2(128.0, 48.0);
    vec2 cell = floor(grid);
    cell.x = mod(cell.x, 128.0);
    float seed = random_cell(cell);
    vec2 center = vec2(0.2) + vec2(random_cell(cell + 19.0),
        random_cell(cell + 47.0)) * 0.6;
    float radius = mix(0.06, 0.12, random_cell(cell + 83.0));
    float star = (1.0 - smoothstep(radius * 0.3, radius,
        length(fract(grid) - center))) * step(0.967, seed);
    star *= smoothstep(0.08, 0.18, altitude)
        * (1.0 - smoothstep(0.985, 0.999, altitude));
    vec3 night = mix(vec3(0.018, 0.028, 0.072),
        vec3(0.018, 0.045, 0.13), altitude);
    ALBEDO = night + vec3(0.38, 0.47, 0.65) * star;
}
