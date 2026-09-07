using Godot;
using System;

public partial class ErrorWindow : Panel
{
    private Label _errorLabel;
    private Button _closeButton;

    public override void _Ready()
    {
        // Ищем узлы внутри окна. Убедись, что имена в Godot совпадают!
        _errorLabel = GetNode<Label>("ErrorText");
        _closeButton = GetNode<Button>("CloseButton");

        // Скрываем окно при нажатии на кнопку закрытия
        _closeButton.Pressed += () => this.Visible = false;

        // Изначально окно невидимо
        this.Visible = false;
    }

    // Этот метод мы будем вызывать из скрипта терминала
    public void ShowMessage(string text)
    {
        _errorLabel.Text = text;
        this.Visible = true;
        this.MoveToFront(); // Выводим на передний план
    }
}