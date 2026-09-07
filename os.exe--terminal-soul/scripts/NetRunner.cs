using Godot;
using System;

public partial class NetRunner : Button
{
    [Export] public bool IsBlockedByVirus = true;
    
    // Ссылка на наше окно ошибки
    private ErrorWindow _errorWindow;

    public override void _Ready()
    {
        // Пытаемся найти ErrorWindow. 
        // Если он лежит в корне сцены, а кнопка внутри пуска, попробуй этот путь:
        _errorWindow = GetNodeOrNull<ErrorWindow>("/root/OS/ErrorWindow"); 

        // Если не нашел по абсолютному пути, попробуем относительный
        if (_errorWindow == null)
        {
            _errorWindow = GetNodeOrNull<ErrorWindow>("../../../ErrorWindow");
        }

        this.Pressed += OnNetRunnerPressed;
    }

    private void OnNetRunnerPressed()
    {
        // ПРОВЕРКА НА NULL (чтобы не было ошибки в 34 строке)
        if (_errorWindow != null)
        {
            if (IsBlockedByVirus)
            {
                _errorWindow.ShowMessage("КРИТИЧЕСКАЯ ОШИБКА:\n\nДоступ заблокирован вирусом 'Terminal Soul'.\nВмешательство в систему NetRunner невозможно.");
                GD.Print("Система: Вирус отклонил запрос.");
            }
        }
        else
        {
            // Если мы здесь, значит GetNode не сработал
            GD.PrintErr("ОШИБКА: Скрипт не видит ErrorWindow. Проверь название узла в дереве сцены!");
        }
    }
}