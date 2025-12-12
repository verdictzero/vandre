shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never;

global uniform vec4 sky_color_top : source_color;
global uniform vec4 sky_color_horizon : source_color;
global uniform float time_of_day;

// Sun/moon settings
const float SUN_SIZE = 0.04;
const float SUN_GLOW_SIZE = 0.12;
const float MOON_SIZE = 0.03;
const float MOON_GLOW_SIZE = 0.08;

// Calculate celestial body position based on time
// Returns vec2 in UV space (0-1)
vec2 get_sun_position(float time) {
	// Sun visible from 5:00 to 19:00 (rises east, sets west)
	// At 12:00, sun is at highest point
	// Map time to arc: 5:00 = right horizon, 12:00 = top, 19:00 = left horizon
	float sun_time = (time - 5.0) / 14.0; // 0 at 5:00, 1 at 19:00
	sun_time = clamp(sun_time, 0.0, 1.0);

	// X: right to left (0.85 to 0.15)
	float x = mix(0.85, 0.15, sun_time);

	// Y: arc using sine (0 at horizons, peaks at 0.85)
	float arc = sin(sun_time * 3.14159);
	float y = mix(0.15, 0.85, arc);

	return vec2(x, y);
}

vec2 get_moon_position(float time) {
	// Moon visible from 18:00 to 6:00 (next day)
	// Normalize to 0-1 range for the night period
	float moon_time;
	if (time >= 18.0) {
		moon_time = (time - 18.0) / 12.0; // 18:00 = 0, 6:00 = 1
	} else {
		moon_time = (time + 6.0) / 12.0; // Continue from midnight
	}
	moon_time = clamp(moon_time, 0.0, 1.0);

	// X: right to left
	float x = mix(0.85, 0.15, moon_time);

	// Y: arc using sine
	float arc = sin(moon_time * 3.14159);
	float y = mix(0.15, 0.85, arc);

	return vec2(x, y);
}

float get_sun_visibility(float time) {
	// Fade in from 5:00-6:00, fade out from 18:00-19:00
	if (time < 5.0) return 0.0;
	if (time < 6.0) return (time - 5.0); // Fade in
	if (time < 18.0) return 1.0;
	if (time < 19.0) return 1.0 - (time - 18.0); // Fade out
	return 0.0;
}

float get_moon_visibility(float time) {
	// Fade in from 18:00-19:00, fade out from 5:00-6:00
	if (time < 5.0) return 1.0;
	if (time < 6.0) return 1.0 - (time - 5.0); // Fade out
	if (time < 18.0) return 0.0;
	if (time < 19.0) return (time - 18.0); // Fade in
	return 1.0;
}

void fragment() {
	// Base sky gradient
	float gradient = UV.y;
	vec3 color = mix(sky_color_horizon.rgb, sky_color_top.rgb, gradient);

	// Sun
	float sun_vis = get_sun_visibility(time_of_day);
	if (sun_vis > 0.0) {
		vec2 sun_pos = get_sun_position(time_of_day);
		float sun_dist = distance(UV, sun_pos);

		// Sun core (bright white/yellow)
		float sun_core = 1.0 - smoothstep(0.0, SUN_SIZE, sun_dist);

		// Sun glow (soft orange/yellow gradient)
		float sun_glow = 1.0 - smoothstep(SUN_SIZE, SUN_GLOW_SIZE, sun_dist);
		sun_glow *= 0.5; // Softer glow

		vec3 sun_color = vec3(1.0, 0.95, 0.8); // Warm white
		vec3 glow_color = vec3(1.0, 0.8, 0.4); // Orange glow

		color = mix(color, glow_color, sun_glow * sun_vis);
		color = mix(color, sun_color, sun_core * sun_vis);
	}

	// Moon
	float moon_vis = get_moon_visibility(time_of_day);
	if (moon_vis > 0.0) {
		vec2 moon_pos = get_moon_position(time_of_day);
		float moon_dist = distance(UV, moon_pos);

		// Moon core (pale white)
		float moon_core = 1.0 - smoothstep(0.0, MOON_SIZE, moon_dist);

		// Moon glow (soft blue-white)
		float moon_glow = 1.0 - smoothstep(MOON_SIZE, MOON_GLOW_SIZE, moon_dist);
		moon_glow *= 0.3; // Subtle glow

		vec3 moon_color = vec3(0.9, 0.92, 0.95); // Cool white
		vec3 glow_color = vec3(0.6, 0.65, 0.8); // Blue-ish glow

		color = mix(color, glow_color, moon_glow * moon_vis);
		color = mix(color, moon_color, moon_core * moon_vis);
	}

	ALBEDO = color;
}
