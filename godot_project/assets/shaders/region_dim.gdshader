shader_type canvas_item;

uniform float dim_amount : hint_range(0.0, 1.0) = 0.0;
uniform float desaturate_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);

    // Desaturate
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(color.rgb, vec3(gray), desaturate_amount);

    // Dim
    color.rgb *= (1.0 - dim_amount);

    COLOR = color;
}
