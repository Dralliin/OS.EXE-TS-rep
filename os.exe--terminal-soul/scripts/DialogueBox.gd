extends CanvasLayer

signal dialogue_finished

var dialog_box: PanelContainer
var label: Label
var current_text: String = ""
var text_speed: float = 0.03  # Скорость печати
var is_typing: bool = false
var dialogue_queue: Array = []

func _ready():
	_create_dialogue_ui()
	hide_dialogue()

func _input(event):
	if dialog_box and dialog_box.visible and (event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)):
		get_viewport().set_input_as_handled()
		if is_typing:
			is_typing = false
			label.text = current_text
		else:
			_show_next_line()

func _create_dialogue_ui():
	layer = 100

	dialog_box = PanelContainer.new()
	dialog_box.name = "DialoguePanel"
	dialog_box.mouse_filter = Control.MOUSE_FILTER_PASS 
	add_child(dialog_box)

	dialog_box.anchor_left = 0.5
	dialog_box.anchor_top = 1.0
	dialog_box.anchor_right = 0.5
	dialog_box.anchor_bottom = 1.0
	
	dialog_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dialog_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dialog_box.position = Vector2(-325, -120)

	dialog_box.custom_minimum_size = Vector2(650, 90)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.04, 0.06, 0.95)
	style.border_color = Color(0.2, 1.0, 0.4, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	
	style.content_margin_left = 18
	style.content_margin_top = 14
	style.content_margin_right = 18
	style.content_margin_bottom = 14
	
	dialog_box.add_theme_stylebox_override("panel", style)

	label = Label.new()
	label.name = "DialogueText"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var font_path = "res://fonts/PixelFont.ttf"
	if ResourceLoader.exists(font_path):
		label.add_theme_font_override("font", load(font_path))

	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.2, 0.0, 0.8))
	label.add_theme_constant_override("outline_size", 2)
	
	dialog_box.add_child(label)

func start_dialogue(lines: Array):
	dialogue_queue = lines.duplicate()
	if dialog_box:
		dialog_box.visible = true
	_show_next_line()

func _show_next_line():
	if dialogue_queue.size() > 0:
		current_text = dialogue_queue.pop_front()
		_type_text(current_text)
	else:
		hide_dialogue()
		dialogue_finished.emit()

func _type_text(target_text: String):
	is_typing = true
	label.text = ""
	for i in range(target_text.length()):
		if not is_typing:
			break
		label.text += target_text[i]
		await get_tree().create_timer(text_speed).timeout
	label.text = target_text
	is_typing = false

func hide_dialogue():
	if dialog_box:
		dialog_box.visible = false
	is_typing = false

func is_dialogue_active() -> bool:
	return dialog_box != null and dialog_box.visible
