shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.5;

global uniform vec4 ambient_tint : source_color;
global uniform vec4 fog_color : source_color;

const float FOG_START = 60.0;
const float FOG_END = 96.0;

void vertex() {
	// For MultiMesh instances, we need to extract world position differently
	// MODEL_MATRIX already contains the instance transform
	vec3 world_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

	// Get camera position in world space
	vec3 cam_pos = (inverse(VIEW_MATRIX) * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

	// Direction to camera (Y-axis billboard)
	vec3 to_cam = cam_pos - world_pos;
	to_cam.y = 0.0;
	to_cam = normalize(to_cam);

	vec3 up = vec3(0.0, 1.0, 0.0);
	vec3 right = cross(up, to_cam);

	// Get the instance scale from MODEL_MATRIX
	float scale_x = length(MODEL_MATRIX[0].xyz);
	float scale_y = length(MODEL_MATRIX[1].xyz);

	// Reconstruct vertex position with billboard rotation
	vec3 billboard_pos = right * VERTEX.x * scale_x + up * VERTEX.y * scale_y;

	// Apply world position offset
	VERTEX = billboard_pos;
	// Offset to instance position
	VERTEX += (inverse(VIEW_MATRIX * MODEL_MATRIX) * vec4(world_pos, 1.0)).xyz;
}

void fragment() {
	vec4 tex_color = texture(albedo_texture, UV);

	if (tex_color.a < alpha_cutoff) {
		discard;
	}

	vec3 color = tex_color.rgb * ambient_tint.rgb;

	float depth = length(VERTEX);
	float fog_factor = smoothstep(FOG_START, FOG_END, depth);

	ALBEDO = mix(color, fog_color.rgb, fog_factor);
	ALPHA = tex_color.a;
}
