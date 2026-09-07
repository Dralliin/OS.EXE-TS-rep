extends Control

@onready var logo_text = $LogoText
@onready var terminal_text = $TerminalText
@onready var menu_buttons = $MenuButtons
@onready var boot_button = $MenuButtons/BootButton
@onready var shutdown_button = $MenuButtons/ShutdownButton
@onready var vhs_overlay = $VHS_Overlay       
@onready var shutdown_sound = $ShutdownSound 
@onready var menu_music = $MenuMusic         

var final_text: String = ""
var bios_static_text: String = ""
var cursor_visible: bool = true
var animation_style_active: bool = true
var background_loop_active: bool = false

var game_logo: String = "[center][color=red][pulse freq=2.0 color=#ffffff22][tornado radius=3.0 speed=5.0]OS.EXE: TERMINAL SOUL[/tornado][/pulse][/color][/center]"

var background_logs: Array[String] = [
	"SYS_MONITOR: Core temperature nominal... 37C",
	"MEM_CHECK: Flushing temporary buffer sectors... OK",
	"NETWORK: Protocol 0xFA binding active.",
	"SOUL_NET: Searching for outbound signals... [NONE]",
	"WARNING: Micro-fluctuations detected in sector 0x09.",
	"LOG: Background process [PID 066] is idling...",
	"SYS_LOG: Dynamic memory allocation... STABLE",
	"SOUL_NET: Ping to HOST_UNKNOWN... [TIMEOUT]",
	"VRAM: Integrity scan completed with 0 minor faults."
]

const MAIN_OS_SCENE_PATH = "res://scenes/loading_screen.tscn" 

func _ready():
	menu_buttons.visible = false
	menu_buttons.modulate.a = 0.0
	terminal_text.text = ""
	logo_text.text = ""
	
	if menu_music:
		menu_music.stop()
	
	if vhs_overlay and vhs_overlay.material:
		vhs_overlay.material.set_shader_parameter("switch_on_pct", 0.0)
	
	await get_tree().process_frame
	
	terminal_text.pivot_offset = terminal_text.size / 2
	logo_text.pivot_offset = logo_text.size / 2
	
	setup_retro_buttons()
	
	boot_button.pressed.connect(_on_boot_pressed)
	shutdown_button.pressed.connect(_on_shutdown_pressed)
	
	await get_tree().create_timer(1.5).timeout
	
	if menu_music:
		menu_music.play()
		
	animate_screen_power_on()

# --- СТИЛИЗАЦИЯ КНОПОК ПОД DOS ---
func setup_retro_buttons():
	var buttons = [boot_button, shutdown_button]
	for btn in buttons:
		btn.focus_mode = Control.FOCUS_NONE
		var empty_style = StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal", empty_style)
		btn.add_theme_stylebox_override("hover", empty_style)
		btn.add_theme_stylebox_override("pressed", empty_style)
		btn.add_theme_stylebox_override("focus", empty_style)
		btn.add_theme_stylebox_override("disabled", empty_style)
		
		btn.add_theme_color_override("font_color", Color("b0b0b0"))
		btn.add_theme_color_override("font_hover_color", Color("ff3333")) 
		btn.add_theme_color_override("font_pressed_color", Color("ff3333"))
		btn.add_theme_color_override("font_focus_color", Color("ff3333"))
		btn.add_theme_color_override("font_disabled_color", Color("ff3333"))
	
	boot_button.text = "  BOOT OS.EXE"
	shutdown_button.text = "  SHUTDOWN"
	
	boot_button.mouse_entered.connect(func(): boot_button.text = "> BOOT OS.EXE")
	boot_button.mouse_exited.connect(func(): boot_button.text = "  BOOT OS.EXE")
	shutdown_button.mouse_entered.connect(func(): shutdown_button.text = "> SHUTDOWN")
	shutdown_button.mouse_exited.connect(func(): shutdown_button.text = "  SHUTDOWN")

# --- РЕАЛИСТИЧНОЕ ВКЛЮЧЕНИЕ МОНИТОРА ---
func animate_screen_power_on():
	if vhs_overlay and vhs_overlay.material:
		var tween = create_tween()
		tween.tween_property(vhs_overlay.material, "shader_parameter/switch_on_pct", 1.0, 0.35)\
			.from(0.0)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
			
		await tween.finished
	
	await get_tree().create_timer(0.2).timeout
	start_cursor_blink()
	run_bios_boot()

# --- ЛОГИКА АНИМАЦИИ BIOS ---
func run_bios_boot():
	var real_cpu_name: String = OS.get_processor_name()
	
	add_log_line("BIOS Version 1.04.26 (C) 1994 CoreCorp")
	add_log_line("CPU: " + real_cpu_name + " emulation mode... OK")
	add_log_line("RAM: 16384KB EXTENDED... OK")
	await get_tree().create_timer(0.4).timeout
	
	add_log_line("DRIVE C: READY | DRIVE D: READY | DRIVE Z: [color=red]FAILED[/color]")
	await get_tree().create_timer(0.6).timeout
	
	add_log_line("\nCRITICAL ERROR: ALTERNATIVE_CORE_DETECTED.")
	add_log_line("UNAUTHORIZED ACCESS IN SECTOR 0x0F...")
	await get_tree().create_timer(0.8).timeout
	
	logo_text.text = game_logo
	trigger_screen_glitch_shake()
	await get_tree().create_timer(1.0).timeout
	
	add_log_line("\nRUN SYSTEM INFUSION PROCESS? (Y/N)")
	add_log_line("Select option below:\n")
	
	bios_static_text = final_text
	show_menu()
	
	background_loop_active = true
	run_background_logger()

# --- БЕСКОНЕЧНЫЙ ФОНОВЫЙ ЛОГГЕР БЕЗ СКРОЛЛА ---
func run_background_logger():
	while background_loop_active and animation_style_active:
		await get_tree().create_timer(randf_range(1.5, 3.5)).timeout
		if not background_loop_active or not animation_style_active:
			break
			
		var random_log = background_logs[randi() % background_logs.size()]
		final_text = bios_static_text + "STATUS: " + random_log
		terminal_text.text = final_text

func add_log_line(new_line: String):
	final_text += new_line + "\n"
	terminal_text.text = final_text

func trigger_screen_glitch_shake():
	var shake = create_tween()
	shake.tween_property(self, "position", Vector2(10, -5), 0.04)
	shake.tween_property(self, "position", Vector2(-8, 5), 0.04)
	shake.tween_property(self, "position", Vector2.ZERO, 0.04)

func start_cursor_blink():
	while animation_style_active:
		cursor_visible = !cursor_visible
		if cursor_visible:
			terminal_text.text = final_text + " _"
		else:
			terminal_text.text = final_text
		await get_tree().create_timer(0.4).timeout

func show_menu():
	menu_buttons.visible = true
	var tween = create_tween()
	tween.tween_property(menu_buttons, "modulate:a", 1.0, 0.5)

# --- НАЖАТИЕ КНОПКИ BOOT (ПЕРЕХОД) ---
func _on_boot_pressed():
	animation_style_active = false
	background_loop_active = false
	boot_button.disabled = true
	shutdown_button.disabled = true
	
	# МГНОВЕННО И ОТРЕЗАННО ВЫКЛЮЧАЕМ МУЗЫКУ МЕНЮ
	if menu_music:
		menu_music.stop()
		
	if shutdown_sound:
		shutdown_sound.play()
	
	var tw = create_tween()
	tw.tween_property(menu_buttons, "modulate:a", 0.0, 0.1)
	
	add_log_line("\n[color=red]BOOTING_TERMINAL_SOUL... GOOD LUCK.[/color]")
	
	await get_tree().create_timer(0.2).timeout
	
	var collapse_tw = create_tween().set_parallel(true)
	collapse_tw.tween_property(terminal_text, "scale:y", 0.0, 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	collapse_tw.tween_property(terminal_text, "modulate:a", 0.0, 0.15)
	collapse_tw.tween_property(logo_text, "scale:y", 0.0, 0.25).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	collapse_tw.tween_property(logo_text, "modulate:a", 0.0, 0.15)
	
	if vhs_overlay and vhs_overlay.material:
		collapse_tw.tween_property(vhs_overlay.material, "shader_parameter/switch_on_pct", 0.0, 0.3)\
			.set_trans(Tween.TRANS_QUART)\
			.set_ease(Tween.EASE_IN)
	
	await collapse_tw.finished
	await get_tree().create_timer(0.5).timeout 
	
	if ResourceLoader.exists(MAIN_OS_SCENE_PATH):
		get_tree().change_scene_to_file(MAIN_OS_SCENE_PATH)
	else:
		terminal_text.scale.y = 1.0
		terminal_text.modulate.a = 1.0
		logo_text.scale.y = 1.0
		logo_text.modulate.a = 1.0
		menu_buttons.modulate.a = 1.0
		if vhs_overlay and vhs_overlay.material:
			vhs_overlay.material.set_shader_parameter("switch_on_pct", 1.0)
		if menu_music:
			menu_music.play()
		boot_button.disabled = false
		shutdown_button.disabled = false
		animation_style_active = true
		start_cursor_blink()

func _on_shutdown_pressed():
	get_tree().quit()
