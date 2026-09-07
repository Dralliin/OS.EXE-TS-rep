extends Node2D

@onready var terminal_window = $DesktopContent/TerminalWindow
@onready var search_panel = $DesktopContent/SearchPanel
@onready var settings_window = $DesktopContent/SettingsWindow

@onready var search_button = $DesktopContent/Taskbar/HBoxContainer/Search
@onready var terminal_task_button = $DesktopContent/Taskbar/HBoxContainer/TerminalTaskButton
@onready var settings_button = $DesktopContent/Taskbar/HBoxContainer/Settings

@onready var vhs_overlay = $Retro_OS_Display

func _ready():
	if terminal_window: terminal_window.visible = false
	if search_panel: 
		search_panel.visible = false
		search_panel.z_index = 10
	
	if terminal_task_button: terminal_task_button.visible = false
	
	if search_button:
		search_button.pressed.connect(_on_search_pressed)
	
	if terminal_task_button:
		terminal_task_button.pressed.connect(_on_terminal_task_pressed)
		
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)

	# --- АНИМАЦИЯ ВКЛЮЧЕНИЯ МОНИТОРА ---
	if vhs_overlay and vhs_overlay.material:
		vhs_overlay.material.set_shader_parameter("switch_on_pct", 0.0)
		
		await get_tree().create_timer(0.15).timeout
		
		var tween = create_tween()
		tween.tween_property(vhs_overlay.material, "shader_parameter/switch_on_pct", 1.0, 0.35)\
			.from(0.0)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)

# Логика для кнопки Поиска
func _on_search_pressed():
	if search_panel:
		search_panel.visible = !search_panel.visible
		if search_panel.visible:
			var input = search_panel.get_node_or_null("HBoxContainer/SearchInput")
			if input:
				input.grab_focus()
				input.text = ""

# Логика кнопки Терминала на панели задач
func _on_terminal_task_pressed():
	if terminal_window:
		terminal_window.toggle_terminal()

# Логика кнопки Настроек в панели задач
func _on_settings_pressed():
	if settings_window:
		settings_window.toggle_settings()

func open_app(app_name: String):
	match app_name:
		"terminal":
			if terminal_window: terminal_window.open_terminal()
		"settings":
			if settings_window: settings_window.open_settings()
