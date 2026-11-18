shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform sampler2D meadow : source_color, filter_nearest, repeat_enable;
uniform sampler2D dirt : source_color, filter_nearest, repeat_enable;
uniform sampler2D stone : source_color, filter_nearest, repeat_enable;
uniform sampler2D paving : source_color, filter_nearest, repeat_enable;
uniform vec4 meadow_tint : source_color = vec4(1.0);
uniform int ground;
uniform int neighbor_ground[6];
uniform float visibility;
uniform float neighbor_visibility[6];

varying vec2 tile_point;
varying vec2 world_point;

void vertex() {
	tile_point = VERTEX.xz;
	world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

float terrain_random(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float terrain_noise(vec2 p) {
	vec2 base = floor(p);
	vec2 f = fract(p);
	vec2 blend = f * f * (3.0 - 2.0 * f);
	float a = mix(terrain_random(base), terrain_random(base + vec2(1.0, 0.0)), blend.x);
	float b = mix(terrain_random(base + vec2(0.0, 1.0)), terrain_random(base + vec2(1.0)), blend.x);
	return mix(a, b, blend.y);
}

float ground_weight(vec2 offset) {
	return 1.0 - smoothstep(0.60, 1.30, length(offset));
}

void fragment() {
	vec2 step_point = floor(world_point * 30.0 + 0.5) / 30.0;
	vec2 broad = vec2(terrain_noise(step_point * 2.9), terrain_noise(step_point * 2.9 + vec2(16.1, 31.3))) - 0.5;
	vec2 fine = vec2(terrain_noise(step_point * 15.0), terrain_noise(step_point * 15.0 + vec2(6.0, 12.1))) - 0.5;
	vec2 displacement = broad * 0.68 + fine * 0.13;
	vec2 shifted = tile_point + displacement * (0.27 / max(0.27, length(displacement)));
	vec4 weights = vec4(0.0);
	weights[ground] = ground_weight(shifted);
	float light_weight = ground_weight(tile_point);
	float lit = light_weight * visibility;
	// Adjacent meshes evaluate the same material and survey weights at their shared edge.
	for (int edge = 0; edge < 6; edge++) {
		int other = neighbor_ground[edge];
		if (other < 0) {
			continue;
		}
		float angle = PI / 6.0 + float(edge) * PI / 3.0;
		vec2 center = vec2(cos(angle), sin(angle)) * sqrt(3.0);
		weights[other] += ground_weight(shifted - center);
		float w = ground_weight(tile_point - center);
		lit += w * neighbor_visibility[edge];
		light_weight += w;
	}
	weights /= dot(weights, vec4(1.0));
	vec2 uv = world_point * 0.46 + vec2(0.5);
	vec3 grass = texture(meadow, uv).rgb * meadow_tint.rgb;
	vec3 earth = mix(grass, texture(dirt, uv).rgb * vec3(0.80, 0.98, 0.88), 0.62);
	vec3 scree = mix(grass, texture(stone, uv).rgb * vec3(0.81, 0.94, 0.88), 0.70);
	ALBEDO = (weights.x * grass + weights.y * earth + weights.z * scree
		+ weights.w * texture(paving, uv).rgb) * (lit / light_weight);
	vec3 up = (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	NORMAL = normalize(mix(NORMAL, up, 0.68));
	ROUGHNESS = 1.0;
}
