shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable;
uniform float fog_amount : hint_range(0.0, 1.0) = 0.5;
uniform float scroll_speed : hint_range(0.0, 1.0) = 0.0;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.5;
uniform float uv_scale_x : hint_range(0.1, 10.0) = 1.0;
uniform float uv_scale_y : hint_range(0.1, 10.0) = 1.0;

global uniform vec4 ambient_tint : source_color;
global uniform vec4 fog_color : source_color;

void fragment() {
	// UV scaling and scrolling for animation
	vec2 uv = UV * vec2(uv_scale_x, uv_scale_y);
	uv.x += TIME * scroll_speed;

	vec4 tex_color = texture(albedo_texture, uv);

	// Alpha cutoff for transparency
	if (tex_color.a < alpha_cutoff) {
		discard;
	}

	// Apply ambient tint
	vec3 color = tex_color.rgb * ambient_tint.rgb;

	// Apply pre-baked fog amount
	ALBEDO = mix(color, fog_color.rgb, fog_amount);
}
