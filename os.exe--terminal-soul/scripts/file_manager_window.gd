extends Panel

# --- UI NODES ---
@onready var sidebar = $Content/Sidebar
@onready var file_area = $Content/FileArea
@onready var close_button = $Header/CloseButton
@onready var os_main = get_parent()

# --- WINDOW LOGIC ---
var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var current_location: String = "Desktop"

# --- PRELOAD ICONS ---
@onready var icon_folder = preload("res://icons/folder.png")
@onready var icon_txt = preload("res://icons/file_txt.png")
@onready var icon_exe = preload("res://icons/file_exe.png")
@onready var icon_sys = preload("res://icons/file_sys.png")

# --- VIRTUAL FILE SYSTEM ---
var locations = {
	"Desktop": [
		{"name": "readme_first.txt", "type": "text"},
		{"name": "system_diagnostic.exe", "type": "exe"},
		{"name": "dev_note_04.txt", "type": "text"}
	],
	"System (C:)": [
		{"name": "Drivers", "type": "folder"},
		{"name": "Core_Files", "type": "folder"},
		{"name": "manifest.sys", "type": "sys"},
		{"name": "crash_dump_3AM.log", "type": "text"}
	],
	"Storage (D:)": [
		{"name": "Recovery_Data", "type": "folder"},
		{"name": "fragment_04.png", "type": "sys"},
		{"name": "unlinked_sector.bin", "type": "sys"}
	],
	"UNKNOWN (Z:)": [
		{"name": "void.exe", "type": "exe"},
		{"name": "NULL_DIRECTORY", "type": "folder"},
		{"name": "DO_NOT_OPEN.txt", "type": "text"}
	],
	"Trash": [
		{"name": "logic_backup.old", "type": "sys"},
		{"name": "empty_promise.txt", "type": "text"}
	]
}

func _ready():
	visible = false
	modulate.a = 0.0
	scale = Vector2.ZERO
	pivot_offset = size / 2
	
	close_button.pressed.connect(_on_close_pressed)
	sidebar.item_selected.connect(_on_sidebar_selected)
	file_area.item_activated.connect(_on_file_double_clicked)
	
	setup_explorer()
	
	# --- ТЕСТОВЫЙ ТАЙМЕР ДЛЯ ОДИНОЧНОЙ СЦЕНЫ ---
	if get_tree().current_scene == self:
		var timer = get_tree().create_timer(1.0)
		timer.timeout.connect(open_window)

func setup_explorer():
	sidebar.clear()
	sidebar.add_item("Desktop")
	sidebar.add_item("System (C:)")
	sidebar.add_item("Storage (D:)")
	sidebar.add_item("UNKNOWN (Z:)")
	sidebar.add_item("Trash")
	
	load_folder("Desktop")

# --- ЛОГИКА ОТРИСОВКИ ИКОНОК ---
func load_folder(folder_name: String):
	current_location = folder_name
	file_area.clear()
	
	if locations.has(folder_name):
		for item in locations[folder_name]:
			var chosen_icon = icon_sys
			
			match item["type"]:
				"folder":
					chosen_icon = icon_folder
				"text":
					chosen_icon = icon_txt
				"exe":
					chosen_icon = icon_exe
				"sys":
					chosen_icon = icon_sys
			
			file_area.add_item(item["name"], chosen_icon)

# --- SIGNALS & INTERACTION ---
func _on_sidebar_selected(index: int):
	var folder = sidebar.get_item_text(index)
	load_folder(folder)

func _on_file_double_clicked(index: int):
	var file_name = file_area.get_item_text(index)
	
	if file_name == "void.exe" or file_name == "system_diagnostic.exe":
		print("CRITICAL: Attempting to access OS_CORE...")
		if os_main and os_main.has_method("open_app"):
			os_main.open_app("terminal")
	
	elif current_location == "UNKNOWN (Z:)":
		var shake = create_tween()
		shake.tween_property(self, "position", position + Vector2(8, 0), 0.05)
		shake.tween_property(self, "position", position - Vector2(8, 0), 0.05)
		shake.set_loops(4)
		print("SYSTEM_ERROR: Resource unlinked from this reality.")
	else:
		print("LOG: User tried to open " + file_name)

# --- WINDOW ANIMATIONS & DRAG ---
func open_window():
	if visible and modulate.a > 0.5: return
	visible = true
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.2)

func _on_close_pressed():
	dragging = false
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.0, 0.2)
	await tw.finished
	visible = false

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if close_button.get_global_rect().has_point(event.global_position): return
				if get_global_rect().has_point(event.global_position):
					dragging = true
					drag_offset = event.global_position - global_position
					move_to_front()
			else:
				dragging = false
				
	if event is InputEventMouseMotion and dragging:
		global_position = event.global_position - drag_offset
