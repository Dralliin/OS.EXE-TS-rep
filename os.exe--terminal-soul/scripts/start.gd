extends TextureButton

@onready var menu = %StartMenu

func _pressed():
	if menu:
		menu.visible = !menu.visible
		print("Меню переключено. Видимость: ", menu.visible)
	else:
		print("Ошибка: Кнопка не видит %StartMenu")
