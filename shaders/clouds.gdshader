shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable;
uniform float scroll_speed : hint_range(0.0, 0.1) = 0.01;
uniform float opacity : hint_range(0.0, 1.0) = 0.5;

global uniform vec4 sky_color_horizon : source_color;

void fragment() {
	// UV scrolling for cloud movement
	vec2 uv = UV;
	uv.x += TIME * scroll_speed;

	vec4 tex_color = texture(albedo_texture, uv);

	// Alpha cutoff
	if (tex_color.a < 0.5) {
		discard;
	}

	// Tint clouds with horizon color for atmospheric consistency
	vec3 color = tex_color.rgb * sky_color_horizon.rgb * opacity;

	ALBEDO = color;
}
