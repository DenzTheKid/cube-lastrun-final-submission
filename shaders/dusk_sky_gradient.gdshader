shader_type canvas_item;

// Atmospheric golden-hour / blood-orange dusk sky shader for CUBE: LAST RUN.
// Renders a 4-stop vertical gradient, volumetric glowing sun disc with heat-haze
// distortion, drifting high-altitude cirrus clouds, and twinkling zenith stars.

uniform vec4 zenith_color : source_color = vec4(0.059, 0.063, 0.129, 1.0);   // #0f1021 Deep twilight indigo
uniform vec4 upper_mid_color : source_color = vec4(0.169, 0.098, 0.239, 1.0); // #2b193d Bruised purple
uniform vec4 lower_mid_color : source_color = vec4(0.478, 0.157, 0.196, 1.0); // #7a2832 Burnt crimson
uniform vec4 horizon_color : source_color = vec4(0.949, 0.549, 0.220, 1.0);   // #f28c38 Molten amber/gold
uniform vec4 sun_core_color : source_color = vec4(1.0, 0.94, 0.72, 1.0);
uniform vec4 sun_halo_color : source_color = vec4(1.0, 0.48, 0.18, 0.65);

uniform vec2 sun_uv_pos = vec2(0.76, 0.42);
uniform float sun_radius : hint_range(0.02, 0.25) = 0.095;
uniform float haze_strength : hint_range(0.0, 0.02) = 0.004;
uniform float cloud_speed : hint_range(0.0, 0.2) = 0.015;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += amp * value_noise(p);
		p *= 2.03;
		amp *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	
	// Multi-stop vertical atmospheric sky gradient
	vec3 sky_col;
	if (uv.y < 0.30) {
		float t = smoothstep(0.0, 0.30, uv.y);
		sky_col = mix(zenith_color.rgb, upper_mid_color.rgb, t);
	} else if (uv.y < 0.62) {
		float t = smoothstep(0.30, 0.62, uv.y);
		sky_col = mix(upper_mid_color.rgb, lower_mid_color.rgb, t);
	} else {
		float t = smoothstep(0.62, 1.0, uv.y);
		sky_col = mix(lower_mid_color.rgb, horizon_color.rgb, t);
	}
	
	// Faint twinkling stars in upper zenith
	if (uv.y < 0.36) {
		vec2 star_grid = floor(uv * vec2(160.0, 90.0));
		float star_seed = hash21(star_grid);
		if (star_seed > 0.992) {
			float twinkle = 0.5 + 0.5 * sin(TIME * (2.0 + star_seed * 6.0) + star_seed * 30.0);
			float zenith_fade = 1.0 - smoothstep(0.15, 0.36, uv.y);
			sky_col += vec3(0.95, 0.92, 1.0) * twinkle * zenith_fade * 0.85;
		}
	}
	
	// Volumetric Dusk Sun with subtle atmospheric heat-haze distortion
	vec2 aspect_uv = vec2(uv.x * (480.0 / 270.0), uv.y);
	vec2 aspect_sun = vec2(sun_uv_pos.x * (480.0 / 270.0), sun_uv_pos.y);
	float haze_wave = sin(uv.y * 95.0 + TIME * 3.2) * haze_strength * smoothstep(0.25, 0.75, uv.y);
	vec2 distorted_uv = aspect_uv + vec2(haze_wave, 0.0);
	
	float dist_to_sun = length(distorted_uv - aspect_sun);
	
	// Outer atmospheric scatter glow
	float sun_halo = exp(-dist_to_sun * 5.2) * 0.75;
	sky_col += sun_halo_color.rgb * sun_halo;
	
	// Crisp low-hanging sun disc with scanline dusk banding
	float sun_disc = 1.0 - smoothstep(sun_radius - 0.008, sun_radius + 0.004, dist_to_sun);
	float sun_banding = 1.0;
	if (uv.y > sun_uv_pos.y) {
		float band_phase = sin((uv.y - sun_uv_pos.y) * 260.0);
		sun_banding = step(-0.25, band_phase);
	}
	vec3 disc_col = mix(horizon_color.rgb, sun_core_color.rgb, 1.0 - clamp((uv.y - (sun_uv_pos.y - sun_radius)) / (sun_radius * 2.0), 0.0, 1.0));
	sky_col = mix(sky_col, disc_col, sun_disc * sun_banding);
	
	// Drifting high-altitude cirrus clouds across middle sky & sun disc
	if (uv.y > 0.18 && uv.y < 0.78) {
		vec2 cloud_uv = vec2(uv.x * 3.5 + TIME * cloud_speed, uv.y * 12.0);
		float n = fbm(cloud_uv);
		float cloud_mask = smoothstep(0.56, 0.78, n) * sin(clamp((uv.y - 0.18) / 0.60, 0.0, 1.0) * 3.14159);
		vec3 cloud_lit = mix(vec3(0.32, 0.12, 0.18), vec3(1.0, 0.62, 0.28), exp(-dist_to_sun * 3.5));
		sky_col = mix(sky_col, cloud_lit, cloud_mask * 0.45);
	}
	
	// Horizon molten glow bloom at base
	float horizon_bloom = smoothstep(0.68, 1.0, uv.y);
	sky_col += vec3(0.98, 0.45, 0.12) * horizon_bloom * 0.22;
	
	COLOR = vec4(sky_col, 1.0);
}
