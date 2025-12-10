shader_type spatial;
render_mode unshaded, cull_back;

uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable;
uniform float uv_scale : hint_range(0.1, 10.0) = 1.0;

global uniform vec4 ambient_tint : source_color;
global uniform vec4 fog_color : source_color;

const float FOG_START = 60.0;
const float FOG_END = 96.0;

void fragment() {
	vec2 uv = UV * uv_scale;
	vec4 tex_color = texture(albedo_texture, uv);

	// Apply ambient tint
	vec3 color = tex_color.rgb * ambient_tint.rgb;

	// Calculate distance fog
	float depth = length(VERTEX);
	float fog_factor = smoothstep(FOG_START, FOG_END, depth);

	// Blend with fog
	ALBEDO = mix(color, fog_color.rgb, fog_factor);
}
