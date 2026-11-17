shader_type canvas_item;

// Pixel-art sky shader for CUBE: LAST RUN.
// Driven by TimeOfDay across Day -> Mid-Afternoon -> Sun Touching Skyline -> Dusk -> Moon Rise -> Night.
// Maps 6 flat horizontal pixel-art sky bands from zenith (uv.y = 0.0) to the skyline horizon (uv.y = 0.58),
// renders a clean pixel-art circle sun (no blurry halo), static non-twinkling upper stars,
// and a thin pixel-art crescent moon with a faint static pixel rim glow.

uniform vec4 zenith_color : source_color = vec4(0.059, 0.063, 0.129, 1.0);
uniform vec4 upper_mid_color : source_color = vec4(0.169, 0.098, 0.239, 1.0);
uniform vec4 lower_mid_color : source_color = vec4(0.478, 0.157, 0.196, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.949, 0.549, 0.220, 1.0);

uniform vec4 sun_core_color : source_color = vec4(1.0, 0.953, 0.690, 1.0);  // #fff3b0 pale warm yellow
uniform vec4 sun_lower_color : source_color = vec4(0.949, 0.549, 0.220, 1.0); // #f28c38 amber
uniform vec2 sun_uv_pos = vec2(0.65, 0.20);
uniform float sun_radius : hint_range(0.02, 0.20) = 0.066;
uniform float sun_alpha : hint_range(0.0, 1.0) = 1.0;

uniform vec4 moon_color : source_color = vec4(0.965, 0.941, 0.784, 1.0); // #f6f0c8 pale cream
uniform vec2 moon_uv_pos = vec2(0.66, 0.18);
uniform float moon_radius : hint_range(0.02, 0.15) = 0.048;
uniform float moon_alpha : hint_range(0.0, 1.0) = 0.0;
uniform float star_alpha : hint_range(0.0, 1.0) = 0.0;

float star_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec3 sample_sky_gradient(float y_quant) {
	if (y_quant < 0.34) {
		return mix(zenith_color.rgb, upper_mid_color.rgb, y_quant / 0.34);
	} else if (y_quant < 0.70) {
		return mix(upper_mid_color.rgb, lower_mid_color.rgb, (y_quant - 0.34) / 0.36);
	} else {
		return mix(lower_mid_color.rgb, horizon_color.rgb, (y_quant - 0.70) / 0.30);
	}
}

void fragment() {
	// Snap UV to the 480x270 pixel grid for strict pixel-art consistency
	vec2 grid_res = vec2(480.0, 270.0);
	vec2 px_coord = floor(UV * grid_res);
	vec2 uv = (px_coord + vec2(0.5)) / grid_res;
	float aspect = 480.0 / 270.0;

	// Map visible sky height (uv.y 0.0 -> 0.58) into 6 flat horizontal pixel-art bands
	// so the horizon colors glow behind the skyline rooftops rather than underground.
	float sky_t = clamp(uv.y / 0.58, 0.0, 1.0);
	float band_count = 6.0;
	float raw_band = sky_t * band_count;
	float band_frac = fract(raw_band);
	float checker = mod(px_coord.x + px_coord.y, 2.0);
	float dither_step = (band_frac > 0.88 && checker > 0.5) ? 1.0 : 0.0;
	float band_y = clamp((floor(raw_band) + dither_step) / band_count, 0.0, 1.0);
	vec3 sky_col = sample_sky_gradient(band_y);

	// Sparse static stars in upper sky only (no twinkling, no diagonal banding)
	if (star_alpha > 0.01 && uv.y > 0.08 && uv.y < 0.30) {
		float star_seed = star_hash(px_coord);
		if (star_seed > 0.9968) {
			vec3 star_tint = (star_seed > 0.9985) ? vec3(0.96, 0.94, 0.80) : vec3(0.80, 0.85, 0.96);
			sky_col = mix(sky_col, star_tint, star_alpha * 0.85);
		}
	}

	// Clean pixel-art circle Sun (pale warm yellow to amber, no blurry halo or bloom)
	if (sun_alpha > 0.01) {
		vec2 sun_delta = (uv - sun_uv_pos) * vec2(aspect, 1.0);
		float dist_to_sun = length(sun_delta);
		if (dist_to_sun <= sun_radius) {
			float v_ratio = clamp((uv.y - (sun_uv_pos.y - sun_radius)) / (sun_radius * 2.0), 0.0, 1.0);
			float sun_band = floor(v_ratio * 3.0) / 2.0;
			vec3 disc_col = mix(sun_core_color.rgb, sun_lower_color.rgb, sun_band * clamp(sun_uv_pos.y * 1.5, 0.20, 1.0));
			sky_col = mix(sky_col, disc_col, sun_alpha);
		}
	}

	// Thin pixel-art Crescent Moon (two overlapping circles + faint static 2px pixel rim glow)
	if (moon_alpha > 0.01) {
		vec2 moon_delta = (uv - moon_uv_pos) * vec2(aspect, 1.0);
		float dist_outer = length(moon_delta);

		vec2 cut_offset = vec2(-moon_radius * 0.44, -moon_radius * 0.18);
		float dist_cut = length(moon_delta - cut_offset);
		float cut_radius = moon_radius * 0.88;

		if (dist_outer <= moon_radius + 0.008 && dist_outer > moon_radius && dist_cut > cut_radius) {
			sky_col = mix(sky_col, moon_color.rgb, 0.14 * moon_alpha);
		}
		if (dist_outer <= moon_radius && dist_cut > cut_radius) {
			sky_col = mix(sky_col, moon_color.rgb, moon_alpha);
		}
	}

	COLOR = vec4(sky_col, 1.0);
}
