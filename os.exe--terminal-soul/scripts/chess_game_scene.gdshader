shader_type canvas_item;

// Текстура экрана под ColorRect
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Переменные интенсивности (меняются из GDScript)
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float color_split : hint_range(0.0, 0.05) = 0.0;

// Простой шум для эффекта
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // Полосы сдвига по горизонтали
    if (glitch_intensity > 0.0) {
        float time_block = floor(TIME * 20.0);
        float line_noise = random(vec2(floor(uv.y * 30.0), time_block));
        
        if (line_noise < glitch_intensity * 0.4) {
            float shift = (random(vec2(time_block, uv.y)) - 0.5) * 0.08 * glitch_intensity;
            uv.x += shift;
        }
    }
    
    // Хроматическая аберрация (расслоение RGB каналов)
    float split = color_split + (glitch_intensity * 0.015);
    float r = texture(screen_texture, uv + vec2(split, 0.0)).r;
    float g = texture(screen_texture, uv).g;
    float b = texture(screen_texture, uv - vec2(split, 0.0)).b;
    
    COLOR = vec4(r, g, b, 1.0);
}