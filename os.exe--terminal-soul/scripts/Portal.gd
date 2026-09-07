extends Area2D

signal player_entered_portal

var light: PointLight2D
var visual_shape: Node2D

func _ready():
	add_to_group("Portal")
	monitoring = true
	body_entered.connect(_on_body_entered)
	
	_setup_collision()
	_setup_visuals()
	_setup_light()

func _setup_collision():
	if not has_node("CollisionShape2D"):
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 20.0
		col.shape = shape
		add_child(col)

func _setup_visuals():
	visual_shape = Node2D.new()
	visual_shape.set_script(load("res://scripts/PortalDrawer.gd"))
	add_child(visual_shape)

func _setup_light():
	light = PointLight2D.new()
	light.energy = 1.2
	light.texture_scale = 2.5
	
	var light_tex = GradientTexture2D.new()
	light_tex.fill = GradientTexture2D.FILL_RADIAL
	light_tex.fill_from = Vector2(0.5, 0.5)
	light_tex.fill_to = Vector2(0.5, 0.0)
	light_tex.width = 128
	light_tex.height = 128
	
	var grad = Gradient.new()
	grad.set_color(0, Color(0.2, 0.9, 1.0, 1.0))
	grad.set_color(1, Color(0.0, 0.0, 0.0, 0.0))
	
	light_tex.gradient = grad
	light.texture = light_tex
	add_child(light)

func _on_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		player_entered_portal.emit()
