extends TextureButton

@onready var file_manager = $"../../../FileManagerWindow" 
@onready var folder_taskbar_button = $"."

func _ready():
	folder_taskbar_button.pressed.connect(_on_folder_button_pressed)

func _on_folder_button_pressed():
	if file_manager and file_manager.has_method("open_window"):
		file_manager.open_window()
		file_manager.move_to_front()
