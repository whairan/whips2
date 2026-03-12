shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 0.85, 0.0, 0.8);
uniform float outline_width : hint_range(0.0, 4.0) = 1.0;
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;
uniform bool enabled = false;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    if (enabled && tex.a < 0.5) {
        // Check neighbors for outline
        float alpha_sum = 0.0;
        vec2 pixel_size = TEXTURE_PIXEL_SIZE * outline_width;

        alpha_sum += texture(TEXTURE, UV + vec2(pixel_size.x, 0.0)).a;
        alpha_sum += texture(TEXTURE, UV + vec2(-pixel_size.x, 0.0)).a;
        alpha_sum += texture(TEXTURE, UV + vec2(0.0, pixel_size.y)).a;
        alpha_sum += texture(TEXTURE, UV + vec2(0.0, -pixel_size.y)).a;

        if (alpha_sum > 0.0) {
            float pulse = (sin(TIME * pulse_speed) + 1.0) * 0.5 * 0.3 + 0.7;
            COLOR = outline_color * pulse;
        } else {
            COLOR = tex;
        }
    } else {
        COLOR = tex;
    }
}
