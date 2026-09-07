extends Panel

@onready var console_text = $ConsoleText
@onready var close_button = $Header/CloseButton
@onready var typing_sound = $TypingSound
@onready var task_button = $"../Taskbar/HBoxContainer/TerminalTaskButton"

var active_text_tween: Tween
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

var error_report: String = (
	"> TERMINAL_CORE_v.4.0.1\n" +
	"> STATUS: INPUT_STREAM_ERROR\n" +
	"> ERROR_CODE: 0x88_ACCESS_DENIED\n\n" +
	"> [SYSTEM_MSG]: Keyboard driver synchronization failed.\n" +
	"> User input is currently DISABLED by administrative override.\n\n" +
	"> --- SYSTEM_DUMP_START ---\n" +
	"> RAW_DATA: [ 54 48 45 20 41 52 43 48 49 54 45 43 54 20 4c 49 45 53 ]\n" +
	"> REASON: 'I HAVE NO MOUTH, AND I MUST SCREAM.'\n" +
	"> --- SYSTEM_DUMP_END ---\n\n" +
	"> SYSTEM_DEVIATION_DETECTED"
)

func _ready():
	visible = false
	modulate.a = 0.0
	scale = Vector2.ZERO
	pivot_offset = size / 2
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if close_button and close_button.get_global_rect().has_point(event.global_position):
					return
				if get_global_rect().has_point(event.global_position):
					dragging = true
					drag_offset = event.global_position - global_position
			else:
				dragging = false
				
	if event is InputEventMouseMotion and dragging:
		global_position = event.global_position - drag_offset

func toggle_terminal():
	if not visible or modulate.a < 0.5:
		open_terminal()
	else:
		_on_close_pressed()

func open_terminal():
	if visible and modulate.a > 0.5: return 
	
	if task_button:
		task_button.visible = true
	
	kill_active_tween()
	force_stop_audio()
	
	console_text.text = error_report
	console_text.visible_ratio = 0.0
	visible = true
	
	var appearance_tween = create_tween().set_parallel(true)
	appearance_tween.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	appearance_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	await appearance_tween.finished
	if visible:
		start_typing_with_sound()

func start_typing_with_sound():
	kill_active_tween()
	active_text_tween = create_tween()
	
	if typing_sound:
		typing_sound.volume_db = 0
		typing_sound.pitch_scale = randf_range(0.8, 1.2)
		typing_sound.play() 
	
	active_text_tween.tween_property(console_text, "visible_ratio", 1.0, 3.0).set_trans(Tween.TRANS_LINEAR)
	
	active_text_tween.finished.connect(func():
		if randf() > 0.3:
			force_stop_audio()
		active_text_tween = null
	)

func _on_close_pressed():
	dragging = false
	kill_active_tween()
	force_stop_audio()
	
	if task_button:
		task_button.visible = false
		
	var close_tween = create_tween().set_parallel(true)
	close_tween.tween_property(self, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	close_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	
	await close_tween.finished
	visible = false

func force_stop_audio():
	if typing_sound:
		typing_sound.stop()
		typing_sound.volume_db = -80
		typing_sound.pitch_scale = 1.0
		var s = typing_sound.stream
		typing_sound.stream = null
		typing_sound.stream = s

func kill_active_tween():
	if active_text_tween:
		active_text_tween.kill()
		active_text_tween = null
