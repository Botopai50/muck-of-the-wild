shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

// ====================================================================
// BOTW FOLIAGE SHADER (BREATH OF THE WILD AESTHETICS - ULTRA)
// ====================================================================
// - Normais esfericas perfeitas para copas de arvore fofas e estilizadas (anime)
// - Vento procedural com rajadas periodicas por ruido simplex, inclinacao e vibracao
// - Translucidez aprimorada (subsurface scattering backlight) contra o sol e a lua
// - Cel-shading de 3 bandas e rim light foliar

group_uniforms Foliage_Color;
uniform vec4 albedo_color : source_color = vec4(0.42, 0.72, 0.22, 1.0);
uniform vec4 top_tint : source_color = vec4(0.62, 0.88, 0.26, 1.0);
uniform vec4 bottom_tint : source_color = vec4(0.18, 0.42, 0.16, 1.0);
uniform float vertical_gradient_power : hint_range(0.1, 4.0, 0.1) = 1.2;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0, 0.01) = 0.5;

group_uniforms Spherical_Normals;
// Normais esfericas: calcula vetor a partir do centro da copa para volume pictorico sem ruidos
uniform vec3 cluster_center_offset = vec3(0.0, 3.8, 0.0);
uniform float spherical_normal_strength : hint_range(0.0, 1.0, 0.02) = 0.85;

group_uniforms Wind_Simulation;
uniform vec2 wind_direction = vec2(1.0, 0.5);
uniform float wind_speed : hint_range(0.0, 8.0, 0.1) = 1.8;
uniform float wind_strength : hint_range(0.0, 1.5, 0.02) = 0.22;
uniform float wind_frequency : hint_range(0.01, 2.0, 0.01) = 0.35;
uniform float wind_gust_strength : hint_range(0.0, 2.0, 0.05) = 0.35;
uniform float wind_gust_speed : hint_range(0.0, 5.0, 0.1) = 0.9;
uniform float flutter_speed : hint_range(0.0, 25.0, 0.5) = 8.0;
uniform float flutter_strength : hint_range(0.0, 0.3, 0.01) = 0.045;
uniform float sway_height_min = 0.3;

group_uniforms Translucency_Subsurface;
// Efeito de translucidez quando visto contra o sol ou a lua
uniform vec4 transmission_color : source_color = vec4(0.62, 0.92, 0.24, 1.0);
uniform float transmission_strength : hint_range(0.0, 4.0, 0.05) = 1.2;
uniform float transmission_power : hint_range(1.0, 12.0, 0.2) = 3.5;

group_uniforms Cel_Lighting;
uniform vec4 shadow_tint : source_color = vec4(0.14, 0.30, 0.38, 1.0); // Sombra azulada/petroleo BotW
uniform vec4 midtone_tint : source_color = vec4(0.68, 0.84, 0.62, 1.0);
uniform float shadow_cut_mid : hint_range(0.0, 1.0, 0.01) = 0.30;
uniform float shadow_cut_bright : hint_range(0.0, 1.0, 0.01) = 0.65;
uniform float shadow_smoothness : hint_range(0.001, 0.3, 0.001) = 0.04;

group_uniforms Rim_Lighting;
uniform vec4 rim_color : source_color = vec4(0.85, 0.96, 0.65, 1.0);
uniform float rim_power : hint_range(0.5, 16.0, 0.1) = 3.0;
uniform float rim_intensity : hint_range(0.0, 5.0, 0.05) = 0.65;
uniform float rim_ambient_silhouette : hint_range(0.0, 1.0, 0.05) = 0.25;

varying float v_height;

// Funcao Hash para o gerador de ruido simplex
vec2 hash_simplex(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// Ruido simplex 2D continuo para rajadas de vento realisticas
float simplex_noise2d(vec2 p) {
	const float K1 = 0.366025404; // (sqrt(3)-1)/2
	const float K2 = 0.211324865; // (3-sqrt(3))/6
	vec2 i = floor(p + (p.x + p.y) * K1);
	vec2 a = p - i + (i.x + i.y) * K2;
	vec2 o = (a.x > a.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec2 b = a - o + K2;
	vec2 c = a - 1.0 + 2.0 * K2;
	vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
	vec3 n = h * h * h * h * vec3(dot(a, hash_simplex(i)), dot(b, hash_simplex(i + o)), dot(c, hash_simplex(i + 1.0)));
	return dot(n, vec3(70.0));
}

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_height = VERTEX.y;

	// 1. Normais esfericas perfeitas estilo anime:
	vec3 to_vertex = VERTEX - cluster_center_offset;
	float dist_from_center = length(to_vertex);
	vec3 sphere_dir = (dist_from_center > 0.001) ? normalize(to_vertex) : vec3(0.0, 1.0, 0.0);
	NORMAL = normalize(mix(NORMAL, sphere_dir, spherical_normal_strength));

	// 2. Simulacao de Vento Procedural Aprimorada:
	vec2 norm_wind = normalize(wind_direction);
	float height_mask = clamp((VERTEX.y - sway_height_min) * 0.35, 0.0, 2.0);

	// Onda suave de base
	float base_sway = sin(TIME * wind_speed + dot(world_pos.xz, norm_wind) * wind_frequency);

	// Rajadas periodicas propagadas por ruido simplex
	vec2 gust_coord = world_pos.xz * 0.06 - norm_wind * (TIME * wind_gust_speed * 0.4);
	float gust = clamp(simplex_noise2d(gust_coord) * 0.5 + 0.5, 0.0, 1.0) * wind_gust_strength;

	// Deslocamento total com inclinacao da copa
	float total_sway = (base_sway * wind_strength + gust) * height_mask;
	VERTEX.x += norm_wind.x * total_sway;
	VERTEX.z += norm_wind.y * total_sway;
	
	// Inclinacao biomecanica (arco para baixo sob vento forte)
	VERTEX.y -= (total_sway * total_sway * 0.12);

	// Vibracao foliar de alta frequencia (fluttering de folhas)
	float flutter = sin(TIME * flutter_speed + dot(world_pos, vec3(4.2, 7.1, 3.8))) * flutter_strength * height_mask;
	VERTEX += NORMAL * flutter;
}

void fragment() {
	vec4 albedo_tex = texture(albedo_texture, UV);

	// Gradiente vertical artistico da copa das arvores
	float grad_factor = clamp(v_height * 0.25 + 0.5, 0.0, 1.0);
	grad_factor = pow(grad_factor, vertical_gradient_power);
	vec3 foliage_gradient = mix(bottom_tint.rgb, top_tint.rgb, grad_factor);

	ALBEDO = albedo_color.rgb * albedo_tex.rgb * foliage_gradient;
	ROUGHNESS = 0.85;
	METALLIC = 0.0;

	// Translucidez nativa do Godot para luzes pontuais
	BACKLIGHT = transmission_color.rgb * transmission_strength * 0.5;

	// Silhueta rim luminosa sutil (para visibilidade a noite)
	float n_dot_v = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float rim = pow(1.0 - n_dot_v, rim_power);
	vec3 ambient_rim = rim_color.rgb * rim * rim_intensity * rim_ambient_silhouette;
	EMISSION = ambient_rim;

	ALPHA = albedo_tex.a * albedo_color.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
}

void light() {
	// NdotL suavizado
	float n_dot_l = dot(NORMAL, LIGHT);
	float light_intensity = clamp((n_dot_l * 0.5 + 0.5) * ATTENUATION, 0.0, 1.0);

	// Cel-Shading em 3 bandas
	float s_mid = smoothstep(shadow_cut_mid - shadow_smoothness, shadow_cut_mid + shadow_smoothness, light_intensity);
	float s_bright = smoothstep(shadow_cut_bright - shadow_smoothness, shadow_cut_bright + shadow_smoothness, light_intensity);

	vec3 cel_band = mix(shadow_tint.rgb, midtone_tint.rgb, s_mid);
	cel_band = mix(cel_band, vec3(1.0), s_bright);

	// Translucidez Subsurface Scattering (Backlight solar ou lunar)
	float back_dot = clamp(dot(-VIEW, LIGHT), 0.0, 1.0);
	float wrap_sub = clamp((dot(-NORMAL, LIGHT) + 0.3) / 1.3, 0.0, 1.0);
	float sss_factor = pow(back_dot, transmission_power) * wrap_sub;
	vec3 sss_glow = transmission_color.rgb * sss_factor * transmission_strength * ATTENUATION * LIGHT_COLOR;

	// Rim Light foliar
	float n_dot_v = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - n_dot_v, rim_power) * rim_intensity * (1.0 - rim_ambient_silhouette);
	vec3 rim_term = rim_color.rgb * rim * clamp(n_dot_l * 0.6 + 0.4, 0.2, 1.0);

	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * cel_band + sss_glow + rim_term * LIGHT_COLOR;
}
