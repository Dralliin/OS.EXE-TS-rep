shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

uniform float static_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float chromatic_aberration : hint_range(0.0, 0.05) = 0.0;

// Генератор случайных чисел
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    float time_step = floor(TIME * 24.0); // Динамика смены кадров шума

    // 1. Горизонтальный сдвиг строк (VHS глитч)
    float line_noise = random(vec2(floor(uv.y * 40.0), time_step));
    if (line_noise < static_intensity * 0.4) {
        float offset = (random(vec2(line_noise, time_step)) - 0.5) * 0.06 * static_intensity;
        uv.x += offset;
    }

    // 2. РГБ-расслоение (Chromatic Aberration)
    float shift = (chromatic_aberration + 0.01) * static_intensity;
    float r = texture(screen_texture, uv + vec2(shift, 0.0)).r;
    float g = texture(screen_texture, uv).g;
    float b = texture(screen_texture, uv - vec2(shift, 0.0)).b;
    vec3 col = vec3(r, g, b);

    // 3. Классический динамический ТВ-шум ("снег")
    // Используем смещение по времени для постоянной пульсации зерен
    float grain = random(uv * 1.5 + vec2(sin(TIME * 50.0), cos(TIME * 30.0)));
    
    col = mix(col, vec3(grain), static_intensity * 0.35);

    // 4. Белые статические полосы-вспышки
    float static_line = random(vec2(time_step, floor(uv.y * 70.0)));
    if (static_line < static_intensity * 0.12) {
        col += vec3(0.25) * static_intensity;
    }

    COLOR = vec4(col, 1.0);
}