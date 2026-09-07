extends Node2D

func _draw():
	var size = Vector2(52, 48)
	var half_size = size / 2.0
	
	draw_rect(Rect2(-half_size + Vector2(0, 4), size), Color(0, 0, 0, 0.4))

	var h = Vector2(0, -18)
	var base_rect = Rect2(-half_size, size)
	var top_rect = Rect2(-half_size + h, size)

	draw_rect(base_rect, Color(0.04, 0.08, 0.14))
	draw_rect(top_rect, Color(0.12, 0.22, 0.35))
	draw_rect(top_rect, Color(0.25, 0.5, 0.8), false, 1.5)
