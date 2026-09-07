extends Control

@onready var warning_text = $WarningText

const MAIN_MENU_PATH = "res://scenes/main_menu.tscn" 

func _ready():
	warning_text.text = "[center][color=red]WARNING / CONTENT ADVISORY[/color]\n\nThis game is a psychological thriller that contains flashing lights,\ndistorting visual effects, and themes of digital paranoia.\n\nIt may not be suitable for individuals with photosensitive epilepsy,\nheart conditions, or high anxiety.\n\n[color=gray]BOOTING SYSTEM_CORE_SOUL.EXE... Please wait.[/color][/center]"
	
	warning_text.visible_ratio = 0.0
	warning_text.modulate.a = 1.0 
	
	run_cinematic_warning()

func run_cinematic_warning():
	var tween = create_tween()
	
	tween.tween_property(warning_text, "visible_ratio", 1.0, 12.0)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_interval(1.0)
	
	tween.tween_property(warning_text, "modulate:a", 0.0, 2.0)
	
	tween.finished.connect(_on_warning_finished)

func _on_warning_finished():
	print("SYSTEM_LOG: Warning finished. Initializing Main Menu transition...")
	
	if ResourceLoader.exists(MAIN_MENU_PATH):
		get_tree().change_scene_to_file(MAIN_MENU_PATH)
	else:
		print("SYSTEM_LOG: Main Menu scene not found yet! Animation sequence works perfectly.")
