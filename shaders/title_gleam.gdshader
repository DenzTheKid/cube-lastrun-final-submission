shader_type canvas_item;

// Metallic bevel & diagonal light gleam sweep shader for CUBE: LAST RUN title logo.

uniform vec4 gleam_color : source_color = vec4(1.0, 0.95, 0.75, 1.0);
uniform float sweep_speed : hint_range(0.1, 5.0) = 0.85;
uniform float gleam_width : hint_range(0.02, 0.3) = 0.10;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 col = tex.rgb * COLOR.rgb;
	float alpha = tex.a * COLOR.a;
	
	// Periodic diagonal gleam band sweeping across letters
	float cycle = mod(TIME * sweep_speed, 3.2) - 0.6;
	float diag = UV.x + UV.y * 0.35;
	float gleam = 1.0 - smoothstep(0.0, gleam_width, abs(diag - cycle));
	
	col = mix(col, gleam_color.rgb, gleam * 0.65 * alpha);
	COLOR = vec4(col, alpha);
}
