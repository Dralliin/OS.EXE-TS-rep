shader_type canvas_item;

uniform vec4 bg_dark : source_color = vec4(0.01, 0.02, 0.04, 1.0);
uniform vec4 bg_light : source_color = vec4(0.04, 0.08, 0.12, 1.0);
uniform vec4 grid_color : source_color = vec4(0.08, 0.20, 0.28, 0.25);
uniform vec4 alert_color : source_color = vec4(0.65, 0.08, 0.12, 0.4); // Цвет алого глитча

// Параметры динамики (можно крутить в инспекторе)
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.2;
uniform float pulse_speed : hint_range(0.1, 5.0) = 1.2;

// Простой генератор псевдослучайных чисел
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 st = UV;
	
	// 1. Динамическая виньетка ("дыхание" тьмы по краям)
	float pulse = sin(TIME * pulse_speed) * 0.05;
	float center_dist = distance(st, vec2(0.5));
	vec4 base_bg = mix(bg_light, bg_dark, smoothstep(0.15 + pulse, 0.85 - pulse, center_dist));
	
	// 2. Волны искажения сетки (эффект нестабильного пространства)
	vec2 distorted_uv = st;
	float wave = sin(st.y * 10.0 + TIME * 1.5) * 0.003;
	distorted_uv.x += wave;
	
	// 3. Микро-глитчи (горизонтальное смещение полос)
	float glitch_trigger = step(1.0 - glitch_intensity * 0.05, hash(vec2(floor(TIME * 12.0), st.y * 15.0)));
	float glitch_offset = (hash(vec2(TIME, st.y)) - 0.5) * 0.03 * glitch_trigger;
	distorted_uv.x += glitch_offset;

	// 4. Кибер-сетка с изменяющимся шагом и движением
	vec2 grid_uv = distorted_uv * 30.0;
	grid_uv.y += TIME * 0.1;
	
	vec2 grid_lines = abs(fract(grid_uv - 0.5) - 0.5) / fwidth(grid_uv);
	float line = min(grid_lines.x, grid_lines.y);
	float grid_pattern = 1.0 - min(line, 1.0);
	
	// 5. Динамический цвет сетки (смена цвета при глитче)
	vec4 current_grid_color = mix(grid_color, alert_color, glitch_trigger);
	
	// Добавляем бегущую волну яркости по сетке
	float scan_wave = smoothstep(0.0, 1.0, sin(st.y * 3.0 - TIME * 2.0));
	grid_pattern *= (0.8 + scan_wave * 0.4);

	COLOR = mix(base_bg, current_grid_color, grid_pattern * 0.5);
}