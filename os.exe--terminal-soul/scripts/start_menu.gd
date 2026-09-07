extends Panel

@onready var terminal_button = $HBoxContainer/Terminal
@onready var terminal_window = $"../TerminalWindow"

func _ready():
	if terminal_window:
		terminal_window.visible = false
	
	if terminal_button:
		terminal_button.pressed.connect(_on_terminal_pressed)

func _on_terminal_pressed():
	if terminal_window:
		terminal_window.open_terminal()
		
		# Опционально: закрываем само меню "Пуск" после нажатия
		# visible = false
