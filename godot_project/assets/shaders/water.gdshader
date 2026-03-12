shader_type canvas_item;

uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform float wave_amplitude : hint_range(0.0, 10.0) = 2.0;
uniform float wave_frequency : hint_range(0.0, 20.0) = 8.0;
uniform vec4 color_top : source_color = vec4(0.2, 0.5, 0.8, 0.8);
uniform vec4 color_bottom : source_color = vec4(0.06, 0.2, 0.4, 0.9);

void fragment() {
    vec2 uv = UV;

    // Wave distortion
    uv.x += sin(uv.y * wave_frequency + TIME * wave_speed) * wave_amplitude * TEXTURE_PIXEL_SIZE.x;
    uv.y += cos(uv.x * wave_frequency * 0.7 + TIME * wave_speed * 0.8) * wave_amplitude * 0.5 * TEXTURE_PIXEL_SIZE.y;

    vec4 tex = texture(TEXTURE, uv);

    // Gradient from top to bottom
    vec4 water_color = mix(color_top, color_bottom, UV.y);

    COLOR = tex * water_color;
}
