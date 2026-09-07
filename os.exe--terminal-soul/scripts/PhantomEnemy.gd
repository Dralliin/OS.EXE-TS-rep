extends CharacterBody2D

enum State { PATROL, CHASE, SEARCH }

@export var patrol_speed: float = 70.0
@export var chase_speed: float = 130.0
@export var view_distance: float = 250.0

var current_state: State = State.PATROL
var player: CharacterBody2D
var astar_grid: AStarGrid2D
var start_offset: Vector2 = Vector2.ZERO
var cell_size: Vector2 = Vector2(52, 48)

var current_path: Array[Vector2] = []
var last_known_player_pos: Vector2 = Vector2.ZERO
var raycast: RayCast2D
var is_catching: bool = false
var patrol_timer: float = 0.0

func _ready():
	z_index = 20
	visible = true
	add_to_group("Enemies")
	motion_mode = MOTION_MODE_FLOATING
	_create_collision_if_missing()
	_setup_raycast()

func _setup_raycast():
	raycast = RayCast2D.new()
	raycast.enabled = true
	raycast.add_exception(self)
	add_child(raycast)

func setup_navigation(grid: AStarGrid2D, offset: Vector2, c_size: Vector2):
	astar_grid = grid
	start_offset = offset
	cell_size = c_size

func _draw():
	var center = Vector2.ZERO
	var core_color = Color(1.0, 0.1, 0.1, 1.0) if current_state == State.CHASE else Color(0.6, 0.1, 0.2, 0.8)
	
	draw_circle(center, 14.0, Color(0.2, 0.0, 0.0, 0.4))
	draw_circle(center, 9.0, core_color)
	draw_rect(Rect2(-3, -3, 6, 6), Color(1.0, 1.0, 1.0, 0.9))

func _physics_process(delta):
	if is_catching: return
	
	if not player:
		player = get_tree().get_first_node_in_group("Player") as CharacterBody2D
		return

	var can_see_player = _check_line_of_sight()

	match current_state:
		State.PATROL:
			if can_see_player:
				current_state = State.CHASE
				queue_redraw()
			else:
				_process_patrol(delta)

		State.CHASE:
			if can_see_player:
				last_known_player_pos = player.position
				_move_towards(player.position, chase_speed)
			else:
				current_state = State.SEARCH
				_recalculate_path_to(last_known_player_pos)

		State.SEARCH:
			if can_see_player:
				current_state = State.CHASE
			else:
				if current_path.size() > 0:
					_follow_path(chase_speed)
				else:
					current_state = State.PATROL
					queue_redraw()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and (collider.is_in_group("Player") or collider == player):
			_catch_player()

func _check_line_of_sight() -> bool:
	if not player: return false
	
	var dist = position.distance_to(player.position)
	if dist > view_distance:
		return false

	raycast.target_position = player.position - position
	raycast.force_raycast_update()

	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider == player or collider.is_in_group("Player"):
			return true

	return false

func _process_patrol(delta):
	patrol_timer += delta
	if patrol_timer >= 3.0 or current_path.size() == 0:
		patrol_timer = 0.0
		_pick_random_patrol_target()

	_follow_path(patrol_speed)

func _pick_random_patrol_target():
	if not astar_grid: return
	var grid_size = astar_grid.region.size
	var random_cell = Vector2i(randi() % grid_size.x, randi() % grid_size.y)
	
	if not astar_grid.is_point_solid(random_cell):
		var target_pos = start_offset + Vector2(random_cell.x * cell_size.x, random_cell.y * cell_size.y)
		_recalculate_path_to(target_pos)

func _recalculate_path_to(target_pos: Vector2):
	if not astar_grid: return

	var my_cell = Vector2i(((position - start_offset) / cell_size).round())
	var target_cell = Vector2i(((target_pos - start_offset) / cell_size).round())

	my_cell.x = clamp(my_cell.x, 0, astar_grid.region.size.x - 1)
	my_cell.y = clamp(my_cell.y, 0, astar_grid.region.size.y - 1)
	target_cell.x = clamp(target_cell.x, 0, astar_grid.region.size.x - 1)
	target_cell.y = clamp(target_cell.y, 0, astar_grid.region.size.y - 1)

	var id_path = astar_grid.get_id_path(my_cell, target_cell)
	if id_path.size() > 1:
		id_path.remove_at(0)

	current_path.clear()
	for cell_id in id_path:
		var world_pos = start_offset + Vector2(cell_id.x * cell_size.x, cell_id.y * cell_size.y)
		current_path.append(world_pos)

func _follow_path(move_speed: float):
	if current_path.size() > 0:
		var target_pos = current_path[0]
		_move_towards(target_pos, move_speed)
		if position.distance_to(target_pos) < 12.0:
			current_path.remove_at(0)
	else:
		velocity = Vector2.ZERO

func _move_towards(target_pos: Vector2, move_speed: float):
	var direction = (target_pos - position).normalized()
	velocity = direction * move_speed
	move_and_slide()

func _catch_player():
	if is_catching: return
	is_catching = true
	get_tree().call_deferred("reload_current_scene")

func _create_collision_if_missing():
	if not has_node("CollisionShape2D"):
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 8.0
		col.shape = shape
		add_child(col)
