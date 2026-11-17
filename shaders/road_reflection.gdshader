shader_type canvas_item;

// Wet asphalt puddle & horizon rim reflection shader for road surface polish.

uniform vec4 puddle_tint : source_color = vec4(0.95, 0.48, 0.22, 0.35);
uniform float shimmer_speed : hint_range(0.0, 10.0) = 3.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 col = tex.rgb * COLOR.rgb;
	
	// Detect dark asphalt pixels and add subtle horizon amber specular reflection
	float luma = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
	if (luma < 0.28 && tex.a > 0.5) {
		float wave = 0.5 + 0.5 * sin(UV.x * 45.0 + TIME * shimmer_speed);
		col = mix(col, puddle_tint.rgb, wave * puddle_tint.a * 0.35);
	}
	
	COLOR = vec4(col, tex.a * COLOR.a);
}
