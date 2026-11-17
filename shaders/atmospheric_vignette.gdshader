shader_type canvas_item;

// Fullscreen atmospheric post-processing overlay:
// - Cinematic warm dusk edge vignette
// - Pulsing crimson HORDE / low-HP danger vignette
// - Subtle high-velocity peripheral speed streaks

uniform float base_vignette : hint_range(0.0, 1.0) = 0.32;
uniform float danger_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float speed_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 vignette_color : source_color = vec4(0.04, 0.02, 0.07, 1.0);
uniform vec4 danger_color : source_color = vec4(0.92, 0.08, 0.12, 1.0);

float hash(float n) {
	return fract(sin(n) * 43758.5453123);
}

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered * vec2(1.35, 1.45));
	
	// Base dusk edge vignette
	float vig = smoothstep(0.45, 0.98, dist) * base_vignette;
	
	// Pulsing crimson danger vignette (stronger on left edge where RearHorde pursues)
	float left_bias = smoothstep(0.65, 0.0, UV.x) * 0.35;
	float pulse = 0.65 + 0.35 * sin(TIME * 8.5);
	float danger_vig = (smoothstep(0.35, 0.92, dist) + left_bias) * danger_intensity * pulse;
	
	// Peripheral horizontal speed lines during high velocity / recoil vaults
	float speed_streak = 0.0;
	if (speed_intensity > 0.05 && dist > 0.52) {
		float row = floor(UV.y * 90.0);
		float rnd = hash(row + floor(TIME * 18.0));
		if (rnd > 0.92) {
			float streak_x = fract(UV.x * 2.0 + TIME * 4.5 + rnd);
			speed_streak = smoothstep(0.52, 0.85, dist) * smoothstep(0.0, 0.3, streak_x) * speed_intensity * 0.22;
		}
	}
	
	vec3 final_col = mix(vignette_color.rgb, danger_color.rgb, clamp(danger_vig / max(vig + danger_vig, 0.001), 0.0, 1.0));
	final_col += vec3(1.0, 0.82, 0.55) * speed_streak;
	float final_alpha = clamp(vig + danger_vig * 0.65 + speed_streak, 0.0, 0.78);
	
	COLOR = vec4(final_col, final_alpha);
}
