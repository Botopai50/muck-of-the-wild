shader_type sky;

// ====================================================================
// BOTW DYNAMIC SKY SHADER (BREATH OF THE WILD AESTHETICS - ULTRA)
// ====================================================================
// - Transicoes perfeitas de 4 fases (aurora dourada, meio-dia vibrante, 
//   por do sol magenta/cobre com haze, noite estrelada)
// - Nuvens cumulus procedurais estilizadas com bordas suaves e
//   efeito de iluminacao solar na crista (silver lining / sunlit crests)
// - Disco solar e lunar estilizados com halo atmosferico

group_uniforms Time_And_Cycle;
uniform bool use_light_direction = false;
// Hora do dia de 0.0 a 24.0 (0=Meia-noite, 6=Aurora, 12=Meio-dia, 18=Por do sol)
uniform float time_of_day : hint_range(0.0, 24.0, 0.1) = 12.0;

group_uniforms Dawn_Palette;
uniform vec4 dawn_zenith : source_color = vec4(0.36, 0.42, 0.70, 1.0);  // Lilas suave
uniform vec4 dawn_horizon : source_color = vec4(0.98, 0.68, 0.36, 1.0); // Pessego / ambar dourado
uniform vec4 dawn_haze : source_color = vec4(1.0, 0.80, 0.54, 1.0);    // Bruma dourada

group_uniforms Noon_Palette;
uniform vec4 noon_zenith : source_color = vec4(0.14, 0.48, 0.90, 1.0);  // Azul ceruleo vibrante BotW
uniform vec4 noon_horizon : source_color = vec4(0.64, 0.84, 0.96, 1.0); // Ciano suave
uniform vec4 noon_haze : source_color = vec4(0.82, 0.94, 1.00, 1.0);   // Bruma aerea cristalina

group_uniforms Sunset_Palette;
uniform vec4 sunset_zenith : source_color = vec4(0.24, 0.14, 0.44, 1.0); // Magenta profundo / indigo
uniform vec4 sunset_horizon : source_color = vec4(0.98, 0.38, 0.16, 1.0);// Cobre / tangerina incandescente
uniform vec4 sunset_haze : source_color = vec4(0.99, 0.54, 0.26, 1.0);   // Bruma de ocaso quente

group_uniforms Night_Palette;
uniform vec4 night_zenith : source_color = vec4(0.012, 0.022, 0.075, 1.0); // Azul meia-noite profundo
uniform vec4 night_horizon : source_color = vec4(0.045, 0.075, 0.16, 1.0); // Azul escuro petrolio
uniform vec4 night_haze : source_color = vec4(0.07, 0.11, 0.22, 1.0);     // Bruma noturna
uniform vec4 ground_color : source_color = vec4(0.06, 0.08, 0.07, 1.0);

group_uniforms Atmosphere_Haze;
uniform float horizon_haze_intensity : hint_range(0.0, 1.0, 0.02) = 0.68;
uniform float horizon_haze_exponent : hint_range(0.5, 8.0, 0.1) = 2.8;

group_uniforms Sun_And_Moon;
uniform vec4 sun_color : source_color = vec4(1.0, 0.96, 0.86, 1.0);
uniform float sun_disk_size : hint_range(0.001, 0.05, 0.001) = 0.016;
uniform float sun_disk_smoothness : hint_range(0.0001, 0.01, 0.0005) = 0.002;
uniform float sun_corona_size : hint_range(10.0, 120.0, 2.0) = 45.0;

uniform vec4 moon_color : source_color = vec4(0.85, 0.92, 1.0, 1.0);
uniform float moon_disk_size : hint_range(0.001, 0.05, 0.001) = 0.013;

group_uniforms Stars_Settings;
uniform float star_density : hint_range(0.0001, 0.01, 0.0002) = 0.003;
uniform float star_scale : hint_range(50.0, 500.0, 10.0) = 220.0;
uniform float star_twinkle_speed : hint_range(0.0, 10.0, 0.5) = 3.2;
uniform float star_intensity : hint_range(0.0, 5.0, 0.1) = 2.2;

group_uniforms Cumulus_Clouds;
uniform bool enable_clouds = true;
uniform vec4 cloud_color_lit : source_color = vec4(1.0, 0.99, 0.96, 1.0);
uniform vec4 cloud_color_shadow : source_color = vec4(0.68, 0.74, 0.86, 1.0);
uniform vec4 cloud_crest_tint : source_color = vec4(1.0, 0.95, 0.80, 1.0);
uniform float cloud_coverage : hint_range(0.0, 1.0, 0.02) = 0.50;
uniform float cloud_softness : hint_range(0.01, 0.5, 0.01) = 0.14;
uniform float cloud_speed : hint_range(0.0, 2.0, 0.02) = 0.045;
uniform float cloud_scale : hint_range(0.1, 5.0, 0.1) = 1.0;
uniform float cloud_crest_intensity : hint_range(0.0, 3.0, 0.1) = 1.4;
uniform vec2 cloud_direction = vec2(1.0, 0.35);

// Calculo de peso Hermite suave para transicao entre periodos do dia
float calc_phase_weight(float cur_time, float target_time) {
	float diff = min(abs(cur_time - target_time), 24.0 - abs(cur_time - target_time));
	float w = clamp(1.0 - diff / 6.0, 0.0, 1.0);
	return w * w * (3.0 - 2.0 * w); // Hermite smoothstep
}

void sky() {
	// 1. Determina vetor do sol/lua e ciclo horario continuo de 24h
	float current_hour = time_of_day;
	vec3 effective_sun_dir = vec3(0.0, 1.0, 0.0);

	if (use_light_direction && LIGHT0_ENABLED) {
		effective_sun_dir = LIGHT0_DIRECTION;
		float sun_y = LIGHT0_DIRECTION.y;
		float sun_x = LIGHT0_DIRECTION.x;
		if (sun_y >= 0.0) {
			current_hour = (sun_x >= 0.0) ? mix(6.0, 12.0, sun_y) : mix(18.0, 12.0, sun_y);
		} else {
			current_hour = (sun_x < 0.0) ? mix(18.0, 24.0, -sun_y) : mix(0.0, 6.0, 1.0 + sun_y);
		}
	} else {
		float sun_rad = (current_hour / 24.0) * 3.14159265 * 2.0 - 1.5707963;
		effective_sun_dir = normalize(vec3(cos(sun_rad), sin(sun_rad), 0.25));
	}
	vec3 effective_moon_dir = -effective_sun_dir;

	// Pesos perfeitamente continuos das 4 fases:
	float norm_hour = mod(current_hour, 24.0);
	float w_dawn   = calc_phase_weight(norm_hour, 6.0);
	float w_noon   = calc_phase_weight(norm_hour, 12.0);
	float w_sunset = calc_phase_weight(norm_hour, 18.0);
	float w_night  = calc_phase_weight(norm_hour, 0.0);

	float total_w = w_dawn + w_noon + w_sunset + w_night + 0.0001;
	w_dawn /= total_w;
	w_noon /= total_w;
	w_sunset /= total_w;
	w_night /= total_w;

	// Interpolacao quadrupla de cores
	vec3 cur_zenith  = dawn_zenith.rgb * w_dawn + noon_zenith.rgb * w_noon + sunset_zenith.rgb * w_sunset + night_zenith.rgb * w_night;
	vec3 cur_horizon = dawn_horizon.rgb * w_dawn + noon_horizon.rgb * w_noon + sunset_horizon.rgb * w_sunset + night_horizon.rgb * w_night;
	vec3 cur_haze    = dawn_haze.rgb * w_dawn + noon_haze.rgb * w_noon + sunset_haze.rgb * w_sunset + night_haze.rgb * w_night;

	// 2. Gradiente vertical de ceu e Haze atmosferico BotW
	float eye_y = EYEDIR.y;
	vec3 sky_color;
	if (eye_y >= 0.0) {
		sky_color = mix(cur_horizon, cur_zenith, pow(eye_y, 0.62));
	} else {
		sky_color = mix(cur_horizon, ground_color.rgb, clamp(-eye_y * 2.6, 0.0, 1.0));
	}

	// Bruma atmosferica no horizonte
	float horizon_proximity = 1.0 - abs(eye_y);
	float haze_factor = pow(clamp(horizon_proximity, 0.0, 1.0), horizon_haze_exponent);
	sky_color = mix(sky_color, cur_haze, haze_factor * horizon_haze_intensity);

	// 3. Disco Solar Estilizado e Corona
	float sun_dot = max(dot(EYEDIR, effective_sun_dir), 0.0);
	float sun_cutoff = 1.0 - sun_disk_size;
	float sun_disk = smoothstep(sun_cutoff - sun_disk_smoothness, sun_cutoff + sun_disk_smoothness, sun_dot);
	float sun_corona = pow(sun_dot, sun_corona_size) * 0.45;
	float day_factor = clamp(effective_sun_dir.y * 3.5, 0.0, 1.0);
	vec3 sun_render = (sun_color.rgb * sun_disk * 2.4 + cur_haze * sun_corona) * day_factor;
	sky_color += sun_render;

	// Disco Lunar Estilizado
	float moon_dot = max(dot(EYEDIR, effective_moon_dir), 0.0);
	float moon_cutoff = 1.0 - moon_disk_size;
	float moon_disk = smoothstep(moon_cutoff - 0.001, moon_cutoff + 0.001, moon_dot);
	float night_factor = clamp(effective_moon_dir.y * 3.0, 0.0, 1.0);
	sky_color += moon_color.rgb * moon_disk * 1.8 * night_factor * w_night;

	// 4. Estrelas cintilantes no ceu noturno
	if (w_night > 0.02 && eye_y > 0.04) {
		vec3 star_coord = floor(EYEDIR * star_scale);
		float star_hash = fract(sin(dot(star_coord, vec3(12.9898, 78.233, 45.164))) * 43758.5453);
		if (star_hash > (1.0 - star_density)) {
			float twinkle = sin(TIME * star_twinkle_speed + star_hash * 62.8) * 0.35 + 0.65;
			vec3 star_col = vec3(0.92, 0.96, 1.0) * twinkle * star_intensity * w_night;
			sky_color += star_col;
		}
	}

	// 5. Nuvens Cumulus Procedurais Estilizadas com Iluminacao Solar na Crista
	if (enable_clouds && eye_y > 0.015) {
		vec2 c_dir = normalize(cloud_direction);
		vec2 c_uv = (EYEDIR.xz / max(eye_y + 0.16, 0.12)) * cloud_scale * 0.26 + c_dir * (TIME * cloud_speed * 0.04);

		// Distorcao harmonica (domain warping) para volumes fofos de cumulus
		vec2 warp = vec2(sin(c_uv.y * 2.4 + TIME * cloud_speed * 0.02), cos(c_uv.x * 2.4));
		vec2 w_uv = c_uv + warp * 0.28;

		float n1 = sin(w_uv.x * 2.8 + sin(w_uv.y * 2.2));
		float n2 = cos(w_uv.x * 4.6 - cos(w_uv.y * 3.8));
		float n3 = sin(w_uv.x * 8.8 + w_uv.y * 8.2) * 0.5;
		float cumulus_shape = (n1 + n2 + n3) * 0.36 + 0.5;

		// Mascara de densidade com bordas suaves
		float cloud_mask = smoothstep(cloud_coverage, cloud_coverage + cloud_softness, cumulus_shape);
		cloud_mask *= smoothstep(0.015, 0.22, eye_y); // Dissolve no horizonte distante

		// Efeito de iluminacao solar na crista (Silver Lining / Sunlit Rim)
		float crest_edge = smoothstep(cloud_coverage + cloud_softness * 0.6, cloud_coverage + cloud_softness * 1.5, cumulus_shape);
		float sun_alignment = clamp(dot(EYEDIR, effective_sun_dir) * 0.5 + 0.5, 0.0, 1.0);
		float crest_light = pow(crest_edge, 1.4) * (sun_alignment * 0.6 + 0.4) * cloud_crest_intensity * day_factor;

		// Shading artistico das nuvens (sombra ambiente -> corpo iluminado -> crista ensolarada)
		vec3 c_shaded = mix(cur_horizon * 0.7 + cur_zenith * 0.3, cloud_color_shadow.rgb, 0.65);
		vec3 c_lit = mix(cloud_color_lit.rgb, cur_haze, 0.2);
		vec3 c_crest = mix(cloud_crest_tint.rgb, sun_color.rgb, 0.5) * 1.35;

		vec3 cloud_final = mix(c_shaded, c_lit, smoothstep(cloud_coverage, 0.82, cumulus_shape));
		cloud_final = mix(cloud_final, c_crest, clamp(crest_light, 0.0, 1.0));

		// Modula nuvens pela noite (nuvens noturnas tingidas pela lua e horizonte escuro)
		cloud_final = mix(cloud_final, cur_horizon * 1.2 + vec3(0.02, 0.03, 0.06), w_night * 0.85);

		sky_color = mix(sky_color, cloud_final, cloud_mask * 0.94);
	}

	COLOR = sky_color;
}
