shader_type spatial;
render_mode unshaded, cull_front, blend_mix, depth_draw_opaque;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float scroll_speed : hint_range(0.0, 0.1) = 0.01;
uniform float opacity : hint_range(0.0, 1.0) = 0.5;
uniform float uv_scale_x : hint_range(0.1, 10.0) = 1.0;
uniform float uv_scale_y : hint_range(0.1, 10.0) = 1.0;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.1;

global uniform vec4 sky_color_horizon : source_color;

void fragment() {
	// UV scaling and scrolling for cloud movement
	vec2 uv = UV * vec2(uv_scale_x, uv_scale_y);
	uv.x += TIME * scroll_speed;

	vec4 tex_color = texture(albedo_texture, uv);

	// Alpha cutoff for sparse areas
	if (tex_color.a < alpha_cutoff) {
		discard;
	}

	// Tint clouds with horizon color for atmospheric consistency
	vec3 color = tex_color.rgb * sky_color_horizon.rgb;

	ALBEDO = color;
	ALPHA = tex_color.a * opacity;
}
