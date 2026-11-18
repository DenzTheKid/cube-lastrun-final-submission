shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(0.96, 0.16, 0.24, 1.0);
uniform float pulse_alpha : hint_range(0.0, 0.7) = 0.0;
uniform float edge_width : hint_range(0.01, 0.2) = 0.065;

void fragment() {
	vec2 d = min(UV, vec2(1.0) - UV);
	float min_edge = min(d.x, d.y * 0.88);
	float rim = 1.0 - smoothstep(0.0, edge_width, min_edge);
	float corner = smoothstep(0.42, 0.98, length((UV - vec2(0.5)) * vec2(1.42, 1.78)));
	float mask = clamp(rim * 0.92 + corner * 0.30, 0.0, 1.0);
	COLOR = vec4(tint_color.rgb, mask * pulse_alpha);
}
