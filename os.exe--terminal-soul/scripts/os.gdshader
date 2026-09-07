shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float scanline_strength : hint_range(0.0, 1.0) = 0.10;   // Мягкие, ненавязчивые полосы
uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.35;  // Легкое затемнение по углам
uniform float brightness : hint_range(0.0, 2.0) = 1.0;           // Яркость экрана

// Параметр анимации включения/выключения
uniform float switch_on_pct : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Безопасная горизонтальная анимация схлопывания без искажения координат кнопок
	uv = (uv - 0.5) * vec2(1.0 / max(switch_on_pct, 0.001), 1.0 / max(pow(switch_on_pct, 4.0), 0.001)) + 0.5;
	
	// Если кадр сжимается, всё что за его пределами — гасим в чёрный
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0 || switch_on_pct <= 0.01) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		// Читаем текстуру без искажения линзы — иконки встанут ровно!
		vec4 col = texture(SCREEN_TEXTURE, uv);
		
		// Аккуратные горизонтальные сканирующие линии
		float scanline = sin(uv.y * 500.0 * PI * 2.0);
		scanline = (scanline + 1.0) / 2.0;
		scanline = mix(1.0, scanline, scanline_strength);
		
		// Мягкая угловая виньетка, создающая глубину
		float vignette = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
		vignette = clamp(pow(16.0 * vignette, vignette_intensity), 0.0, 1.0);
		
		// Эффект вспышки фосфора при зажигании экрана
		float launch_modifier = clamp(1.0 - switch_on_pct, 0.0, 1.0);
		vec3 flash = vec3(pow(launch_modifier, 2.0) * 0.5);
		
		vec3 final_rgb = (col.rgb * scanline * vignette * brightness) + flash;
		
		COLOR = vec4(final_rgb, 1.0);
	}
}