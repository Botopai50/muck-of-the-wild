shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back;

// ====================================================================
// BOTW WATER SHADER (BREATH OF THE WILD AESTHETICS - ULTRA)
// ====================================================================
// - Gradiente de profundidade cristalina (turquesa da costa -> safira do oceano)
// - Linha de quebra de espuma ondulante e dinamica nas margens e rochas
// - Causticas solares animadas projetadas no fundo do mar/areia
// - Glint solar estilizado (anime sun sparkles)

group_uniforms Water_Colors;
uniform vec4 shallow_color : source_color = vec4(0.18, 0.86, 0.80, 0.72); // Turquesa cristalino da praia
uniform vec4 mid_color : source_color = vec4(0.08, 0.52, 0.74, 0.88);     // Azul celeste intermediario
uniform vec4 deep_color : source_color = vec4(0.02, 0.16, 0.46, 0.96);     // Azul safira do mar aberto
uniform float depth_distance : hint_range(0.5, 30.0, 0.5) = 4.5;
uniform float depth_curve : hint_range(0.2, 4.0, 0.1) = 1.25;

group_uniforms Foam_Settings;
// Espuma ondulante dinamica que quebra na praia e rochas
uniform vec4 foam_color : source_color = vec4(0.97, 1.0, 1.0, 1.0);
uniform float foam_width : hint_range(0.01, 3.0, 0.02) = 0.55;
uniform float foam_surge_intensity : hint_range(0.0, 1.0, 0.05) = 0.45; // Avanco e recuo das ondas
uniform float foam_smoothness : hint_range(0.001, 0.3, 0.005) = 0.04;
uniform float foam_speed : hint_range(0.0, 5.0, 0.1) = 1.4;
uniform float foam_noise_scale : hint_range(1.0, 50.0, 1.0) = 16.0;

group_uniforms Surface_Waves;
uniform float wave_speed : hint_range(0.0, 5.0, 0.1) = 1.3;
uniform float wave_amplitude : hint_range(0.0, 1.0, 0.01) = 0.09;
uniform float wave_frequency : hint_range(0.1, 5.0, 0.1) = 1.35;

group_uniforms Caustics_Refraction;
// Causticas projetadas no leito marinho com atenuacao por profundidade
uniform vec4 caustics_color : source_color = vec4(0.75, 0.98, 1.0, 0.65);
uniform float caustics_scale : hint_range(0.1, 10.0, 0.1) = 2.2;
uniform float caustics_speed : hint_range(0.0, 5.0, 0.1) = 0.85;
uniform float caustics_strength : hint_range(0.0, 2.0, 0.05) = 0.55;
uniform float caustics_fade_depth : hint_range(0.5, 15.0, 0.5) = 5.0;

group_uniforms Surface_Shading;
uniform float roughness : hint_range(0.0, 1.0, 0.01) = 0.06;
uniform float specular_strength : hint_range(0.0, 3.0, 0.1) = 1.4;
uniform vec4 sun_specular_color : source_color = vec4(1.0, 0.98, 0.88, 1.0);
uniform float fresnel_power : hint_range(1.0, 8.0, 0.2) = 4.0;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

varying vec3 v_world_pos;
varying float v_wave_height;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Ondulacao suave de superficie bidirecional
	float w1 = sin(v_world_pos.x * wave_frequency + TIME * wave_speed);
	float w2 = cos(v_world_pos.z * wave_frequency * 1.15 + TIME * wave_speed * 0.92);
	float wave = (w1 + w2) * 0.5 * wave_amplitude;
	v_wave_height = wave;

	VERTEX.y += wave;

	// Recalculo analitico suave da normal da onda
	float d_dx = cos(v_world_pos.x * wave_frequency + TIME * wave_speed) * wave_frequency * wave_amplitude * 0.5;
	float d_dz = -sin(v_world_pos.z * wave_frequency * 1.15 + TIME * wave_speed * 0.92) * (wave_frequency * 1.15) * wave_amplitude * 0.5;
	NORMAL = normalize(vec3(-d_dx, 1.0, -d_dz));
}

void fragment() {
	// 1. Reconstrucao de profundidade linear do cenario
	float depth_raw = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec4 upos = INV_PROJECTION_MATRIX * vec4(vec3(SCREEN_UV, depth_raw) * 2.0 - 1.0, 1.0);
	upos.xyz /= upos.w;
	float scene_depth = -upos.z;
	float surface_depth = -VERTEX.z;
	float depth_diff = max(scene_depth - surface_depth, 0.0);
	if (depth_raw < 0.0001 || depth_raw >= 0.9999) {
		depth_diff = 999.0;
	}

	// Posicao mundial do leito marinho para projecao de causticas
	vec4 seafloor_world = INV_VIEW_MATRIX * vec4(upos.xyz, 1.0);

	// 2. Gradiente de profundidade cristalina em 3 fases:
	float norm_depth = clamp(depth_diff / max(depth_distance, 0.01), 0.0, 1.0);
	norm_depth = pow(norm_depth, depth_curve);
	vec4 water_col = mix(shallow_color, mid_color, smoothstep(0.0, 0.45, norm_depth));
	water_col = mix(water_col, deep_color, smoothstep(0.40, 1.0, norm_depth));

	// 3. Causticas solares animadas no leito marinho
	vec2 c_pos = seafloor_world.xz * caustics_scale * 0.35;
	vec2 c_mov1 = c_pos + vec2(TIME * 0.05 * caustics_speed, TIME * 0.035 * caustics_speed);
	vec2 c_mov2 = c_pos - vec2(TIME * 0.04 * caustics_speed, -TIME * 0.055 * caustics_speed);
	float c1 = abs(sin(c_mov1.x * 3.1415 + sin(c_mov1.y * 3.1415)));
	float c2 = abs(cos(c_mov2.x * 3.1415 + cos(c_mov2.y * 3.1415)));
	float caustics_web = pow(1.0 - sqrt(c1 * c2), 2.2);
	// Fade de causticas com a profundidade da agua
	float caustics_fade = 1.0 - smoothstep(0.0, caustics_fade_depth, depth_diff);
	float caustics_final = caustics_web * caustics_fade * caustics_strength;

	// 4. Linha de quebra de espuma ondulante e dinamica
	float surge = sin(TIME * foam_speed * 1.3 + v_world_pos.x * 0.45 + v_world_pos.z * 0.35) * 0.5 + 0.5;
	float dynamic_width = foam_width * (1.0 + surge * foam_surge_intensity);
	
	// Perturbacao celular para contorno organico e estilizado da espuma
	float foam_noise = sin(v_world_pos.x * foam_noise_scale + TIME * foam_speed) *
	                   cos(v_world_pos.z * foam_noise_scale * 0.85 - TIME * foam_speed * 0.75);
	float shore_threshold = dynamic_width * (1.0 + foam_noise * 0.3);
	float shore_factor = 1.0 - smoothstep(0.0, shore_threshold, depth_diff);
	float foam_factor = smoothstep(0.5 - foam_smoothness, 0.5 + foam_smoothness, shore_factor);

	// Espuma de crista nas pontas de ondas mais altas
	float crest_foam = smoothstep(wave_amplitude * 0.65, wave_amplitude * 0.95, v_wave_height);
	foam_factor = max(foam_factor, crest_foam * 0.75);

	// 5. Composicao de albedo, causticas e reflexo Fresnel
	vec3 base_rgb = mix(water_col.rgb, foam_color.rgb, foam_factor);
	base_rgb += caustics_color.rgb * caustics_final * (1.0 - foam_factor);

	// Efeito Fresnel de borda de agua
	float n_dot_v = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - n_dot_v, fresnel_power);
	base_rgb = mix(base_rgb, mid_color.rgb * 1.3, fresnel * 0.35);

	ALBEDO = base_rgb;
	ROUGHNESS = roughness;
	METALLIC = 0.04;
	ALPHA = mix(water_col.a, 1.0, foam_factor);
}

void light() {
	// Iluminacao cel para a massa de agua
	float n_dot_l = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * (n_dot_l * 0.65 + 0.35) * ATTENUATION;

	// Specular Glint estilizado do sol (glint cel afiado com cintilacao)
	vec3 half_vec = normalize(VIEW + LIGHT);
	float n_dot_h = clamp(dot(NORMAL, half_vec), 0.0, 1.0);
	float spec_val = pow(n_dot_h, 160.0);
	float anime_glint = smoothstep(0.28, 0.36, spec_val) * specular_strength;

	SPECULAR_LIGHT += sun_specular_color.rgb * anime_glint * LIGHT_COLOR * ATTENUATION;
}
