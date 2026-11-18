shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, shadows_disabled;

void fragment() {
	float ribbon = sin(clamp(UV.x, 0.0, 1.0) * 3.141593);
	float breath = 0.56 + sin(TIME * 2.2) * 0.09;
	ALBEDO = vec3(0.31, 0.74, 1.0);
	ALPHA = pow(ribbon, 1.4) * breath;
}
