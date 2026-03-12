shader_type canvas_item;

// 0 = none, 1 = deuteranopia, 2 = protanopia, 3 = tritanopia
uniform int mode : hint_range(0, 3) = 0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    if (mode == 1) {
        // Deuteranopia (green-blind)
        float r = 0.625 * color.r + 0.375 * color.g;
        float g = 0.7 * color.r + 0.3 * color.g;
        float b = 0.3 * color.g + 0.7 * color.b;
        COLOR = vec4(r, g, b, color.a);
    } else if (mode == 2) {
        // Protanopia (red-blind)
        float r = 0.567 * color.r + 0.433 * color.g;
        float g = 0.558 * color.r + 0.442 * color.g;
        float b = 0.242 * color.g + 0.758 * color.b;
        COLOR = vec4(r, g, b, color.a);
    } else if (mode == 3) {
        // Tritanopia (blue-blind)
        float r = 0.95 * color.r + 0.05 * color.g;
        float g = 0.433 * color.g + 0.567 * color.b;
        float b = 0.475 * color.g + 0.525 * color.b;
        COLOR = vec4(r, g, b, color.a);
    } else {
        COLOR = color;
    }
}
