shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// ====================================================================
// BOTW UNIVERSAL CEL SHADER (BREATH OF THE WILD AESTHETICS - ULTRA)
// ====================================================================
// - Sombreamento de 3 bandas com transicoes calibradas via smoothstep
// - Anime sun glint / specular highlight com recorte cel afiado (Ghibli style)
// - Rim Light Fresnel com silhouette glow ativo dia e noite
// - Sombras ceruleas com modulacao de saturacao e oclusao de ambiente estilizada

group_uniforms Albedo;
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);

group_uniforms Cel_Lighting;
// 3 Bandas de Iluminacao: Sombra Cerulea -> Meio-Tom -> Luz Direta
uniform vec4 shadow_tint : source_color = vec4(0.28, 0.38, 0.58, 1.0); // Azul ceruleo tipico BotW
uniform float shadow_saturation : hint_range(0.0, 2.0, 0.05) = 1.1;   // Controle de vivacidade da sombra
uniform vec4 midtone_tint : source_color = vec4(0.78, 0.85, 0.92, 1.0);
uniform float shadow_cut_mid : hint_range(0.0, 1.0, 0.01) = 0.35;
uniform float shadow_cut_bright : hint_range(0.0, 1.0, 0.01) = 0.70;
uniform float shadow_smoothness : hint_range(0.001, 0.3, 0.001) = 0.035;

group_uniforms Stylized_Ambient_Occlusion;
uniform float ao_strength : hint_range(0.0, 1.0, 0.02) = 0.4;
uniform sampler2D ao_texture : hint_default_white, filter_linear_mipmap, repeat_enable;

group_uniforms Rim_Lighting;
// Rim Lighting (Fresnel) para destacar silhuetas contra qualquer fundo (dia ou noite)
uniform vec4 rim_color : source_color = vec4(0.75, 0.90, 1.0, 1.0);
uniform float rim_power : hint_range(0.5, 16.0, 0.1) = 3.2;
uniform float rim_intensity : hint_range(0.0, 5.0, 0.05) = 0.75;
uniform float rim_smoothness : hint_range(0.001, 0.5, 0.01) = 0.06;
uniform float rim_ambient_silhouette : hint_range(0.0, 1.0, 0.05) = 0.30; // Brilho de contorno constante (noite/sombra)

group_uniforms Specular_Glint;
// Anime / Ghibli Sun Glint afiado com corte toon
uniform vec4 specular_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float specular_size : hint_range(0.001, 0.5, 0.002) = 0.05;
uniform float specular_smoothness : hint_range(0.001, 0.1, 0.002) = 0.012; // Transicao ultra-afiada
uniform float glint_intensity : hint_range(0.0, 4.0, 0.1) = 1.6;

group_uniforms PBR_Maps;
uniform float metallic_value : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform sampler2D metallic_texture : hint_default_white, filter_linear_mipmap, repeat_enable;

uniform float roughness_value : hint_range(0.0, 1.0, 0.01) = 0.75;
uniform sampler2D roughness_texture : hint_default_white, filter_linear_mipmap, repeat_enable;

uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0, 0.1) = 1.0;

group_uniforms Emission;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy : hint_range(0.0, 16.0, 0.1) = 0.0;
uniform sampler2D emission_texture : hint_default_black, filter_linear_mipmap, repeat_enable;

varying vec3 v_normal;
varying vec3 v_view;

void vertex() {
	v_normal = NORMAL;
	v_view = -VERTEX;
}

// Ajuste de saturacao de cor RGB
vec3 adjust_saturation(vec3 color, float sat) {
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	return mix(vec3(gray), color, sat);
}

void fragment() {
	vec2 uv = UV * uv_scale + uv_offset;
	vec4 albedo_tex = texture(albedo_texture, uv);
	ALBEDO = albedo_color.rgb * albedo_tex.rgb;

	float metal_tex = texture(metallic_texture, uv).r;
	METALLIC = metallic_value * metal_tex;

	float rough_tex = texture(roughness_texture, uv).r;
	ROUGHNESS = roughness_value * rough_tex;

	NORMAL_MAP = texture(normal_texture, uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;

	// Oclusao de ambiente estilizada
	float ao_tex = texture(ao_texture, uv).r;
	float final_ao = mix(1.0, ao_tex, ao_strength);
	ALBEDO *= final_ao;

	// Rim Light constante de silhueta (BotW silhouette highlight ativo dia/noite)
	float n_dot_v = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float fresnel = pow(1.0 - n_dot_v, rim_power);
	float rim_step = smoothstep(0.4 - rim_smoothness, 0.4 + rim_smoothness, fresnel);
	vec3 silhouette_glow = rim_color.rgb * rim_step * rim_intensity * rim_ambient_silhouette;

	vec4 emit_tex = texture(emission_texture, uv);
	EMISSION = emission_color.rgb * emit_tex.rgb * emission_energy + silhouette_glow;
}

void light() {
	// NdotL suavizado com atenuacao
	float n_dot_l = dot(NORMAL, LIGHT);
	float light_intensity = clamp((n_dot_l * 0.5 + 0.5) * ATTENUATION, 0.0, 1.0);

	// 3 Bandas Cel Shading com recorte suave via smoothstep
	float s_mid = smoothstep(shadow_cut_mid - shadow_smoothness, shadow_cut_mid + shadow_smoothness, light_intensity);
	float s_bright = smoothstep(shadow_cut_bright - shadow_smoothness, shadow_cut_bright + shadow_smoothness, light_intensity);

	// Sombra cerulea com saturacao calibrada
	vec3 tuned_shadow = adjust_saturation(shadow_tint.rgb, shadow_saturation);
	vec3 cel_band = mix(tuned_shadow, midtone_tint.rgb, s_mid);
	cel_band = mix(cel_band, vec3(1.0), s_bright);

	// Fresnel Rim Light dependente da luz (borda iluminada pelo sol)
	float n_dot_v = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - n_dot_v, rim_power);
	float rim_step = smoothstep(0.4 - rim_smoothness, 0.4 + rim_smoothness, fresnel);
	float light_facing = clamp(n_dot_l * 0.6 + 0.4, 0.0, 1.0);
	vec3 rim_term = rim_color.rgb * rim_step * rim_intensity * light_facing * (1.0 - rim_ambient_silhouette);

	// Anime / Ghibli Sun Glint estilizado (specular afiado)
	vec3 half_vec = normalize(VIEW + LIGHT);
	float n_dot_h = clamp(dot(NORMAL, half_vec), 0.0, 1.0);
	float spec_thresh = 1.0 - specular_size * (1.0 - ROUGHNESS * 0.6);
	float glint = smoothstep(spec_thresh - specular_smoothness, spec_thresh + specular_smoothness, n_dot_h);
	// O glint so acende na banda brilhante sob luz direta (recorte anime puro)
	glint *= s_bright * ATTENUATION;
	vec3 spec_term = specular_color.rgb * glint * glint_intensity;

	// Acumulacao final de luz difusa, rim e glint
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * cel_band + rim_term * LIGHT_COLOR;
	SPECULAR_LIGHT += spec_term * LIGHT_COLOR;
}
