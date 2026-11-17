shader_type canvas_item;

// Pixel-aligned sky shader for CUBE: LAST RUN.
// Driven by TimeOfDay controller across Daylight -> Late Afternoon -> Dusk -> Night.
// Preserves the multi-stop dusk transition look, moves the sun along a setting arc,
// and reveals sparse static stars and a crisp thin crescent moon at night.

uniform vec4 zenith_color : source_color = vec4(0.059, 0.063, 0.129, 1.0);
uniform vec4 upper_mid_color : source_color = vec4(0.169, 0.098, 0.239, 1.0);
uniform vec4 lower_mid_color : source_color = vec4(0.478, 0.157, 0.196, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.949, 0.549, 0.220, 1.0);

uniform vec4 sun_core_color : source_color = vec4(1.0, 0.95, 0.78, 1.0);
uniform vec4 sun_halo_color : source_color = vec4(1.0, 0.52, 0.20, 0.45);
uniform vec2 sun_uv_pos = vec2(0.63, 0.23);
uniform float sun_radius : hint_range(0.02, 0.25) = 0.072;
uniform float sun_alpha : hint_range(0.0, 1.0) = 1.0;

uniform vec4 moon_color : source_color = vec4(0.965, 0.941, 0.784, 1.0);
uniform vec2 moon_uv_pos = vec2(0.63, 0.17);
uniform float moon_radius : hint_range(0.02, 0.15) = 0.046;
uniform float moon_alpha : hint_range(0.0, 1.0) = 0.0;
uniform float star_alpha : hint_range(0.0, 1.0) = 0.0;
uniform float cloud_opacity : hint_range(0.0, 1.0) = 0.35;

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

void fragment() {
	// Snap UV to the 480x270 pixel grid for consistent pixel-art density
	vec2 grid_res = vec2(480.0, 270.0);
	vec2 uv = (floor(UV * grid_res) + 0.5) / grid_res;
	float aspect = 480.0 / 270.0;

	// 4-stop vertical atmospheric sky gradient
	vec3 sky_col;
	if (uv.y < 0.30) {
		sky_col = mix(zenith_color.rgb, upper_mid_color.rgb, uv.y / 0.30);
	} else if (uv.y < 0.62) {
		sky_col = mix(upper_mid_color.rgb, lower_mid_color.rgb, (uv.y - 0.30) / 0.32);
	} else {
		sky_col = mix(lower_mid_color.rgb, horizon_color.rgb, (uv.y - 0.62) / 0.38);
	}

	// Sparse static stars in upper sky only (no twinkling or per-frame blinking)
	if (star_alpha > 0.01 && uv.y > 0.07 && uv.y < 0.33) {
		vec2 px_coord = floor(UV * grid_res);
		float star_seed = hash21(px_coord);
		if (star_seed > 0.9955) {
			float height_mask = 1.0 - smoothstep(0.18, 0.33, uv.y);
			vec3 star_tint = (star_seed > 0.998) ? vec3(0.96, 0.94, 0.82) : vec3(0.82, 0.86, 0.98);
			sky_col = mix(sky_col, star_tint, star_alpha * height_mask * 0.85);
		}
	}

	// Sun with restrained halo and dusk horizon scanline banding
	if (sun_alpha > 0.01) {
		vec2 sun_delta = (uv - sun_uv_pos) * vec2(aspect, 1.0);
		float dist_to_sun = length(sun_delta);

		float sun_halo = exp(-dist_to_sun * 7.5) * 0.38 * sun_halo_color.a * sun_alpha;
		sky_col += sun_halo_color.rgb * sun_halo;

		if (dist_to_sun <= sun_radius) {
			float band_mask = 1.0;
			// Apply dusk horizon banding only when the sun is low in the sky
			if (sun_uv_pos.y > 0.32 && uv.y > sun_uv_pos.y + 0.01) {
				int row_px = int(floor(UV.y * 270.0));
				if ((row_px % 3) == 0) {
					band_mask = 0.0;
				}
			}
			float v_grad = clamp((uv.y - (sun_uv_pos.y - sun_radius)) / (sun_radius * 2.0), 0.0, 1.0);
			vec3 disc_col = mix(sun_core_color.rgb, horizon_color.rgb, v_grad * 0.55);
			sky_col = mix(sky_col, disc_col, band_mask * sun_alpha);
		}
	}

	// Thin Crescent Moon in upper sky (two overlapping discs: outer moon minus offset shadow disc)
	if (moon_alpha > 0.01) {
		vec2 moon_delta = (uv - moon_uv_pos) * vec2(aspect, 1.0);
		float dist_outer = length(moon_delta);

		// Very soft, restrained lunar glow
		float moon_glow = exp(-dist_outer * 18.0) * 0.14 * moon_alpha;
		sky_col += moon_color.rgb * moon_glow;

		// Offset shadow cutout center toward upper-left so a crisp right/bottom crescent remains
		vec2 cut_offset = vec2(-moon_radius * 0.42, -moon_radius * 0.18);
		float dist_cut = length(moon_delta - cut_offset);
		float cut_radius = moon_radius * 0.88;

		if (dist_outer <= moon_radius && dist_cut > cut_radius) {
			sky_col = mix(sky_col, moon_color.rgb, moon_alpha);
		}
	}

	// Subtle high-altitude cloud bands
	if (cloud_opacity > 0.01 && uv.y > 0.22 && uv.y < 0.72) {
		vec2 cloud_uv = vec2(uv.x * 4.0, uv.y * 14.0);
		float n = value_noise(cloud_uv) * 0.65 + value_noise(cloud_uv * 2.1) * 0.35;
		float cloud_mask = smoothstep(0.62, 0.78, n) * sin(clamp((uv.y - 0.22) / 0.50, 0.0, 1.0) * 3.14159);
		vec3 cloud_col = mix(upper_mid_color.rgb, horizon_color.rgb, 0.55);
		sky_col = mix(sky_col, cloud_col, cloud_mask * cloud_opacity);
	}

	COLOR = vec4(sky_col, 1.0);
}
