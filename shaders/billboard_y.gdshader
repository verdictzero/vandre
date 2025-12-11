shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.5;

global uniform vec4 ambient_tint : source_color;
global uniform vec4 fog_color : source_color;

const float FOG_START = 60.0;
const float FOG_END = 96.0;

void vertex() {
	// Y-axis billboard: rotate to face camera while keeping upright
	vec3 cam_pos = (inverse(VIEW_MATRIX) * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 to_cam = cam_pos - MODEL_MATRIX[3].xyz;
	to_cam.y = 0.0; // Project onto XZ plane
	to_cam = normalize(to_cam);

	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 right = cross(up, to_cam);

	// Reconstruct vertex position with billboard rotation
	VERTEX = right * VERTEX.x + up * VERTEX.y + to_cam * VERTEX.z;
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
	ALPHA = 1.0;  // Alpha clip - no variable transparency
}
