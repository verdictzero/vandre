shader_type spatial;
render_mode unshaded, cull_front, blend_mix, depth_draw_never;

uniform float gradient_power : hint_range(0.5, 4.0) = 1.5;
uniform float opacity : hint_range(0.0, 1.0) = 0.4;

global uniform vec4 fog_color : source_color;

void fragment() {
	// Vertical gradient - thick at bottom, transparent at top
	float gradient = 1.0 - UV.y;
	gradient = pow(gradient, gradient_power);

	ALBEDO = fog_color.rgb;
	ALPHA = gradient * opacity;
}
