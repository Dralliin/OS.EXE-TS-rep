extends Node2D

var rotation_angle: float = 0.0

func _process(delta: float):
	rotation_angle += delta * 3.0
	queue_redraw()

func _draw():
	var radius = 18.0 + sin(rotation_angle * 2.0) * 2.0
	draw_circle(Vector2.ZERO, radius + 4.0, Color(0.1, 0.8, 1.0, 0.2))
	
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(0.2, 0.9, 1.0, 0.9), 3.0)
	draw_arc(Vector2.ZERO, radius * 0.6, 0, TAU, 24, Color(0.8, 0.95, 1.0, 0.8), 2.0)
	
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 1.0, 1.0, 0.9))
