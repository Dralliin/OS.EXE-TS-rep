extends Control

# Ссылки на кнопки управления окном
@onready var close_button = $Header/CloseButton

# Ссылки на кнопки вкладок
@onready var display_tab_button = $MainContent/Sidebar/DisplayTabButton
@onready var custom_tab_button = $MainContent/Sidebar/CustomTabButton
@onready var about_tab_button = $MainContent/Sidebar/AboutTabButton

# Ссылки на контейнеры самих вкладок
@onready var display_audio_tab = $MainContent/TabContents/DisplayAudioTab
@onready var personalization_tab = $MainContent/TabContents/PersonalizationTab
@onready var about_tab = $MainContent/TabContents/AboutTab

# Ссылки на ползунки настроек
@onready var volume_slider = $MainContent/TabContents/DisplayAudioTab/VolumeSlider
@onready var glitch_slider = $MainContent/TabContents/DisplayAudioTab/GlitchSlider

# Ссылка на шейдер экрана (чтобы менять помехи на лету)
# Если узел лежит в корне сцены OS, берем его через родителя
@onready var vhs_overlay = $"../../Retro_OS_Display"

func _ready():
	visible = false
	modulate.a = 0.0
	
	if close_button:
		close_button.pressed.connect(close_settings)
		
	if display_tab_button: display_tab_button.pressed.connect(func(): _show_tab("display"))
	if custom_tab_button: custom_tab_button.pressed.connect(func(): _show_tab("custom"))
	if about_tab_button: about_tab_button.pressed.connect(func(): _show_tab("about"))
	
	if volume_slider:
		volume_slider.value_changed.connect(_on_volume_changed)
	if glitch_slider:
		glitch_slider.value_changed.connect(_on_glitch_changed)
		
	_show_tab("display")

# Функция переключения вкладок внутри настроек
func _show_tab(tab_name: String):
	if display_audio_tab: display_audio_tab.visible = (tab_name == "display")
	if personalization_tab: personalization_tab.visible = (tab_name == "custom")
	if about_tab: about_tab.visible = (tab_name == "about")

# ИЗМЕНЕНИЕ ГРОМКОСТИ (Влияет на всю игру через Master шину)
func _on_volume_changed(value: float):
	var bus_index = AudioServer.get_bus_index("Master")
	if value > 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
		AudioServer.set_bus_mute(bus_index, false)
	else:
		AudioServer.set_bus_mute(bus_index, true)

# ИЗМЕНЕНИЕ ИНТЕНСИВНОСТИ ШЕЙДЕРА ЭКРАНА
func _on_glitch_changed(value: float):
	if vhs_overlay and vhs_overlay.material:
		vhs_overlay.material.set_shader_parameter("scanline_strength", value)

# --- ЛОГИКА ОКНА (Открытие / Закрытие) ---
func toggle_settings():
	if visible:
		close_settings()
	else:
		open_settings()

func open_settings():
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func close_settings():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
	await tween.finished
	visible = false
