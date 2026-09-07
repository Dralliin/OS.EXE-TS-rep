extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)
	_create_collision_if_missing()

func _draw():
	var shadow_points = PackedVector2Array()
	for i in range(12):
		var angle = i * PI * 2.0 / 12
		var pt = Vector2(0, 6) + Vector2(cos(angle) * 10, sin(angle) * 4)
		shadow_points.append(pt)
	draw_colored_polygon(shadow_points, Color(0, 0, 0, 0.3))
	
	var pos = Vector2(0, -10)
	var rect = Rect2(pos + Vector2(-8, -8), Vector2(16, 16))
	draw_rect(rect, Color(1.0, 0.7, 0.1))
	draw_rect(rect, Color(1.0, 0.9, 0.3), false, 2.0)

func _on_body_entered(body):
	if body.is_in_group("Player") or body.has_method("add_key"):
		body.add_key()
		queue_free()

func _create_collision_if_missing():
	if not has_node("CollisionShape2D"):
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 12.0
		col.shape = shape
		add_child(col)
