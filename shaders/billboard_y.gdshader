shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.5;

global uniform vec4 ambient_tint : source_color;
global uniform vec4 fog_color : source_color;

const float FOG_START = 40.0;
const float FOG_END = 128.0;

void vertex() {
	// Y-axis billboard: align to camera plane (not camera position)
	// Get camera's forward direction (view direction) projected onto XZ plane
	vec3 cam_forward = -vec3(VIEW_MATRIX[0][2], VIEW_MATRIX[1][2], VIEW_MATRIX[2][2]);
	cam_forward.y = 0.0; // Project onto XZ plane
	cam_forward = normalize(cam_forward);

	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 right = cross(up, cam_forward);

	// Reconstruct vertex position with billboard rotation
	VERTEX = right * VERTEX.x + up * VERTEX.y + cam_forward * VERTEX.z;
}

void fragment() {
	vec4 tex_color = texture(albedo_texture, UV);

	// Alpha cutoff for transparency
	if (tex_color.a < alpha_cutoff) {
		discard;
	}

	// Apply ambient tint
	vec3 color = tex_color.rgb * ambient_tint.rgb;

	// Calculate distance fog
	float depth = length(VERTEX);
	float fog_factor = smoothstep(FOG_START, FOG_END, depth);

	// Blend with fog
	ALBEDO = mix(color, fog_color.rgb, fog_factor);
	ALPHA = 1.0;
}
