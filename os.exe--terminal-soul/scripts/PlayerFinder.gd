extends CharacterBody2D

signal key_collected_signal(count: int)

@export var speed: float = 180.0

var collected_keys: int = 0
var flashlight: PointLight2D
var camera: Camera2D
var facing_direction: Vector2 = Vector2.DOWN

func _ready():
	add_to_group("Player")
	z_index = 10
	_setup_collision()
	_setup_flashlight()
	_setup_camera()

func _setup_collision():
	if not has_node("CollisionShape2D"):
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 12.0
		col.shape = shape
		add_child(col)

func _setup_flashlight():
	flashlight = PointLight2D.new()
	flashlight.name = "Flashlight"
	flashlight.energy = 1.3
	flashlight.texture_scale = 3.0
	
	var light_tex = GradientTexture2D.new()
	light_tex.fill = GradientTexture2D.FILL_RADIAL
	light_tex.fill_from = Vector2(0.5, 0.5)
	light_tex.fill_to = Vector2(0.5, 0.0)
	light_tex.width = 128
	light_tex.height = 128
	
	var grad = Gradient.new()
	grad.set_color(0, Color(1.0, 0.95, 0.85, 1.0))
	grad.set_color(1, Color(0.0, 0.0, 0.0, 0.0))
	
	light_tex.gradient = grad
	flashlight.texture = light_tex
	add_child(flashlight)

# Динамическая камера слежения за игроком
func _setup_camera():
	camera = Camera2D.new()
	camera.name = "PlayerCamera"
	camera.enabled = true
	camera.zoom = Vector2(2.0, 2.0) # Зум для локального обзора
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	add_child(camera)

func _draw():
	var center = Vector2.ZERO
	draw_circle(center + Vector2(0, 3), 13.0, Color(0, 0, 0, 0.3))
	var body_rect = Rect2(-11, -11, 22, 22)
	draw_rect(body_rect, Color(0.15, 0.8, 0.4, 1.0))
	draw_rect(body_rect, Color(0.4, 1.0, 0.6, 1.0), false, 2.0)
	var eye_offset = facing_direction * 6.0
	draw_circle(center + eye_offset, 3.5, Color(1.0, 1.0, 1.0, 0.9))

func _physics_process(_delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		facing_direction = direction.normalized()
		queue_redraw()

	velocity = direction * speed
	move_and_slide()

	if flashlight and facing_direction != Vector2.ZERO:
		flashlight.position = facing_direction * 8.0

func add_key():
	collected_keys += 1
	key_collected_signal.emit(collected_keys)
