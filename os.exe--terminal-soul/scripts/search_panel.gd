extends NinePatchRect

@onready var input_field = $SearchInput
@onready var enter_button = $EnterButton
@onready var os_main = get_parent()

func _ready():
	input_field.text_submitted.connect(_on_search_submitted)
	if enter_button:
		enter_button.pressed.connect(func(): _on_search_submitted(input_field.text))

func _on_search_submitted(query: String):
	query = query.to_lower().strip_edges()
	if query == "": return

	match query:
		"terminal", "терминал", "cmd":
			os_main.open_app("terminal")
			visible = false
		"exit", "выход":
			input_field.text = ""
			input_field.placeholder_text = "ВЫХОДА НЕТ"
		_:
			input_field.text = ""
			input_field.placeholder_text = "Не найдено..."
