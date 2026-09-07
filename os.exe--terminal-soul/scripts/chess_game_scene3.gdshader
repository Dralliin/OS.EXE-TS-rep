shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float flash_progress : hint_range(0.0, 1.0) = 0.0;

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // Глитч-сдвиг при поражении
    if (flash_progress > 0.2) {
        float noise = random(vec2(floor(uv.y * 20.0), floor(TIME * 30.0)));
        if (noise < flash_progress) {
            uv.x += (random(vec2(TIME, uv.y)) - 0.5) * 0.15 * flash_progress;
        }
    }
    
    vec4 screen_color = texture(screen_texture, uv);
    
    // Красная вспышка с бликом
    vec4 red_tint = vec4(0.9, 0.05, 0.1, 0.7);
    
    // Диагональный блик
    float glare = smoothstep(0.4, 0.6, sin(uv.x + uv.y - TIME * 8.0) * 0.5 + 0.5) * flash_progress;
    
    vec3 result = mix(screen_color.rgb, red_tint.rgb, flash_progress * red_tint.a);
    result += vec3(glare * 0.4); // Добавляем яркость блика
    
    COLOR = vec4(result, 1.0);
}