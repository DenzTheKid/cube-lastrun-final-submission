shader_type canvas_item;

// Tactile damage / bullet impact hit-flash shader with optional emissive rim outline.
// Set flash_modifier = 1.0 for 2-3 frames on bullet impact or player hurt.

uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 rim_color : source_color = vec4(0.28, 0.88, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 col = tex.rgb * COLOR.rgb;
	float alpha = tex.a * COLOR.a;
	
	// Subtle top-right rim highlight when rim_strength > 0
	if (rim_strength > 0.0 && alpha > 0.1) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float neighbor_up = texture(TEXTURE, UV + vec2(0.0, -px.y)).a;
		float neighbor_right = texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
		if (neighbor_up < 0.1 || neighbor_right < 0.1) {
			col = mix(col, rim_color.rgb, rim_strength);
		}
	}
	
	// Pure white / custom hit-flash override
	col = mix(col, flash_color.rgb, flash_modifier);
	
	COLOR = vec4(col, alpha);
}
