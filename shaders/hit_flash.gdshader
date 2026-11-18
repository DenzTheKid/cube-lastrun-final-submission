shader_type canvas_item;

// Tactile damage / bullet impact hit-flash shader with optional emissive rim outline.
// Set flash_modifier = 1.0 for 2-3 frames on bullet impact or player hurt.

uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 rim_color : source_color = vec4(0.28, 0.88, 1.0, 1.0);

// Optional skin palette swap (disabled by default so zombies/fx stay untouched)
uniform float skin_swap_enabled : hint_range(0.0, 1.0) = 0.0;
uniform float skin_y_limit : hint_range(0.0, 1.0) = 1.0;
uniform vec4 band_hi_color : source_color = vec4(1.0, 0.45, 0.49, 1.0);
uniform vec4 band_base_color : source_color = vec4(0.92, 0.18, 0.25, 1.0);
uniform vec4 band_sh_color : source_color = vec4(0.57, 0.08, 0.14, 1.0);

// 0.0 = off, 1.0 = player spritesheet exact visor colors, 2.0 = showcase UI visor box
uniform float visor_swap_enabled : hint_range(0.0, 2.0) = 0.0;
uniform vec4 visor_uv_bounds = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 visor_hi_color : source_color = vec4(0.0, 0.96, 1.0, 1.0);
uniform vec4 visor_base_color : source_color = vec4(0.30, 0.78, 0.87, 1.0);
uniform vec4 visor_core_color : source_color = vec4(0.88, 1.0, 1.0, 1.0);

varying vec4 v_modulate;

void vertex() {
	v_modulate = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 swapped_tex = tex.rgb;
	bool did_swap = false;
	float max_gb = max(tex.g, tex.b);

	if (skin_swap_enabled > 0.5 && tex.a > 0.1 && UV.y <= skin_y_limit) {
		// Rose/crimson headband tones have B >= G - 0.04 (excludes wood shotgun grip where G >> B).
		// On showcase (skin_y_limit < 0.9), also catch the upper orange headband knot (UV.y < 0.36).
		bool is_rose_band = tex.r > max_gb + 0.16 && (tex.b + 0.04 >= tex.g || (skin_y_limit < 0.9 && UV.y < 0.36));
		if (is_rose_band) {
			did_swap = true;
			if (tex.r >= 0.96 && max_gb >= 0.40) {
				swapped_tex = band_hi_color.rgb;
			} else if (tex.r >= 0.70) {
				swapped_tex = band_base_color.rgb;
			} else {
				swapped_tex = band_sh_color.rgb;
			}
		}
	}

	if (visor_swap_enabled > 0.5 && tex.a > 0.1) {
		if (visor_swap_enabled < 1.5) {
			// Cube Player spritesheet: VISOR_GLOW (0,245,255) & VISOR_CORE (225..230,255,255)
			if (tex.r < 0.08 && tex.g > 0.88 && tex.b > 0.92) {
				swapped_tex = visor_hi_color.rgb;
				did_swap = true;
			} else if (tex.r > 0.82 && tex.g > 0.95 && tex.b > 0.95) {
				swapped_tex = visor_core_color.rgb;
				did_swap = true;
			}
		} else {
			// Single-card showcase hero eyes inside visor region
			if (UV.x >= visor_uv_bounds.x && UV.y >= visor_uv_bounds.y && UV.x <= visor_uv_bounds.z && UV.y <= visor_uv_bounds.w) {
				if (tex.b > 0.80 && tex.g > 0.70) {
					did_swap = true;
					if (tex.r > 0.78) {
						swapped_tex = visor_core_color.rgb;
					} else if (tex.r > 0.42) {
						swapped_tex = visor_hi_color.rgb;
					} else {
						swapped_tex = visor_base_color.rgb;
					}
				}
			}
		}
	}

	vec3 col = did_swap ? (swapped_tex * v_modulate.rgb) : (tex.rgb * COLOR.rgb);
	float alpha = did_swap ? (tex.a * v_modulate.a) : (tex.a * COLOR.a);
	
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
