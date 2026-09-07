extends Node2D

var world_container: Node2D
var player: CharacterBody2D
var phantoms: Array[CharacterBody2D] = []
var collectibles: Node2D
var hud_label: Label
var threat_music_player: AudioStreamPlayer
var exit_portal: Area2D

# --- Переменные для шейдера и синхронизированной угрозы ---
@onready var glitch_overlay: ColorRect = get_node_or_null("GlitchOverlay")
@export var threat_detection_radius: float = 200.0

# --- Размеры и параметры сетки ---
@export var cell_size: Vector2 = Vector2(52, 48)

# --- Настройки аудио ---
@export var level_bgm_path: String = "res://sounds/GHOST.mp3"
@export var level_bgm_volume_db: float = -6.0

@export var threat_audio_path: String = "res://sounds/nicos nextbots bonus track - chase.mp3"
@export var max_threat_volume_db: float = -12.0

# --- Настройки уровня (динамически изменяются) ---
var grid_width: int = 19
var grid_height: int = 11
var wall_removal_chance: float = 0.3
var num_rooms: int = 3
var lamp_spawn_chance: float = 0.05

var total_keys_needed: int = 3
var phantoms_count: int = 1
var phantom_speed_multiplier: float = 1.0

var maze_grid = []
var astar_grid: AStarGrid2D = AStarGrid2D.new()

func _ready():
	_apply_level_difficulty()
	_bind_nodes()

	if world_container:
		world_container.scale = Vector2(1.0, 1.0)

	_setup_background_music()
	_generate_building_layout()
	_setup_astar_navigation()
	_build_maze_from_grid()
	_setup_hud()
	_setup_threat_music()
	
	# Тёмный фильтр
	var canvas_modulate = CanvasModulate.new()
	canvas_modulate.name = "DarknessOverlay"
	canvas_modulate.color = Color(0.03, 0.04, 0.08, 1.0)
	add_child(canvas_modulate)

	_connect_player_signal()

func _process(delta: float):
	_update_threat_effects(delta)

# --- ФОНОВЫЙ САУНДТРЕК УРОВНЯ (ЧЕРЕЗ GAMEMANAGER) ---
func _setup_background_music():
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("play_maze_music"):
		gm.play_maze_music(level_bgm_path, level_bgm_volume_db)

# --- ЕДИНАЯ СИНХРОНИЗИРОВАННАЯ ЛОГИКА ЭФФЕКТОВ УГРОЗЫ (ШЕЙДЕР + МУЗЫКА) ---
func _update_threat_effects(delta: float):
	if not player or phantoms.size() == 0:
		_apply_threat_intensity(0.0, delta)
		return

	var min_distance = 99999.0
	for p in phantoms:
		if is_instance_valid(p):
			var dist = player.global_position.distance_to(p.global_position)
			if dist < min_distance:
				min_distance = dist

	var intensity = 0.0
	if min_distance < threat_detection_radius:
		var factor = 1.0 - (min_distance / threat_detection_radius)
		intensity = clamp(factor, 0.0, 1.0)

	_apply_threat_intensity(intensity, delta)

func _apply_threat_intensity(intensity: float, delta: float):
	if glitch_overlay and glitch_overlay.material:
		var mat = glitch_overlay.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("static_intensity", intensity)
			mat.set_shader_parameter("chromatic_aberration", intensity * 0.035)

	if threat_music_player and threat_music_player.stream:
		if intensity > 0.0:
			var target_db = lerp(-40.0, max_threat_volume_db, intensity)
			threat_music_player.volume_db = move_toward(threat_music_player.volume_db, target_db, delta * 35.0)
		else:
			threat_music_player.volume_db = move_toward(threat_music_player.volume_db, -80.0, delta * 25.0)

# --- ЧТЕНИЕ УРОВНЯ ИЗ GAMEMANAGER ---
func _get_current_level_number() -> int:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		if "current_level" in gm:
			return gm.current_level
		elif "level" in gm:
			return gm.level
		elif gm.has_method("get_current_level"):
			return gm.get_current_level()
	return 1

# --- НАСТРОЙКА 10 УРОВНЕЙ СЛОЖНОСТИ ---
func _apply_level_difficulty():
	var level = _get_current_level_number()

	match level:
		1:
			grid_width = 19; grid_height = 11
			total_keys_needed = 3; phantoms_count = 1
			lamp_spawn_chance = 0.06; phantom_speed_multiplier = 0.85
		2:
			grid_width = 21; grid_height = 13
			total_keys_needed = 3; phantoms_count = 1
			lamp_spawn_chance = 0.05; phantom_speed_multiplier = 0.95
		3:
			grid_width = 23; grid_height = 13
			total_keys_needed = 4; phantoms_count = 1
			lamp_spawn_chance = 0.04; phantom_speed_multiplier = 1.0
		4:
			grid_width = 25; grid_height = 15
			total_keys_needed = 4; phantoms_count = 2
			lamp_spawn_chance = 0.04; phantom_speed_multiplier = 1.05
		5:
			grid_width = 27; grid_height = 15
			total_keys_needed = 5; phantoms_count = 2
			lamp_spawn_chance = 0.03; phantom_speed_multiplier = 1.1
		6:
			grid_width = 29; grid_height = 17
			total_keys_needed = 5; phantoms_count = 2
			lamp_spawn_chance = 0.03; phantom_speed_multiplier = 1.15
		7:
			grid_width = 31; grid_height = 17
			total_keys_needed = 6; phantoms_count = 2
			lamp_spawn_chance = 0.02; phantom_speed_multiplier = 1.2
		8:
			grid_width = 33; grid_height = 19
			total_keys_needed = 6; phantoms_count = 3
			lamp_spawn_chance = 0.02; phantom_speed_multiplier = 1.25
		9:
			grid_width = 35; grid_height = 19
			total_keys_needed = 7; phantoms_count = 3
			lamp_spawn_chance = 0.01; phantom_speed_multiplier = 1.3
		10, _:
			grid_width = 39; grid_height = 21
			total_keys_needed = 8; phantoms_count = 3
			lamp_spawn_chance = 0.005; phantom_speed_multiplier = 1.4

func _bind_nodes():
	if not glitch_overlay:
		glitch_overlay = get_node_or_null("GlitchLayer/GlitchOverlay") as ColorRect
		if not glitch_overlay:
			glitch_overlay = get_node_or_null("GlitchOverlay") as ColorRect

	world_container = get_node_or_null("WorldContainer") as Node2D
	if world_container:
		player = world_container.get_node_or_null("Player") as CharacterBody2D
		collectibles = world_container.get_node_or_null("Collectibles") as Node2D

	hud_label = get_node_or_null("HUD/StatusLabel") as Label

func _connect_player_signal():
	if not player:
		player = get_tree().get_first_node_in_group("Player") as CharacterBody2D

	if player and player.has_signal("key_collected_signal"):
		if player.key_collected_signal.is_connected(_on_player_collected_key):
			player.key_collected_signal.disconnect(_on_player_collected_key)
		player.key_collected_signal.connect(_on_player_collected_key)

# --- МУЗЫКА ТРЕВОГИ ---
func _setup_threat_music():
	threat_music_player = AudioStreamPlayer.new()
	threat_music_player.name = "ThreatMusic"
	add_child(threat_music_player)
	
	if ResourceLoader.exists(threat_audio_path):
		var stream = load(threat_audio_path)
		if stream:
			if "loop" in stream: stream.loop = true
			elif stream is AudioStreamWAV: stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

			threat_music_player.stream = stream
			threat_music_player.volume_db = -80.0
			threat_music_player.play()
			threat_music_player.finished.connect(func(): threat_music_player.play())

# --- ГЕНЕРАЦИЯ СЕТКИ ЛАБИРИНТА ---
func _generate_building_layout():
	maze_grid.clear()
	for x in range(grid_width):
		var column = []
		for y in range(grid_height):
			column.append(1)
		maze_grid.append(column)

	var stack = []
	var start_pos = Vector2i(1, 1)
	maze_grid[start_pos.x][start_pos.y] = 0
	stack.append(start_pos)

	var directions = [Vector2i(0, -2), Vector2i(0, 2), Vector2i(-2, 0), Vector2i(2, 0)]

	while stack.size() > 0:
		var current = stack[-1]
		var neighbors = []

		for dir in directions:
			var nx = current.x + dir.x
			var ny = current.y + dir.y
			if nx > 0 and nx < grid_width - 1 and ny > 0 and ny < grid_height - 1:
				if maze_grid[nx][ny] == 1:
					neighbors.append(dir)

		if neighbors.size() > 0:
			var chosen_dir = neighbors[randi() % neighbors.size()]
			var wall_x = current.x + chosen_dir.x / 2
			var wall_y = current.y + chosen_dir.y / 2
			var next_x = current.x + chosen_dir.x
			var next_y = current.y + chosen_dir.y

			maze_grid[wall_x][wall_y] = 0
			maze_grid[next_x][next_y] = 0

			stack.append(Vector2i(next_x, next_y))
		else:
			stack.pop_back()

	for r in range(num_rooms):
		var rx = (randi() % max(1, int((grid_width - 4) / 2.0))) * 2 + 1
		var ry = (randi() % max(1, int((grid_height - 4) / 2.0))) * 2 + 1
		
		for w in range(3):
			for h in range(3):
				if rx + w < grid_width - 1 and ry + h < grid_height - 1:
					maze_grid[rx + w][ry + h] = 0

	for x in range(1, grid_width - 1):
		for y in range(1, grid_height - 1):
			if maze_grid[x][y] == 1:
				var horizontal_pass = (maze_grid[x-1][y] == 0 and maze_grid[x+1][y] == 0)
				var vertical_pass = (maze_grid[x][y-1] == 0 and maze_grid[x][y+1] == 0)
				if (horizontal_pass or vertical_pass) and randf() < wall_removal_chance:
					maze_grid[x][y] = 0

func _setup_astar_navigation():
	astar_grid.region = Rect2i(0, 0, grid_width, grid_height)
	astar_grid.cell_size = cell_size
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	for x in range(grid_width):
		for y in range(grid_height):
			if maze_grid[x][y] == 1:
				astar_grid.set_point_solid(Vector2i(x, y), true)

func _build_maze_from_grid():
	if not world_container: return

	# --- ОЧИСТКА СТАРЫХ СТЕН ИЗ СЦЕНЫ ---
	var old_walls = world_container.get_node_or_null("MazeWalls")
	if old_walls:
		old_walls.queue_free()

	for child in world_container.get_children():
		if child is StaticBody2D and child.name != "Player":
			child.queue_free()

	var walls_node = Node2D.new()
	walls_node.name = "MazeWalls"
	world_container.add_child(walls_node)

	var maze_pixel_size = Vector2(grid_width * cell_size.x, grid_height * cell_size.y)
	var screen_center = Vector2(1280, 720) / 2.0
	var start_offset = (screen_center - (maze_pixel_size / 2.0)) + (cell_size / 2.0)

	var empty_cells_local = []

	for x in range(grid_width):
		for y in range(grid_height):
			var pos = start_offset + Vector2(x * cell_size.x, y * cell_size.y)

			if maze_grid[x][y] == 1:
				var wall = StaticBody2D.new()
				wall.position = pos

				var col = CollisionShape2D.new()
				var shape = RectangleShape2D.new()
				shape.size = cell_size
				col.shape = shape
				wall.add_child(col)

				var drawer = Node2D.new()
				drawer.set_script(load("res://scripts/MazeWallDrawer.gd"))
				wall.add_child(drawer)

				walls_node.add_child(wall)

				if randf() < lamp_spawn_chance and x > 0 and x < grid_width - 1 and y > 0 and y < grid_height - 1:
					_spawn_wall_lamp(pos)
			else:
				empty_cells_local.append(pos)

	if player and empty_cells_local.size() > 0:
		player.position = empty_cells_local[0]

	# --- СПАВН КЛЮЧЕЙ ---
	if collectibles:
		for c in collectibles.get_children():
			c.queue_free()

		var available_cells = empty_cells_local.duplicate()
		available_cells.pop_front()
		available_cells.shuffle()

		for i in range(min(total_keys_needed, available_cells.size())):
			var key_node = Area2D.new()
			key_node.name = "Key_" + str(i + 1)
			key_node.set_script(load("res://scripts/KeyFragment.gd"))
			key_node.position = available_cells[i]
			collectibles.add_child(key_node)

	# --- ОЧИСТКА И СПАВН ФАНТОМОВ ---
	if world_container:
		for old_child in world_container.get_children():
			if old_child is CharacterBody2D and old_child != player:
				old_child.queue_free()

	for old_phantom_group in get_tree().get_nodes_in_group("Phantom"):
		old_phantom_group.queue_free()

	phantoms.clear()
	var spawn_indices = []
	for i in range(phantoms_count):
		var idx = empty_cells_local.size() - 1 - (i * 3)
		if idx > 5:
			spawn_indices.append(idx)

	for i in range(spawn_indices.size()):
		var phantom = CharacterBody2D.new()
		phantom.name = "PhantomEnemy_" + str(i + 1)
		phantom.set_script(load("res://scripts/PhantomEnemy.gd"))
		
		if "speed" in phantom:
			phantom.speed *= phantom_speed_multiplier
			
		world_container.add_child(phantom)
		phantom.position = empty_cells_local[spawn_indices[i]]
		phantom.z_index = 20
		phantom.visible = true
		
		if phantom.has_method("setup_navigation"):
			phantom.setup_navigation(astar_grid, start_offset, cell_size)
			
		phantoms.append(phantom)

	# --- ЕДИНСТВЕННЫЙ ПОРТАЛ ---
	for existing_portal in get_tree().get_nodes_in_group("Portal"):
		existing_portal.queue_free()

	if empty_cells_local.size() > 5:
		exit_portal = Area2D.new()
		exit_portal.name = "ExitPortal"
		exit_portal.set_script(load("res://scripts/Portal.gd"))
		
		var portal_cell_index = randi_range(empty_cells_local.size() / 2, empty_cells_local.size() - 1)
		exit_portal.position = empty_cells_local[portal_cell_index]
		
		exit_portal.visible = false
		exit_portal.process_mode = PROCESS_MODE_DISABLED
		
		if exit_portal.has_signal("player_entered_portal"):
			exit_portal.player_entered_portal.connect(_on_player_entered_portal)
			
		world_container.add_child(exit_portal)

func _spawn_wall_lamp(lamp_position: Vector2):
	var lamp = PointLight2D.new()
	lamp.position = lamp_position
	lamp.energy = 0.8
	lamp.texture_scale = 1.8
	
	var light_tex = GradientTexture2D.new()
	light_tex.fill = GradientTexture2D.FILL_RADIAL
	light_tex.fill_from = Vector2(0.5, 0.5)
	light_tex.fill_to = Vector2(0.5, 0.0)
	light_tex.width = 128
	light_tex.height = 128
	
	var grad = Gradient.new()
	grad.set_color(0, Color(0.8, 0.85, 1.0, 0.9))
	grad.set_color(1, Color(0.0, 0.0, 0.0, 0.0))
	
	light_tex.gradient = grad
	lamp.texture = light_tex
	
	if world_container:
		world_container.add_child(lamp)

# --- HUD И ПЕРЕХОД МЕЖДУ УРОВНЯМИ ---
func _setup_hud():
	var hud_canvas = get_node_or_null("HUD") as CanvasLayer
	if not hud_canvas:
		hud_canvas = CanvasLayer.new()
		hud_canvas.name = "HUD"
		add_child(hud_canvas)

	hud_label = hud_canvas.get_node_or_null("StatusLabel") as Label
	if not hud_label:
		hud_label = Label.new()
		hud_label.name = "StatusLabel"
		hud_canvas.add_child(hud_label)

	hud_label.anchor_left = 0.5
	hud_label.anchor_top = 0.0
	hud_label.anchor_right = 0.5
	hud_label.anchor_bottom = 0.0
	hud_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hud_label.grow_vertical = Control.GROW_DIRECTION_END
	hud_label.position.y = 20

	var custom_font_path = "res://fonts/CutiveMono-Regular.ttf"
	if ResourceLoader.exists(custom_font_path):
		hud_label.add_theme_font_override("font", load(custom_font_path))

	hud_label.add_theme_font_size_override("font_size", 18)
	hud_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	hud_label.add_theme_color_override("font_outline_color", Color(0.0, 0.2, 0.0, 0.8))
	hud_label.add_theme_constant_override("outline_size", 4)

	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.05, 0.07, 0.09, 0.85)
	style_box.border_color = Color(0.2, 1.0, 0.4, 0.6)
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(6)
	style_box.content_margin_left = 16
	style_box.content_margin_top = 8
	style_box.content_margin_right = 16
	style_box.content_margin_bottom = 8

	hud_label.add_theme_stylebox_override("normal", style_box)
	hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_update_hud_text(0)

func _on_player_collected_key(current_keys: int):
	_update_hud_text(current_keys)

func _update_hud_text(current_keys: int):
	if not hud_label: return
	
	var current_lvl = _get_current_level_number()

	if current_keys >= total_keys_needed:
		hud_label.text = "LEVEL " + str(current_lvl) + "/10 CLEARED // PORTAL OPEN!"
		hud_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		
		var current_style = hud_label.get_theme_stylebox("normal") as StyleBoxFlat
		if current_style:
			current_style.border_color = Color(1.0, 0.85, 0.2, 0.8)
			
		if exit_portal and is_instance_valid(exit_portal):
			exit_portal.visible = true
			exit_portal.process_mode = PROCESS_MODE_INHERIT
	else:
		hud_label.text = "SECTOR " + str(current_lvl) + "/10   |   KEYS: " + str(current_keys) + " / " + str(total_keys_needed) + "   |   THREATS: " + str(phantoms_count)
		
		if exit_portal and is_instance_valid(exit_portal):
			exit_portal.visible = false
			exit_portal.process_mode = PROCESS_MODE_DISABLED

# --- ПЕРЕХОД МЕЖДУ УРОВНЯМИ И ФИНАЛ ---
func _on_player_entered_portal():
	print("Портал пройден!")
	var current_lvl = _get_current_level_number()
	var gm = get_node_or_null("/root/GameManager")
	
	if current_lvl >= 10:
		_finish_game(gm)
		return

	if gm:
		if gm.has_method("next_level"):
			gm.next_level()
		elif "current_level" in gm:
			gm.current_level += 1
		elif "level" in gm:
			gm.level += 1

	get_tree().reload_current_scene()

func _finish_game(gm: Node):
	print("ВСЕ 10 СЕКТОРОВ УСПЕШНО ПРОЙДЕНЫ!")
	
	if gm:
		if gm.has_method("complete_maze_game"):
			gm.complete_maze_game()
			return
		elif gm.has_method("switch_to_os"):
			gm.switch_to_os()
			return
		elif "current_level" in gm:
			gm.current_level = 1
			
			get_tree().change_scene_to_file("res://scenes/os.tscn")
			
			if gm:
				if gm.has_method("stop_maze_music"):
					gm.stop_maze_music()
					
		elif "bgm_player" in gm and gm.bgm_player:
			gm.bgm_player.stop()

		if gm.has_method("complete_maze_game"):
			gm.complete_maze_game()
			return
		elif gm.has_method("switch_to_os"):
			gm.switch_to_os()
			return
		elif "current_level" in gm:
			gm.current_level = 1
			get_tree().change_scene_to_file("res://scenes/os.tscn")
			
# --- ДЕБАГ / ЧИТ-КОДЫ ДЛЯ ТЕСТИРОВАНИЯ ---
func _unhandled_input(event: InputEvent) -> void:
	# Пропуск уровня по нажатию Shift + N или F3
	if event is InputEventKey and event.pressed and not event.echo:
		if (event.keycode == KEY_N and Input.is_key_pressed(KEY_SHIFT)) or event.keycode == KEY_F3:
			_debug_skip_level()

func _debug_skip_level() -> void:
	print("[DEBUG] Пропуск сектора ", _get_current_level_number())
	_on_player_entered_portal()
