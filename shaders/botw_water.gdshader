shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back;

// ====================================================================
// BOTW WATER SHADER (BREATH OF THE WILD STYLIZED WATER)
// ====================================================================
// Linha de espuma nas margens e rochas via depth buffer, gradiente
// turquesa profundo, ondulacoes suaves e reflexos estilizados.

group_uniforms Water_Colors;
uniform vec4 shallow_color : source_color = vec4(0.18, 0.82, 0.78, 0.75); // Turquesa cristalino
uniform vec4 deep_color : source_color = vec4(0.04, 0.25, 0.52, 0.95);    // Azul safira profundo
uniform float depth_distance : hint_range(0.1, 20.0, 0.1) = 3.5;
uniform float depth_curve : hint_range(0.2, 4.0, 0.1) = 1.2;

group_uniforms Foam_Settings;
// Espuma nas margens e contornos de rochas/obstaculos
uniform vec4 foam_color : source_color = vec4(0.95, 1.0, 1.0, 1.0);
uniform float foam_width : hint_range(0.01, 2.0, 0.01) = 0.45;
uniform float foam_smoothness : hint_range(0.001, 0.5, 0.01) = 0.06;
uniform float foam_speed : hint_range(0.0, 5.0, 0.1) = 1.5;
uniform float foam_noise_scale : hint_range(1.0, 50.0, 1.0) = 18.0;

group_uniforms Surface_Waves;
uniform float wave_speed : hint_range(0.0, 5.0, 0.1) = 1.2;
uniform float wave_amplitude : hint_range(0.0, 1.0, 0.01) = 0.08;
uniform float wave_frequency : hint_range(0.1, 5.0, 0.1) = 1.4;

group_uniforms Caustics_Ripples;
uniform vec4 caustics_color : source_color = vec4(0.70, 0.95, 1.0, 0.5);
uniform float caustics_scale : hint_range(0.1, 10.0, 0.1) = 2.0;
uniform float caustics_speed : hint_range(0.0, 5.0, 0.1) = 0.8;
uniform float caustics_strength : hint_range(0.0, 1.0, 0.02) = 0.35;

group_uniforms Surface_Shading;
uniform float roughness : hint_range(0.0, 1.0, 0.01) = 0.08;
uniform float specular_strength : hint_range(0.0, 2.0, 0.05) = 1.0;
uniform vec4 sun_specular_color : source_color = vec4(1.0, 0.98, 0.85, 1.0);

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Ondulacao suave de superficie
	float w1 = sin(v_world_pos.x * wave_frequency + TIME * wave_speed);
	float w2 = cos(v_world_pos.z * wave_frequency * 1.2 + TIME * wave_speed * 0.9);
	float wave = (w1 + w2) * 0.5 * wave_amplitude;

	VERTEX.y += wave;

	// Recalculo suave da normal da superficie da onda
	float d_dx = cos(v_world_pos.x * wave_frequency + TIME * wave_speed) * wave_frequency * wave_amplitude * 0.5;
	float d_dz = -sin(v_world_pos.z * wave_frequency * 1.2 + TIME * wave_speed * 0.9) * wave_frequency * 1.2 * wave_amplitude * 0.5;
	NORMAL = normalize(vec3(-d_dx, 1.0, -d_dz));
}

void fragment() {
	// Reconstrucao de profundidade linear para linha de espuma e translucidez
	float depth_raw = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec4 upos = INV_PROJECTION_MATRIX * vec4(vec3(SCREEN_UV, depth_raw) * 2.0 - 1.0, 1.0);
	float scene_depth = -upos.z / upos.w;
	float surface_depth = -VERTEX.z;
	float depth_diff = max(scene_depth - surface_depth, 0.0);

	// Gradiente de cor de agua rasa -> agua profunda
	float depth_factor = clamp(depth_diff / max(depth_distance, 0.01), 0.0, 1.0);
	vec4 water_col = mix(shallow_color, deep_color, pow(depth_factor, depth_curve));

	// Padrao estilizado de causticas/celulas de superficie
	vec2 c_uv1 = (v_world_pos.xz * 0.3 * caustics_scale) + vec2(TIME * 0.05 * caustics_speed, TIME * 0.04 * caustics_speed);
	vec2 c_uv2 = (v_world_pos.xz * 0.45 * caustics_scale) - vec2(TIME * 0.04 * caustics_speed, -TIME * 0.06 * caustics_speed);
	float caustic_wave1 = sin(c_uv1.x * 6.0 + sin(c_uv1.y * 4.0));
	float caustic_wave2 = cos(c_uv2.x * 5.0 - cos(c_uv2.y * 6.0));
	float caustics_val = smoothstep(0.4, 0.8, (caustic_wave1 + caustic_wave2) * 0.5);

	// Linha de espuma nas margens com modulacao por ruido senoidal
	float foam_noise = sin(v_world_pos.x * foam_noise_scale + TIME * foam_speed) *
	                   cos(v_world_pos.z * foam_noise_scale + TIME * foam_speed * 1.2);
	float dynamic_foam_dist = foam_width * (1.0 + foam_noise * 0.25);
	float foam_factor = 1.0 - smoothstep(0.0, dynamic_foam_dist, depth_diff);
	foam_factor = smoothstep(0.5 - foam_smoothness, 0.5 + foam_smoothness, foam_factor);

	// Composicao final da cor
	vec3 base_rgb = mix(water_col.rgb, foam_color.rgb, foam_factor);
	base_rgb += caustics_color.rgb * caustics_val * caustics_strength * (1.0 - foam_factor);

	ALBEDO = base_rgb;
	ROUGHNESS = roughness;
	METALLIC = 0.05;
	ALPHA = mix(water_col.a, 1.0, foam_factor);
}

void light() {
	// Iluminacao cel-shading para a agua
	float n_dot_l = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * (n_dot_l * 0.7 + 0.3) * ATTENUATION;

	// Brilho especular estilizado do sol na agua (glint suave/nitido)
	vec3 half_vec = normalize(VIEW + LIGHT);
	float n_dot_h = clamp(dot(NORMAL, half_vec), 0.0, 1.0);
	float spec = pow(n_dot_h, 128.0);
	float toon_spec = smoothstep(0.3, 0.4, spec) * specular_strength;

	SPECULAR_LIGHT += sun_specular_color.rgb * toon_spec * LIGHT_COLOR * ATTENUATION;
}
