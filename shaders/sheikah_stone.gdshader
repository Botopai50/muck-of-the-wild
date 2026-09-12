shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// ====================================================================
// SHEIKAH ANCIENT STONE SHADER (BOTW X MUCK)
// ====================================================================
// Pedra ancestral com bandas de cel-shading BotW e runas Sheikah
// em ciano emissivo pulsante geradas proceduralmente.

group_uniforms Base_Stone;
uniform vec4 stone_color : source_color = vec4(0.36, 0.38, 0.42, 1.0);
uniform vec4 shadow_tint : source_color = vec4(0.20, 0.22, 0.32, 1.0);
uniform vec4 midtone_tint : source_color = vec4(0.50, 0.54, 0.60, 1.0);
uniform float shadow_cut_mid : hint_range(0.0, 1.0) = 0.35;
uniform float shadow_cut_bright : hint_range(0.0, 1.0) = 0.70;
uniform float shadow_smoothness : hint_range(0.001, 0.5) = 0.04;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.88;

group_uniforms Rim_Lighting;
uniform vec4 rim_color : source_color = vec4(0.4, 0.85, 1.0, 1.0);
uniform float rim_power : hint_range(0.5, 16.0) = 3.8;
uniform float rim_intensity : hint_range(0.0, 5.0) = 0.6;

group_uniforms Sheikah_Runes;
uniform vec4 rune_color : source_color = vec4(0.0, 0.92, 1.0, 1.0);
uniform float rune_density : hint_range(1.0, 30.0) = 6.0;
uniform float rune_thickness : hint_range(0.01, 0.3) = 0.08;
uniform float rune_glow_energy : hint_range(0.0, 10.0) = 2.8;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.4;

varying vec3 v_world_pos;
varying vec3 v_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// Procedural Sheikah geometric circuitry pattern
float sheikah_pattern(vec2 p) {
	vec2 g = fract(p) - 0.5;
	vec2 id = floor(p);
	
	// Circuit lines along grid
	float line_x = smoothstep(rune_thickness, 0.0, abs(g.x));
	float line_y = smoothstep(rune_thickness, 0.0, abs(g.y));
	
	// Broken circuit traces using pseudo-random hashing
	float h = fract(sin(dot(id, vec2(12.9898, 78.233))) * 43758.5453);
	float active_trace = step(0.42, h);
	
	// Node circular connectors
	float node_dist = length(g);
	float nodes = smoothstep(rune_thickness * 1.8, rune_thickness * 0.5, node_dist) * step(0.68, h);
	
	// Diagonal circuitry steps
	float diag = smoothstep(rune_thickness, 0.0, abs(g.x + g.y) * 0.7071) * step(0.55, fract(h * 3.7));
	
	return clamp((line_x + line_y) * active_trace * 0.7 + nodes + diag * 0.6, 0.0, 1.0);
}

void fragment() {
	vec2 rune_uv = UV * rune_density;
	if (length(UV) < 0.001) {
		rune_uv = (v_world_pos.xz + v_world_pos.xy) * (rune_density * 0.35);
	}
	
	float runes = sheikah_pattern(rune_uv);
	
	float stone_noise = fract(sin(dot(v_world_pos.xz * 14.0, vec2(12.9898, 4.1414))) * 43758.5453) * 0.08;
	vec3 base_col = stone_color.rgb + vec3(stone_noise);
	
	ALBEDO = mix(base_col, stone_color.rgb * 0.85, runes * 0.4);
	ROUGHNESS = roughness_val;
	METALLIC = 0.05;
	
	float pulse = 0.82 + 0.28 * sin(TIME * pulse_speed + v_world_pos.y * 1.8);
	EMISSION = rune_color.rgb * runes * rune_glow_energy * pulse;
}

void light() {
	float n_dot_l = dot(NORMAL, LIGHT);
	float light_intensity = clamp((n_dot_l * 0.5 + 0.5) * ATTENUATION, 0.0, 1.0);

	float s_mid = smoothstep(shadow_cut_mid - shadow_smoothness, shadow_cut_mid + shadow_smoothness, light_intensity);
	float s_bright = smoothstep(shadow_cut_bright - shadow_smoothness, shadow_cut_bright + shadow_smoothness, light_intensity);

	vec3 cel_band = mix(shadow_tint.rgb, midtone_tint.rgb, s_mid);
	cel_band = mix(cel_band, vec3(1.0), s_bright);

	float n_dot_v = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - n_dot_v, rim_power) * rim_intensity;
	vec3 rim_term = rim_color.rgb * rim * clamp(n_dot_l * 0.5 + 0.5, 0.3, 1.0);

	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * cel_band + rim_term * LIGHT_COLOR;
}
