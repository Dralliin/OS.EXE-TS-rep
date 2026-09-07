shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float scanline_count : hint_range(0.0, 1080.0) = 300.0;
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.15;
uniform float rgb_shift : hint_range(0.0, 0.05) = 0.0015; 
uniform float screen_blink : hint_range(0.0, 0.1) = 0.01;
uniform float switch_on_pct : hint_range(0.0, 1.0) = 1.0;

// Настройки строго идущих полос шума
uniform float bar_speed : hint_range(0.0, 5.0) = 0.5;      // Скорость бега полос вниз
uniform float bar_opacity : hint_range(0.0, 1.0) = 0.25;   // Плотность шума внутри полосы
uniform float bar_height : hint_range(0.01, 0.2) = 0.03;   // Высота полос (сделали тонкими)

float rand(vec2 co) {
	return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 curve(vec2 uv) {
	uv = (uv - 0.5) * 2.0;
	uv.x *= 1.0 + pow((uv.y / 6.0), 2.0); 
	uv.y *= 1.0 + pow((uv.x / 5.0), 2.0);
	uv = (uv / 2.0) + 0.5;
	return uv;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Эффект включения/выключения кинескопа
	uv = (uv - 0.5) * vec2(1.0 / max(switch_on_pct, 0.001), 1.0 / max(pow(switch_on_pct, 4.0), 0.001)) + 0.5;
	uv = curve(uv);
	
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0 || switch_on_pct <= 0.01) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		float time = TIME;
		
		// Логика движения трех полос сверху вниз (твоя старая, чистая)
		float bar_mask = 0.0;
		float pos1 = fract(time * bar_speed);
		float pos2 = fract(time * bar_speed + 0.33);
		float pos3 = fract(time * bar_speed + 0.66);
		
		if (uv.y > pos1 && uv.y < pos1 + bar_height) bar_mask = 1.0;
		if (uv.y > pos2 && uv.y < pos2 + bar_height) bar_mask = 1.0;
		if (uv.y > pos3 && uv.y < pos3 + bar_height) bar_mask = 1.0;
		
		// ЭФФЕКТ ВСПЫШКИ ПРИ ВКЛЮЧЕНИИ:
		// Пока экран открывается (switch_on_pct < 1.0), мы искусственно выкручиваем RGB-сдвиг на максимум
		float launch_modifier = clamp(1.0 - switch_on_pct, 0.0, 1.0);
		float current_rgb = rgb_shift + (bar_mask * 0.002) + (launch_modifier * 0.04); // Сильное расслоение при старте
		
		// При старте строки слегка дёргаются по горизонтали, но как только экран открылся — замирают
		float launch_jitter = (rand(vec2(uv.y, time)) - 0.5) * 0.03 * launch_modifier;
		
		float r = texture(SCREEN_TEXTURE, vec2(uv.x + current_rgb + launch_jitter, uv.y)).r;
		float g = texture(SCREEN_TEXTURE, vec2(uv.x + launch_jitter, uv.y)).g;
		float b = texture(SCREEN_TEXTURE, vec2(uv.x - current_rgb + launch_jitter, uv.y)).b;
		
		vec3 final_color = vec3(r, g, b);
		
		// Наложение пиксельного шума внутрь полос
		if (bar_mask > 0.5) {
			float static_noise = rand(vec2(uv.x * time, uv.y * time));
			final_color = mix(final_color, final_color + vec3(static_noise * 0.5 - 0.25), bar_opacity);
		}
		
		// Сетка экрана и мерцание
		float scanline = sin(uv.y * scanline_count * PI * 2.0);
		scanline = (scanline + 1.0) / 2.0;
		scanline = mix(1.0, scanline, scanline_opacity);
		
		float blink = 1.0 - (sin(time * 50.0) * screen_blink);
		final_color *= scanline * blink;
		
		// Фоновый шум
		final_color += vec3(rand(vec2(uv.x * time, uv.y * time)) * 0.015);
		
		// МОЩНАЯ РЕАЛИСТИЧНАЯ ВСПЫШКА:
		// Делаем засветку кадра в момент раскрытия луча (резкий белый блик, который быстро гаснет)
		final_color += vec3(pow(launch_modifier, 2.0) * 0.8); 
		
		COLOR = vec4(final_color, 1.0);
	}
}