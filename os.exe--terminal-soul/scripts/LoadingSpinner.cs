using Godot;
using System;
using System.Threading.Tasks;

public partial class LoadingSpinner : AnimatedSprite2D
{
    [Export] public Control ButtonsContainer; // Сюда перетащим контейнер с кнопками

    public override void _Ready()
    {
        Visible = false; // В начале он спит
    }

    // Этот метод мы будем вызывать из кнопки
    public async void StartLoading()
    {
        if (ButtonsContainer == null) return;

        ButtonsContainer.Visible = false;
        Visible = true;
        Play("rotate"); // Твоя анимация из 8 кадров

        await Task.Delay(2000);

        // Если меню всё еще открыто (проверим по родителю)
        if (GetParent<Control>().Visible)
        {
            Stop();
            Visible = false;
            ButtonsContainer.Visible = true;
        }
    }
}