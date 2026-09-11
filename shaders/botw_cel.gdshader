shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// ====================================================================
// BOTW UNIVERSAL CEL SHADER (BREATH OF THE WILD AESTHETICS)
// ====================================================================
// Suporta 3 bandas estilizadas com transicoes suaves, sombras ceruleas,
// Fresnel rim-lighting e mapas PBR completos.

group_uniforms Albedo;
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);

group_uniforms Cel_Lighting;
// 3 Bandas de Iluminacao: Sombra, Meio-Tom e Luz Direta Brilhante
uniform vec4 shadow_tint : source_color = vec4(0.28, 0.38, 0.58, 1.0); // Azul ceruleo tipico BotW
uniform vec4 midtone_tint : source_color = vec4(0.78, 0.85, 0.92, 1.0);
uniform float shadow_cut_mid : hint_range(0.0, 1.0, 0.01) = 0.35;
uniform float shadow_cut_bright : hint_range(0.0, 1.0, 0.01) = 0.70;
uniform float shadow_smoothness : hint_range(0.001, 0.5, 0.001) = 0.04;

group_uniforms Rim_Lighting;
// Rim Lighting (Fresnel) para destacar silhuetas contra o cenario
uniform vec4 rim_color : source_color = vec4(0.75, 0.90, 1.0, 1.0);
uniform float rim_power : hint_range(0.5, 16.0, 0.1) = 3.5;
uniform float rim_intensity : hint_range(0.0, 5.0, 0.05) = 0.65;
uniform float rim_smoothness : hint_range(0.001, 0.5, 0.01) = 0.08;

group_uniforms Specular;
uniform vec4 specular_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float specular_size : hint_range(0.0, 1.0, 0.01) = 0.06;
uniform float specular_smoothness : hint_range(0.001, 0.5, 0.01) = 0.02;

group_uniforms PBR_Maps;
uniform float metallic_value : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform sampler2D metallic_texture : hint_default_white, filter_linear_mipmap, repeat_enable;

uniform float roughness_value : hint_range(0.0, 1.0, 0.01) = 0.8;
uniform sampler2D roughness_texture : hint_default_white, filter_linear_mipmap, repeat_enable;

uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0, 0.1) = 1.0;

group_uniforms Emission;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy : hint_range(0.0, 16.0, 0.1) = 0.0;
uniform sampler2D emission_texture : hint_default_black, filter_linear_mipmap, repeat_enable;

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

	vec4 emit_tex = texture(emission_texture, uv);
	EMISSION = emission_color.rgb * emit_tex.rgb * emission_energy;
}

void light() {
	// NdotL suavizado com atenuacao (sombras e distancia de luzes)
	float n_dot_l = dot(NORMAL, LIGHT);
	float light_intensity = clamp((n_dot_l * 0.5 + 0.5) * ATTENUATION, 0.0, 1.0);

	// 3 Bandas Cel Shading com transicao smoothstep
	float s_mid = smoothstep(shadow_cut_mid - shadow_smoothness, shadow_cut_mid + shadow_smoothness, light_intensity);
	float s_bright = smoothstep(shadow_cut_bright - shadow_smoothness, shadow_cut_bright + shadow_smoothness, light_intensity);

	// Gradiente entre sombra cerulea -> meio-tom -> luz direta
	vec3 cel_band = mix(shadow_tint.rgb, midtone_tint.rgb, s_mid);
	cel_band = mix(cel_band, vec3(1.0), s_bright);

	// Rim Lighting estilizado (Fresnel silhouette highlight BotW)
	float n_dot_v = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - n_dot_v, rim_power) * rim_intensity;
	vec3 rim_term = rim_color.rgb * rim * clamp(n_dot_l * 0.5 + 0.5, 0.3, 1.0);

	// Toon Specular Highlight
	vec3 half_vec = normalize(VIEW + LIGHT);
	float n_dot_h = clamp(dot(NORMAL, half_vec), 0.0, 1.0);
	float spec_val = pow(n_dot_h, (1.0 - ROUGHNESS) * 128.0 + 8.0);
	float spec_step = smoothstep(1.0 - specular_size - specular_smoothness, 1.0 - specular_size + specular_smoothness, spec_val);
	vec3 spec_term = specular_color.rgb * spec_step * ATTENUATION * (1.0 - ROUGHNESS);

	// Acumulacao de difusa e especular
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * cel_band + rim_term * LIGHT_COLOR;
	SPECULAR_LIGHT += spec_term * LIGHT_COLOR;
}
