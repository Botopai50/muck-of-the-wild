shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

// ====================================================================
// BOTW GRASS SHADER (BREATH OF THE WILD STYLIZED MEADOWS)
// ====================================================================
// Ondulacoes de vento via ondas mundiais, gradiente vertical de cor
// (raiz densa -> ponta dourada), deformacao fisica e translucidez.

group_uniforms Color_Gradient;
uniform vec4 color_root : source_color = vec4(0.12, 0.32, 0.10, 1.0);
uniform vec4 color_tip : source_color = vec4(0.56, 0.86, 0.22, 1.0);
uniform float gradient_power : hint_range(0.2, 4.0, 0.1) = 1.1;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0, 0.01) = 0.5;

group_uniforms Height_Settings;
uniform bool invert_uv_height = false;
uniform bool use_vertex_y_for_height = false;
uniform float grass_mesh_height = 1.0;
uniform float height_curve : hint_range(0.5, 3.0, 0.1) = 1.5;

group_uniforms Wind_Simulation;
uniform vec2 wind_direction = vec2(1.0, 0.3);
uniform float wind_speed : hint_range(0.0, 10.0, 0.1) = 2.2;
uniform float wind_strength : hint_range(0.0, 2.0, 0.02) = 0.28;
uniform float wind_scale : hint_range(0.01, 1.0, 0.01) = 0.12;
uniform float wind_gust_strength : hint_range(0.0, 1.0, 0.02) = 0.15;
uniform float wind_gust_speed : hint_range(0.0, 5.0, 0.1) = 1.2;
uniform float wind_vertical_depression : hint_range(0.0, 1.0, 0.05) = 0.35;

group_uniforms Interactive_Bend;
uniform vec3 player_position = vec3(0.0);
uniform float player_bend_radius : hint_range(0.0, 5.0, 0.1) = 1.5;
uniform float player_bend_strength : hint_range(0.0, 2.0, 0.05) = 0.6;

group_uniforms Lighting_Styling;
uniform vec4 shadow_tint : source_color = vec4(0.16, 0.30, 0.38, 1.0);
uniform vec4 midtone_tint : source_color = vec4(0.72, 0.85, 0.60, 1.0);
uniform float shadow_cut_mid : hint_range(0.0, 1.0, 0.01) = 0.30;
uniform float shadow_cut_bright : hint_range(0.0, 1.0, 0.01) = 0.65;
uniform float shadow_smoothness : hint_range(0.001, 0.5, 0.001) = 0.05;

group_uniforms Translucency;
uniform vec4 transmission_color : source_color = vec4(0.45, 0.80, 0.20, 1.0);
uniform float transmission_strength : hint_range(0.0, 3.0, 0.05) = 0.8;

varying float v_height;

void vertex() {
	// Determina a altura relativa do vertice (0.0 na raiz, 1.0 na ponta)
	float raw_h = invert_uv_height ? UV.y : (1.0 - UV.y);
	if (use_vertex_y_for_height) {
		raw_h = clamp(VERTEX.y / max(grass_mesh_height, 0.001), 0.0, 1.0);
	}
	float h_factor = clamp(raw_h, 0.0, 1.0);
	v_height = h_factor;

	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 norm_wind = normalize(wind_direction);

	// Simulacao de rajadas de vento passando pelas campinas
	vec2 uv_wind = world_pos.xz * wind_scale - norm_wind * (TIME * wind_speed);
	float wave1 = sin(uv_wind.x * 2.0 + uv_wind.y * 1.5);
	float wave2 = cos(uv_wind.x * 3.5 - uv_wind.y * 2.0 + TIME * 0.8);
	float main_wave = (wave1 + wave2 * 0.5) * 0.66;

	float gust = sin(world_pos.x * 0.15 + world_pos.z * 0.12 - TIME * wind_gust_speed) * wind_gust_strength;
	float sway = (main_wave * wind_strength + gust) * pow(h_factor, height_curve);

	VERTEX.x += norm_wind.x * sway;
	VERTEX.z += norm_wind.y * sway;
	VERTEX.y -= abs(sway) * wind_vertical_depression;

	// Interacao / amassamento da grama sob os pes do jogador
	if (player_bend_radius > 0.001) {
		vec3 to_player = world_pos - player_position;
		float dist = length(to_player.xz);
		if (dist < player_bend_radius && dist > 0.001) {
			float push = (1.0 - dist / player_bend_radius) * player_bend_strength * pow(h_factor, height_curve);
			vec2 push_dir = normalize(to_player.xz);
			VERTEX.x += push_dir.x * push;
			VERTEX.z += push_dir.y * push;
			VERTEX.y -= push * 0.4;
		}
	}

	// Normal voltada levemente para cima para suavizar a iluminacao nas campinas
	NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), 0.6));
}

void fragment() {
	vec4 albedo_tex = texture(albedo_texture, UV);

	// Gradiente vertical de cor: raiz escura e densa -> ponta sunlit
	vec3 grad_col = mix(color_root.rgb, color_tip.rgb, pow(v_height, gradient_power));
	ALBEDO = grad_col * albedo_tex.rgb;
	ROUGHNESS = 0.85;
	METALLIC = 0.0;

	// Subsurface scattering nativo para folhas finas de grama
	BACKLIGHT = transmission_color.rgb * transmission_strength;

	// Alpha scissor para laminas texturizadas
	ALPHA = albedo_tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
}

void light() {
	float n_dot_l = dot(NORMAL, LIGHT);
	float light_intensity = clamp((n_dot_l * 0.5 + 0.5) * ATTENUATION, 0.0, 1.0);

	// 3 Bandas Cel Shading
	float s_mid = smoothstep(shadow_cut_mid - shadow_smoothness, shadow_cut_mid + shadow_smoothness, light_intensity);
	float s_bright = smoothstep(shadow_cut_bright - shadow_smoothness, shadow_cut_bright + shadow_smoothness, light_intensity);

	vec3 cel_band = mix(shadow_tint.rgb, midtone_tint.rgb, s_mid);
	cel_band = mix(cel_band, vec3(1.0), s_bright);

	// Contraluz vibrante nas pontas
	float back_dot = clamp(dot(-VIEW, LIGHT), 0.0, 1.0);
	vec3 back_trans = transmission_color.rgb * pow(back_dot, 2.0) * transmission_strength * v_height * ATTENUATION;

	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * (cel_band + back_trans);
}
