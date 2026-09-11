shader_type sky;

// ====================================================================
// BOTW DYNAMIC SKY SHADER (BREATH OF THE WILD AESTHETICS)
// ====================================================================
// Gradiente de horizonte atmosferico (haze), ciclo de cores (amanhecer
// dourado, meio-dia vibrante, entardecer magenta, noite estrelada),
// disco solar estilizado e nuvens cumulus pictoricas.

group_uniforms Time_And_Cycle;
uniform bool use_light_direction = false;
// Hora do dia de 0.0 a 24.0 (0=Meia-noite, 6=Amanhecer, 12=Meio-dia, 18=Entardecer)
uniform float time_of_day : hint_range(0.0, 24.0, 0.1) = 12.0;

group_uniforms Dawn_Palette;
uniform vec4 dawn_zenith : source_color = vec4(0.35, 0.42, 0.68, 1.0);
uniform vec4 dawn_horizon : source_color = vec4(0.98, 0.65, 0.38, 1.0);
uniform vec4 dawn_haze : source_color = vec4(1.0, 0.78, 0.52, 1.0);

group_uniforms Noon_Palette;
uniform vec4 noon_zenith : source_color = vec4(0.16, 0.48, 0.88, 1.0); // Azul ceruleo BotW
uniform vec4 noon_horizon : source_color = vec4(0.62, 0.82, 0.94, 1.0);
uniform vec4 noon_haze : source_color = vec4(0.80, 0.92, 1.00, 1.0);

group_uniforms Sunset_Palette;
uniform vec4 sunset_zenith : source_color = vec4(0.22, 0.16, 0.42, 1.0); // Magenta/Indigo
uniform vec4 sunset_horizon : source_color = vec4(0.96, 0.38, 0.18, 1.0); // Laranja vivo
uniform vec4 sunset_haze : source_color = vec4(0.98, 0.52, 0.28, 1.0);

group_uniforms Night_Palette;
uniform vec4 night_zenith : source_color = vec4(0.015, 0.025, 0.08, 1.0); // Azul profundo
uniform vec4 night_horizon : source_color = vec4(0.05, 0.08, 0.16, 1.0);
uniform vec4 night_haze : source_color = vec4(0.08, 0.12, 0.22, 1.0);
uniform vec4 ground_color : source_color = vec4(0.08, 0.10, 0.08, 1.0);

group_uniforms Atmosphere_Haze;
uniform float horizon_haze_intensity : hint_range(0.0, 1.0, 0.02) = 0.65;
uniform float horizon_haze_exponent : hint_range(0.5, 8.0, 0.1) = 3.0;

group_uniforms Sun_Settings;
uniform vec4 sun_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform float sun_disk_size : hint_range(0.001, 0.05, 0.001) = 0.015;
uniform float sun_disk_smoothness : hint_range(0.0001, 0.01, 0.0005) = 0.002;

group_uniforms Stars_Settings;
uniform float star_density : hint_range(0.0001, 0.01, 0.0002) = 0.0025;
uniform float star_scale : hint_range(50.0, 500.0, 10.0) = 220.0;
uniform float star_twinkle_speed : hint_range(0.0, 10.0, 0.5) = 3.0;
uniform float star_intensity : hint_range(0.0, 5.0, 0.1) = 2.0;

group_uniforms Clouds_Settings;
uniform bool enable_clouds = true;
uniform vec4 cloud_color_lit : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 cloud_color_shadow : source_color = vec4(0.70, 0.78, 0.90, 1.0);
uniform float cloud_coverage : hint_range(0.0, 1.0, 0.02) = 0.52;
uniform float cloud_softness : hint_range(0.01, 0.5, 0.01) = 0.12;
uniform float cloud_speed : hint_range(0.0, 2.0, 0.02) = 0.04;
uniform float cloud_scale : hint_range(0.1, 5.0, 0.1) = 1.0;
uniform vec2 cloud_direction = vec2(1.0, 0.3);

void sky() {
	// 1. Determina pesos dos quatro periodos do dia
	float current_hour = time_of_day;
	vec3 effective_sun_dir = vec3(0.0, 1.0, 0.0);

	if (use_light_direction && LIGHT0_ENABLED) {
		effective_sun_dir = LIGHT0_DIRECTION;
		// Estima hora aproximada baseada na elevacao e orientacao do sol
		float sun_y = LIGHT0_DIRECTION.y;
		float sun_x = LIGHT0_DIRECTION.x;
		if (sun_y >= 0.0) {
			// Dia: de 6h (aurora) passando por 12h (zenite) ate 18h (ocaso)
			current_hour = (sun_x >= 0.0) ? mix(6.0, 12.0, sun_y) : mix(18.0, 12.0, sun_y);
		} else {
			// Noite: de 18h passando por 24h/0h ate 6h
			current_hour = (sun_x < 0.0) ? mix(18.0, 24.0, -sun_y) : mix(0.0, 6.0, 1.0 + sun_y);
		}
	} else {
		// Calcula vetor solar estilizado a partir da hora
		float sun_rad = (current_hour / 24.0) * 3.14159265 * 2.0 - 1.5707963;
		effective_sun_dir = normalize(vec3(cos(sun_rad), sin(sun_rad), 0.2));
	}

	// Calculo de pesos de transicao suaves entre periodos (Dawn, Noon, Sunset, Night)
	float w_dawn   = max(0.0, 1.0 - abs(current_hour - 6.0) / 2.5);
	float w_noon   = max(0.0, 1.0 - abs(current_hour - 12.0) / 4.0);
	float w_sunset = max(0.0, 1.0 - abs(current_hour - 18.0) / 2.5);
	float w_night  = 0.0;
	if (current_hour < 4.0 || current_hour > 20.0) {
		w_night = 1.0;
	} else if (current_hour >= 4.0 && current_hour < 6.0) {
		w_night = 1.0 - (current_hour - 4.0) / 2.0;
	} else if (current_hour > 18.0 && current_hour <= 20.0) {
		w_night = (current_hour - 18.0) / 2.0;
	}

	float total_w = w_dawn + w_noon + w_sunset + w_night + 0.0001;
	w_dawn /= total_w;
	w_noon /= total_w;
	w_sunset /= total_w;
	w_night /= total_w;

	// Cores interpoladas para a hora atual
	vec3 cur_zenith  = dawn_zenith.rgb * w_dawn + noon_zenith.rgb * w_noon + sunset_zenith.rgb * w_sunset + night_zenith.rgb * w_night;
	vec3 cur_horizon = dawn_horizon.rgb * w_dawn + noon_horizon.rgb * w_noon + sunset_horizon.rgb * w_sunset + night_horizon.rgb * w_night;
	vec3 cur_haze    = dawn_haze.rgb * w_dawn + noon_haze.rgb * w_noon + sunset_haze.rgb * w_sunset + night_haze.rgb * w_night;

	// 2. Gradiente vertical de ceu e Haze atmosferico
	float eye_y = EYEDIR.y;
	vec3 sky_color;
	if (eye_y >= 0.0) {
		sky_color = mix(cur_horizon, cur_zenith, pow(eye_y, 0.65));
	} else {
		sky_color = mix(cur_horizon, ground_color.rgb, clamp(-eye_y * 2.5, 0.0, 1.0));
	}

	// Bruma atmosferica no horizonte (BotW atmospheric haze)
	float horizon_proximity = 1.0 - abs(eye_y);
	float haze_factor = pow(clamp(horizon_proximity, 0.0, 1.0), horizon_haze_exponent);
	sky_color = mix(sky_color, cur_haze, haze_factor * horizon_haze_intensity);

	// 3. Disco Solar Estilizado
	float sun_dot = max(dot(EYEDIR, effective_sun_dir), 0.0);
	float sun_cutoff = 1.0 - sun_disk_size;
	float sun_disk = smoothstep(sun_cutoff - sun_disk_smoothness, sun_cutoff + sun_disk_smoothness, sun_dot);
	float sun_corona = pow(sun_dot, 48.0) * 0.4;
	float day_factor = clamp(effective_sun_dir.y * 3.0, 0.0, 1.0);
	vec3 sun_render = (sun_color.rgb * sun_disk * 2.2 + cur_haze * sun_corona) * day_factor;
	sky_color += sun_render;

	// 4. Estrelas cintilantes durante a noite
	if (w_night > 0.01 && eye_y > 0.05) {
		vec3 star_coord = floor(EYEDIR * star_scale);
		float star_hash = fract(sin(dot(star_coord, vec3(12.9898, 78.233, 45.164))) * 43758.5453);
		if (star_hash > (1.0 - star_density)) {
			float twinkle = sin(TIME * star_twinkle_speed + star_hash * 62.8) * 0.35 + 0.65;
			vec3 star_col = vec3(0.92, 0.96, 1.0) * twinkle * star_intensity * w_night;
			sky_color += star_col;
		}
	}

	// 5. Nuvens Cumulus estilizadas (BotW fluffy clouds)
	if (enable_clouds && eye_y > 0.02) {
		vec2 c_dir = normalize(cloud_direction);
		vec2 c_uv = (EYEDIR.xz / max(eye_y + 0.15, 0.1)) * cloud_scale * 0.25 + c_dir * (TIME * cloud_speed * 0.05);

		// Padrao procedural multi-frequencia para cumulus fofas
		float n1 = sin(c_uv.x * 3.0 + sin(c_uv.y * 2.0));
		float n2 = cos(c_uv.x * 5.0 - cos(c_uv.y * 4.0));
		float n3 = sin(c_uv.x * 9.0 + c_uv.y * 8.0) * 0.5;
		float cumulus_shape = (n1 + n2 + n3) * 0.35 + 0.5;

		float cloud_mask = smoothstep(cloud_coverage, cloud_coverage + cloud_softness, cumulus_shape);
		// Fade suave na linha do horizonte
		cloud_mask *= smoothstep(0.02, 0.25, eye_y);

		// Tonalizacao estilizada das nuvens pelo sol e ambiente
		vec3 c_shaded = mix(cur_horizon * 0.8, cloud_color_shadow.rgb, 0.6);
		vec3 c_lit = mix(cloud_color_lit.rgb, cur_haze, 0.25);
		vec3 cloud_final = mix(c_shaded, c_lit, smoothstep(cloud_coverage, 0.85, cumulus_shape));

		sky_color = mix(sky_color, cloud_final, cloud_mask * 0.92);
	}

	COLOR = sky_color;
}
