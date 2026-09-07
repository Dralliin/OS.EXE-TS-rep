using Godot;
using System;

public partial class StartButton : TextureButton
{
    // Ссылка на меню (инкапсуляция: поле приватное)
    private Control _startMenu;

    public override void _Ready()
    {
        // 1. Ищем меню в дереве узлов.
        // Путь "../../StartMenu" означает:
        // Выйти из кнопки (..) -> Выйти из Taskbar (..) -> Найти StartMenu
        _startMenu = GetNodeOrNull<Control>("../../StartMenu");

        // Проверка на ошибку (защитное программирование)
        if (_startMenu == null)
        {
            GD.PrintErr("ОШИБКА: Не удалось найти StartMenu! Проверь путь в GetNode.");
            return;
        }

        // 2. Начальное состояние: меню скрыто
        _startMenu.Visible = false;

        // 3. Подписываемся на событие нажатия (Делегат в C#)
        this.Pressed += OnStartButtonPressed;
        
        GD.Print("Система: Кнопка Пуск инициализирована успешно.");
    }

    private void OnStartButtonPressed()
    {
        if (_startMenu != null)
        {
            // Инвертируем видимость (true становится false и наоборот)
            _startMenu.Visible = !_startMenu.Visible;

            if (_startMenu.Visible)
            {
                // Поднимаем меню на передний план
                _startMenu.MoveToFront();
                GD.Print("Система: Меню открыто.");
            }
        }
    }
}