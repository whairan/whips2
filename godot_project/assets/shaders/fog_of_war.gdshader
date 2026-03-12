shader_type canvas_item;

uniform sampler2D fog_mask : hint_default_white;
uniform float dissolve_edge : hint_range(0.01, 0.2) = 0.05;
uniform vec4 fog_color : source_color = vec4(0.03, 0.06, 0.03, 1.0);
uniform vec4 edge_glow : source_color = vec4(0.3, 1.0, 0.3, 0.4);
uniform float reveal_progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 scene = texture(TEXTURE, UV);
    float mask_value = texture(fog_mask, UV).r;

    // Animate reveal with progress
    float adjusted_mask = mask_value - reveal_progress;
    adjusted_mask = clamp(adjusted_mask, 0.0, 1.0);

    // Smooth edge
    float fog_amount = smoothstep(0.0, dissolve_edge, adjusted_mask);
    float edge = smoothstep(0.0, dissolve_edge, adjusted_mask)
               - smoothstep(dissolve_edge, dissolve_edge * 2.0, adjusted_mask);

    COLOR = mix(scene, fog_color, fog_amount);
    COLOR += edge_glow * edge;
    COLOR.a = scene.a;
}
