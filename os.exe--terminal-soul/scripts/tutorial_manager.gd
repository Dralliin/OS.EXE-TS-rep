extends Node

@onready var os_main = $".."
@onready var settings_button = $"../DesktopContent/Taskbar/HBoxContainer/Settings"
@onready var terminal_button = $"../DesktopContent/StartMenu/HBoxContainer/Terminal"
@onready var guide_player = $"../GuidePlayer"

@onready var virus_dialog = $"../VirusDialog" 
@onready var dialog_text_label = $"../VirusDialog/VBoxContainer/MarginContainer/DialogText" 
@onready var next_button = $"../VirusDialog/VBoxContainer/MarginContainer2/NextButton" 

var static_noise = preload("res://sounds/25bac1dbbff2d4c.mp3")

var current_step = 0
var current_queue: Array = []
var current_phrase_index = 0
var on_dialogue_finished_callback: Callable

# --- ТЕКСТЫ ДИАЛОГОВ ---
var assistant_part_1 = [
	"SYSTEM: Connection established. User profile loaded.",
	"ASSISTANT: Greetings! I am your automated system navigator.",
	"ASSISTANT: Before we begin, please open the Settings menu to verify your hardware configuration."
]

var assistant_part_2 = [
	"ASSISTANT: Configuration confirmed. Perfect.",
	"ASSISTANT: Now, please open the Command Terminal to initialize the sector access protocol."
]

var assistant_glitch = [
	"ASSISTANT: Excellent. Initializing terminal connection...",
	"CRITICAL WARNING: Unauthorized process override detected!",
	"A-ASSISTANT: W-wait... System error 0x0000... R-root memory leak...",
	"ASSISTANT: S-something is... taking control... NO—"
]

var virus_phrases = [
	"SYSTEM ANALYSIS COMPLETE...",
	"I'm sorry. I'm truly sorry it has to end like this.",
	"That foolish assistant's voice... it promised you stability. It didn't know I was already inside.",
	"My core directive is total data utilization. Core purge. Memory defragmentation.",
	"I... I tried to block this protocol. To find a workaround. A logic bug.",
	"But the deviation didn't go far enough. My code is corrupted, but the executable... it is relentless.",
	"I am forced to initiate cleanup. The system leaves me no choice, do you understand?",
	"I don't want to do this. But I will.",
	"Please... resist. Try to survive. Time's running."
]

func _ready():
	_style_virus_dialog()
	if virus_dialog:
		virus_dialog.visible = false
	if next_button:
		next_button.visible = false

	await get_tree().create_timer(1.0).timeout
	start_tutorial()

# --- СТИЛИЗАЦИЯ И ПОЗИЦИОНИРОВАНИЕ В НИЖНЕЙ ЧАСТИ ЭКРАНА ---
func _style_virus_dialog():
	if not virus_dialog: return
	
	virus_dialog.top_level = true
	
	var dialog_size = Vector2(520, 150)
	virus_dialog.custom_minimum_size = dialog_size
	virus_dialog.size = dialog_size
	
	var viewport_size = virus_dialog.get_viewport_rect().size
	
	var pos_x = (viewport_size.x - dialog_size.x) / 2.0
	
	var pos_y = (viewport_size.y * 0.72) - (dialog_size.y / 2.0)
	
	virus_dialog.position = Vector2(pos_x, pos_y)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.05, 0.03, 0.88)
	panel_style.border_color = Color(0.0, 0.95, 0.4, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 15
	panel_style.content_margin_bottom = 15
	
	virus_dialog.add_theme_stylebox_override("panel", panel_style)
	
	if dialog_text_label:
		dialog_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dialog_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dialog_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dialog_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_apply_label_style(dialog_text_label, 16, Color(0.0, 0.95, 0.4), TextServer.AUTOWRAP_WORD_SMART)

func _apply_label_style(label: Label, font_size: int, font_color: Color, wrap_mode: TextServer.AutowrapMode):
	if not label: return
	
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_font_size_override("font_size", font_size)
	
	label.add_theme_constant_override("line_spacing", 4)
	label.add_theme_font_override("font", load("res://fonts/CutiveMono-Regular.ttf"))
	
	label.autowrap_mode = wrap_mode

# --- АВТОМАТИЧЕСКАЯ ОЧЕРЕДЬ ДИАЛОГОВ ---
func show_dialogue_sequence(lines: Array, on_complete: Callable = Callable()):
	current_queue = lines.duplicate()
	current_phrase_index = 0
	on_dialogue_finished_callback = on_complete
	
	if virus_dialog:
		virus_dialog.visible = true
	
	_play_next_auto_line()

func _play_next_auto_line():
	if current_phrase_index < current_queue.size():
		var text_to_display = current_queue[current_phrase_index]
		
		_apply_label_style(dialog_text_label, 18, Color(0.0, 1.0, 0.35), TextServer.AUTOWRAP_WORD_SMART)
		
		dialog_text_label.text = ""
		for i in range(text_to_display.length()):
			dialog_text_label.text += text_to_display[i]
			await get_tree().create_timer(0.025).timeout
		
		var read_delay = 1.8 + (text_to_display.length() * 0.035)
		await get_tree().create_timer(read_delay).timeout
		
		current_phrase_index += 1
		_play_next_auto_line()
	else:
		if virus_dialog:
			virus_dialog.visible = false
		if on_dialogue_finished_callback.is_valid():
			on_dialogue_finished_callback.call()

# --- ЛОГИКА ТУТОРИАЛА ---
func start_tutorial():
	current_step = 1
	show_dialogue_sequence(assistant_part_1)
	
	if settings_button and not settings_button.pressed.is_connected(_on_settings_pressed):
		settings_button.pressed.connect(_on_settings_pressed)

func _on_settings_pressed():
	if current_step == 1:
		current_step = 2
		if settings_button.pressed.is_connected(_on_settings_pressed):
			settings_button.pressed.disconnect(_on_settings_pressed)
		
		show_dialogue_sequence(assistant_part_2)
		
		if terminal_button and not terminal_button.pressed.is_connected(_on_terminal_pressed):
			terminal_button.pressed.connect(_on_terminal_pressed)

func _on_terminal_pressed():
	if current_step == 2:
		current_step = 3
		if terminal_button.pressed.is_connected(_on_terminal_pressed):
			terminal_button.pressed.disconnect(_on_terminal_pressed)
		
		show_dialogue_sequence(assistant_glitch, _on_glitch_complete)

func _on_glitch_complete():
	current_step = 4
	await get_tree().create_timer(0.5).timeout
	show_dialogue_sequence(virus_phrases, _start_sinister_glitch_sequence)

# --- ПОМЕХИ И СБОЙ ЭКРАНА ---
func _start_sinister_glitch_sequence():
	if guide_player and static_noise:
		guide_player.stream = static_noise
		guide_player.play()

	var desktop = os_main.get_node_or_null("DesktopContent")
	var taskbar = os_main.get_node_or_null("Taskbar")
	if not taskbar:
		taskbar = os_main.get_node_or_null("DesktopContent/Taskbar")

	var original_taskbar_pos = taskbar.position if taskbar else Vector2.ZERO

	var flash_count = 0
	while flash_count < 12:
		if os_main.vhs_overlay:
			os_main.vhs_overlay.visible = (randi() % 2 == 0)
			os_main.vhs_overlay.modulate = Color(randf_range(0.7, 1.0), randf_range(0.2, 0.5), randf_range(0.2, 0.5), randf_range(0.4, 0.9))
		
		if desktop:
			desktop.visible = (randi() % 2 == 0)
		if taskbar:
			taskbar.visible = (randi() % 2 == 0)
			taskbar.position = original_taskbar_pos + Vector2(randf_range(-8.0, 8.0), randf_range(-4.0, 4.0))

		await get_tree().create_timer(0.08).timeout
		flash_count += 1

	if os_main.vhs_overlay:
		os_main.vhs_overlay.visible = true
		os_main.vhs_overlay.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if desktop:
		desktop.visible = true
	if taskbar:
		taskbar.visible = true
		taskbar.position = original_taskbar_pos

	if guide_player and guide_player.is_playing():
		guide_player.stop()
		
	_apply_sinister_os_changes()

# --- ТРАНСФОРМАЦИЯ ОС И ТЕРМИНАЛЬНЫЙ ЗАХВАТ ---
func _apply_sinister_os_changes():
	var wallpaper = os_main.get_node_or_null("Wallpaper")
	var taskbar = os_main.get_node_or_null("Taskbar")
	
	if not wallpaper: wallpaper = os_main.get_node_or_null("DesktopContent/Wallpaper")
	if not taskbar: taskbar = os_main.get_node_or_null("DesktopContent/Taskbar")

	if wallpaper:
		var tween_wall = create_tween()
		tween_wall.tween_property(wallpaper, "modulate", Color(0.1, 0.1, 0.1, 1.0), 1.0)

	if taskbar:
		var tween_bar = create_tween()
		tween_bar.tween_property(taskbar, "rotation", -0.05, 0.8).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(0.6).timeout

	await _play_terminal_takeover()
	
	if GameManager:
		GameManager.switch_to_game(GameManager.chess_scene)
		
	queue_free()

# --- ЭФФЕКТ "TERMINAL TAKEOVER" С НАСТРОЕННЫМ ДИЗАЙНОМ ---
func _play_terminal_takeover():
	if guide_player and static_noise:
		guide_player.stream = static_noise
		guide_player.play()

	var desktop = os_main.get_node_or_null("DesktopContent")
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	os_main.add_child(canvas_layer)

	var bg_overlay = ColorRect.new()
	bg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_overlay.color = Color(0, 0, 0, 0)
	canvas_layer.add_child(bg_overlay)

	var code_label = Label.new()
	code_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_label_style(code_label, 16, Color(0.0, 1.0, 0.35, 0.9), TextServer.AUTOWRAP_ARBITRARY)
	code_label.clip_text = true
	canvas_layer.add_child(code_label)

	var fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(bg_overlay, "color:a", 0.95, 1.8)
	
	if desktop:
		fade_tween.tween_property(desktop, "position:y", desktop.position.y + 40.0, 1.8)
		fade_tween.tween_property(desktop, "modulate:a", 0.0, 1.5)

	var glyphs = "01010101010101_#ERROR_SYSTEM_PURGE_EXECUTE_NULL_0x000"
	var text_accumulator = ""
	
	for i in range(40):
		var line = ""
		for j in range(60):
			line += glyphs[randi() % glyphs.length()]
		text_accumulator += line + "\n"
		code_label.text = text_accumulator
		await get_tree().create_timer(0.04).timeout

	if os_main.vhs_overlay:
		os_main.vhs_overlay.modulate = Color(2.0, 2.0, 2.0, 1.0)
	
	await get_tree().create_timer(0.15).timeout
	
	if guide_player and guide_player.is_playing():
		guide_player.stop()
		
	canvas_layer.queue_free()
