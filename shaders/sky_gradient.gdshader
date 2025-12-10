shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never;

global uniform vec4 sky_color_top : source_color;
global uniform vec4 sky_color_horizon : source_color;

void fragment() {
	// Use UV.y for gradient (0 at bottom/horizon, 1 at top)
	// The sphere's UVs map Y position to V coordinate
	float gradient = UV.y;

	// Smooth gradient from horizon (bottom) to top
	vec3 color = mix(sky_color_horizon.rgb, sky_color_top.rgb, gradient);

	ALBEDO = color;
}
