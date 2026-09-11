shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

// ====================================================================
// BOTW FOLIAGE SHADER (TREES & BUSHES - BREATH OF THE WILD)
// ====================================================================
// Normais esfericas para silhuetas fofas, vento senoidal com flutter,
// translucidez a contraluz (subsurface) e cel-shading em 3 bandas.

group_uniforms Foliage_Color;
uniform vec4 albedo_color : source_color = vec4(0.40, 0.70, 0.20, 1.0);
uniform vec4 top_tint : source_color = vec4(0.60, 0.85, 0.25, 1.0);
uniform vec4 bottom_tint : source_color = vec4(0.20, 0.45, 0.15, 1.0);
uniform float vertical_gradient_power : hint_range(0.1, 4.0, 0.1) = 1.2;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0, 0.01) = 0.5;

group_uniforms Spherical_Normals;
// Normais esfericas/cluster: direciona as normais para fora do centro,
// criando volumes fofos, pictoricos e sem ruído de triangulos individuais.
uniform vec3 cluster_center_offset = vec3(0.0, 1.5, 0.0);
uniform float spherical_normal_strength : hint_range(0.0, 1.0, 0.02) = 0.85;

group_uniforms Wind_Animation;
uniform vec2 wind_direction = vec2(1.0, 0.5);
uniform float wind_speed : hint_range(0.0, 10.0, 0.1) = 1.8;
uniform float wind_strength : hint_range(0.0, 2.0, 0.02) = 0.18;
uniform float wind_frequency : hint_range(0.01, 2.0, 0.01) = 0.4;
uniform float flutter_speed : hint_range(0.0, 20.0, 0.5) = 6.0;
uniform float flutter_strength : hint_range(0.0, 0.5, 0.01) = 0.04;
uniform float sway_height_min = 0.2;

group_uniforms Cel_Lighting;
uniform vec4 shadow_tint : source_color = vec4(0.15, 0.32, 0.40, 1.0); // Sombra verde-azulada tipica de copas
uniform vec4 midtone_tint : source_color = vec4(0.70, 0.85, 0.65, 1.0);
uniform float shadow_cut_mid : hint_range(0.0, 1.0, 0.01) = 0.30;
uniform float shadow_cut_bright : hint_range(0.0, 1.0, 0.01) = 0.65;
uniform float shadow_smoothness : hint_range(0.001, 0.5, 0.001) = 0.06;

group_uniforms Translucency_Backlight;
// Translucidez de folhas quando a luz solar atravessa a copa
uniform vec4 transmission_color : source_color = vec4(0.55, 0.85, 0.25, 1.0);
uniform float transmission_strength : hint_range(0.0, 3.0, 0.05) = 0.75;

group_uniforms Rim_Lighting;
uniform vec4 rim_color : source_color = vec4(0.85, 0.95, 0.65, 1.0);
uniform float rim_power : hint_range(0.5, 16.0, 0.1) = 3.0;
uniform float rim_intensity : hint_range(0.0, 5.0, 0.05) = 0.5;

varying float v_height;

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_height = VERTEX.y;

	// Calculo de normais esfericas a partir do centro do cluster
	vec3 sphere_dir = normalize(VERTEX - cluster_center_offset);
	NORMAL = normalize(mix(NORMAL, sphere_dir, spherical_normal_strength));

	// Calculo de deslocamento de vento baseado em ondas mundiais
	vec2 norm_wind = normalize(wind_direction);
	float height_mask = clamp((VERTEX.y - sway_height_min) * 0.3, 0.0, 1.5);

	float broad_sway = sin(TIME * wind_speed + world_pos.x * wind_frequency + world_pos.z * wind_frequency * 0.8);
	float flutter = sin(TIME * flutter_speed + world_pos.y * 4.0 + world_pos.x * 2.0) * flutter_strength;

	float total_sway = (broad_sway * wind_strength + flutter) * height_mask;
	VERTEX.x += norm_wind.x * total_sway;
	VERTEX.z += norm_wind.y * total_sway;
	VERTEX.y -= abs(broad_sway) * wind_strength * 0.3 * height_mask;
}

void fragment() {
	vec4 albedo_tex = texture(albedo_texture, UV);
	
	// Gradiente vertical na copa (fundo mais sombrio, topo mais claro)
	float grad_factor = clamp(v_height * 0.25 + 0.5, 0.0, 1.0);
	grad_factor = pow(grad_factor, vertical_gradient_power);
	vec3 foliage_gradient = mix(bottom_tint.rgb, top_tint.rgb, grad_factor);

	ALBEDO = albedo_color.rgb * albedo_tex.rgb * foliage_gradient;
	ROUGHNESS = 0.9;
	METALLIC = 0.0;

	// Translucidez nativa do Godot para contraluz
	BACKLIGHT = transmission_color.rgb * transmission_strength;

	// Mascara de alfa para placas de folhagem (cards)
	ALPHA = albedo_tex.a * albedo_color.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
}

void light() {
	// NdotL suavizado
	float n_dot_l = dot(NORMAL, LIGHT);
	float light_intensity = clamp((n_dot_l * 0.5 + 0.5) * ATTENUATION, 0.0, 1.0);

	// Cel Shading em 3 bandas
	float s_mid = smoothstep(shadow_cut_mid - shadow_smoothness, shadow_cut_mid + shadow_smoothness, light_intensity);
	float s_bright = smoothstep(shadow_cut_bright - shadow_smoothness, shadow_cut_bright + shadow_smoothness, light_intensity);

	vec3 cel_band = mix(shadow_tint.rgb, midtone_tint.rgb, s_mid);
	cel_band = mix(cel_band, vec3(1.0), s_bright);

	// Efeito de contraluz (subsurface glow)
	float back_dot = clamp(dot(-VIEW, LIGHT), 0.0, 1.0);
	vec3 back_trans = transmission_color.rgb * pow(back_dot, 2.5) * transmission_strength * ATTENUATION;

	// Rim light de borda
	float n_dot_v = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - n_dot_v, rim_power) * rim_intensity;
	vec3 rim_term = rim_color.rgb * rim * clamp(n_dot_l * 0.5 + 0.5, 0.2, 1.0);

	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * (cel_band + back_trans) + rim_term * LIGHT_COLOR;
}
