extends Control

# Переменные элементов UI
var bg_art: TextureRect
var dark_overlay: ColorRect
var ui_container: VBoxContainer
var title_label: Label
var reason_label: Label
var restart_button: Button
var music_player: AudioStreamPlayer
var vhs_rect: ColorRect

# Ресурсы
var default_art = preload("res://icons/lucid-origin_Stylized_2D_digital_art_dark_comic_book_illustration._Low_angle_view_from_behind-0.jpg")
var default_music = preload("res://sounds/Among Us sounds on guitar 2 (tasks).mp3")
var custom_font = preload("res://fonts/ShareTechMono-Regular.ttf")

func _ready():
	set_anchors_preset(PRESET_FULL_RECT)
	_build_ui()
	_play_defeat_sequence()

func _build_ui():
	# --- 1. ФОНОВЫЙ АРТ ---
	bg_art = TextureRect.new()
	bg_art.set_anchors_preset(PRESET_FULL_RECT)
	bg_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_art.texture = default_art
	add_child(bg_art)

	# --- 2. НОВЫЙ VHS-ШЕЙДЕР (Хроматическая аберрация + Тейп-глитч) ---
	_setup_vhs_effect()

	# --- 3. ТЕМНЫЙ ОВЕРЛЕЙ (Для скрытия фона и затемнения UI) ---
	dark_overlay = ColorRect.new()
	dark_overlay.set_anchors_preset(PRESET_FULL_RECT)
	dark_overlay.color = Color(0, 0, 0, 1.0) # Старт: 100% черный экран
	add_child(dark_overlay)

	# --- 4. МУЗЫКА ---
	music_player = AudioStreamPlayer.new()
	music_player.stream = default_music
	add_child(music_player)

	# --- 5. КОНТЕЙНЕР ДЛЯ ИНТЕРФЕЙСА ---
	ui_container = VBoxContainer.new()
	ui_container.set_anchors_preset(PRESET_CENTER)
	ui_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ui_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	ui_container.alignment = BoxContainer.ALIGNMENT_CENTER
	ui_container.add_theme_constant_override("separation", 20)
	ui_container.modulate.a = 0.0 # Изначально UI скрыт
	add_child(ui_container)

	# --- 6. ЗАГОЛОВОК ---
	title_label = Label.new()
	title_label.text = "SYSTEM COMPROMISED"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))
	if custom_font:
		title_label.add_theme_font_override("font", custom_font)
	title_label.add_theme_font_size_override("font_size", 38)
	ui_container.add_child(title_label)

	# --- 7. ПРИЧИНА ПОРАЖЕНИЯ ---
	reason_label = Label.new()
	reason_label.text = "The Virus crushed your mind with a chess piece..."
	reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	if custom_font:
		reason_label.add_theme_font_override("font", custom_font)
	reason_label.add_theme_font_size_override("font_size", 18)
	ui_container.add_child(reason_label)

	# --- 8. КНОПКА ПЕРЕЗАПУСКА ---
	restart_button = Button.new()
	restart_button.text = "  REBOOT SYSTEM  "
	restart_button.custom_minimum_size = Vector2(240, 50)
	restart_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	if custom_font:
		restart_button.add_theme_font_override("font", custom_font)
	restart_button.add_theme_font_size_override("font_size", 18)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.1, 0.05, 0.12, 0.9)
	btn_style.border_color = Color(0.7, 0.2, 0.9)
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(6)
	
	var btn_hover = btn_style.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color(0.2, 0.08, 0.25, 0.95)
	btn_hover.border_color = Color(1.0, 0.3, 0.3)
	
	restart_button.add_theme_stylebox_override("normal", btn_style)
	restart_button.add_theme_stylebox_override("hover", btn_hover)
	restart_button.add_theme_stylebox_override("pressed", btn_style)
	restart_button.add_theme_color_override("font_color", Color(1, 1, 1))
	
	restart_button.pressed.connect(_on_restart_pressed)
	ui_container.add_child(restart_button)

# --- СОЗДАНИЕ VHS ШЕЙДЕРА В КОДЕ ---
func _setup_vhs_effect():
	vhs_rect = ColorRect.new()
	vhs_rect.set_anchors_preset(PRESET_FULL_RECT)
	
	var shader_code = """
	shader_type canvas_item;
	uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

	float random(vec2 uv) {
		return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
	}

	void fragment() {
		vec2 uv = SCREEN_UV;
		
		// Легкое вертикальное поддрагивание пленки
		float tape_jitter = sin(TIME * 30.0) * 0.001;
		uv.y += tape_jitter;

		// RGB Split / Хроматическая аберрация по краям
		float shift = 0.003 * (1.0 + sin(TIME * 5.0) * 0.5);
		float r = texture(screen_texture, vec2(uv.x + shift, uv.y)).r;
		float g = texture(screen_texture, uv).g;
		float b = texture(screen_texture, vec2(uv.x - shift, uv.y)).b;

		// Мелкий аналоговый шум VHS
		float noise = (random(uv + vec2(TIME * 0.1)) - 0.5) * 0.05;

		COLOR = vec4(r + noise, g + noise, b + noise, 1.0);
	}
	"""
	
	var shader = Shader.new()
	shader.code = shader_code
	
	var mat = ShaderMaterial.new()
	mat.shader = shader
	
	vhs_rect.material = mat
	add_child(vhs_rect)

# --- ПЛАВНАЯ АНИМАЦИЯ ПОЯВЛЕНИЯ ---
func _play_defeat_sequence():
	if music_player and music_player.stream:
		music_player.play()

	dark_overlay.modulate.a = 1.0
	
	var fade_tween = create_tween()
	fade_tween.tween_property(dark_overlay, "modulate:a", 0.5, 1.8)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await fade_tween.finished

	var ui_tween = create_tween()
	ui_tween.tween_property(ui_container, "modulate:a", 1.0, 0.8)

func _on_restart_pressed():
	get_tree().change_scene_to_file("res://scenes/chess_game_scene.tscn")
