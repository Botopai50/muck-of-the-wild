shader_type spatial;
render_mode blend_add, depth_draw_never, cull_disabled, unshaded;

// ====================================================================
// BOTW ANIME SLASH TRAIL SHADER (WIND & SWORD BLADE ARC)
// ====================================================================
// Efeito de corte em arco translúcido / emissivo (lâmina de vento)
// Suporta desvanecimento dinâmico ao longo do arco (progress, trail_length),
// afunilamento nas pontas (taper), núcleo quente brilhante e gradiente de cor.

group_uniforms Trail_Colors;
uniform vec4 trail_color : source_color = vec4(0.35, 0.78, 1.0, 1.0); // Cor principal do corte
uniform vec4 tip_color : source_color = vec4(0.15, 0.45, 1.0, 1.0);   // Borda externa suave
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);    // Centro branco incandescente
uniform float emission_intensity : hint_range(0.5, 10.0, 0.1) = 3.0;

group_uniforms Animation;
uniform float progress : hint_range(0.0, 1.5, 0.01) = 1.0;           // Progresso do corte (0 -> 1.3)
uniform float trail_length : hint_range(0.05, 1.0, 0.01) = 0.60;     // Comprimento visível do arco
uniform float alpha_mult : hint_range(0.0, 2.0, 0.05) = 1.0;

group_uniforms Shape_Taper;
uniform float inner_fade : hint_range(0.01, 1.0, 0.02) = 0.30;       // Desvanecimento na borda interna
uniform float outer_sharpness : hint_range(0.01, 0.5, 0.01) = 0.08;  // Nitidez da borda externa
uniform float taper_head : hint_range(0.01, 0.5, 0.01) = 0.12;      // Afunilamento na ponta frontal
uniform float taper_tail : hint_range(0.01, 0.8, 0.01) = 0.35;      // Afunilamento no rastro final

void fragment() {
	// UV.x: 0.0 (início do corte) -> 1.0 (ponta da lâmina)
	// UV.y: 0.0 (raio interno) -> 1.0 (raio externo afiado)

	float head_pos = progress;
	float tail_pos = progress - trail_length;

	// Se estiver fora do intervalo ativo, descarta ou zera alfa
	if (UV.x > head_pos || UV.x < tail_pos) {
		ALPHA = 0.0;
		discard;
	}

	// Fade na ponta dianteira
	float head_fade = smoothstep(head_pos, head_pos - max(taper_head * trail_length, 0.001), UV.x);
	// Fade na cauda traseira
	float tail_fade = smoothstep(tail_pos, tail_pos + max(taper_tail * trail_length, 0.001), UV.x);
	float length_mask = head_fade * tail_fade;

	// Afunilamento dinâmico de espessura (largura máxima perto de 60% do rastro)
	float norm_pos = clamp((UV.x - tail_pos) / max(trail_length, 0.001), 0.0, 1.0);
	float width_factor = sin(norm_pos * 3.14159265);
	width_factor = pow(width_factor, 0.55);

	// Gradiente radial (UV.y): borda interna suave, borda externa com fio afiado
	float inner_mask = smoothstep(0.0, inner_fade, UV.y);
	float outer_mask = smoothstep(1.0, 1.0 - outer_sharpness, UV.y);
	float radial_fade = inner_mask * outer_mask;

	// Núcleo brilhante (core hot streak ao longo de UV.y ~ 0.8)
	float core_dist = abs(UV.y - 0.78);
	float core_mask = smoothstep(0.16 * width_factor, 0.0, core_dist);

	// Gradiente de cor estilizado BotW
	vec3 base_col = mix(tip_color.rgb, trail_color.rgb, smoothstep(0.1, 0.85, UV.y));
	vec3 final_color = mix(base_col, core_color.rgb, core_mask * 0.95);

	float alpha = length_mask * radial_fade * width_factor * alpha_mult;

	ALBEDO = final_color * emission_intensity;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
