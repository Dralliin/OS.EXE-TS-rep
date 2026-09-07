extends ColorRect

@export var line_color: Color = Color(0.18, 0.65, 0.85, 0.5)
@export var cursor_color: Color = Color(0.3, 1.0, 0.5, 0.9)
@export var alert_color: Color = Color(0.9, 0.15, 0.15, 0.8)

@export var glitch_chance: float = 0.08
@export var draw_speed: float = 1.2

class GeoObject:
	var verts: Array[Vector3] = []
	var edges: Array[Vector2i] = []
	var screen_pos: Vector2
	var scale: float
	
	var is_drawn: bool = false
	var draw_progress: float = 0.0
	var rot_speed: Vector3
	var current_rot: Vector3 = Vector3.ZERO
	
	var is_glitching: bool = false
	var glitch_timer: float = 0.0

var objects: Array[GeoObject] = []

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var obj1 = GeoObject.new()
	obj1.scale = 330.0
	_build_icosahedron(obj1, obj1.scale)
	obj1.screen_pos = Vector2(0.5, 0.5)
	obj1.rot_speed = Vector3(0.18, 0.25, 0.1)
	objects.append(obj1)
	
	var obj2 = GeoObject.new()
	obj2.scale = 75.0
	_build_cube(obj2, obj2.scale)
	obj2.screen_pos = Vector2(0.12, 0.18)
	obj2.rot_speed = Vector3(0.4, -0.3, 0.2)
	objects.append(obj2)
	
	var obj3 = GeoObject.new()
	obj3.scale = 85.0
	_build_tetrahedron(obj3, obj3.scale)
	obj3.screen_pos = Vector2(0.88, 0.82)
	obj3.rot_speed = Vector3(-0.25, 0.4, -0.15)
	objects.append(obj3)

func _process(delta: float):
	for obj in objects:
		_update_object_logic(obj, delta)
		
	queue_redraw()

func _update_object_logic(obj: GeoObject, delta: float):
	obj.current_rot += obj.rot_speed * delta
	
	if not obj.is_drawn:
		obj.draw_progress = min(1.0, obj.draw_progress + delta * draw_speed)
		if obj.draw_progress >= 1.0:
			obj.is_drawn = true
	
	if not obj.is_glitching and randf() < (glitch_chance * delta):
		obj.is_glitching = true
		obj.glitch_timer = randf_range(0.05, 0.15)
		
	if obj.is_glitching:
		obj.glitch_timer -= delta
		if obj.glitch_timer <= 0:
			obj.is_glitching = false

func _draw():
	for obj in objects:
		var center = size * obj.screen_pos
		var draw_color = line_color
		var active_center = center
		
		if obj.is_glitching:
			active_center += Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
			draw_color = alert_color
			
		var projected: Array[Vector2] = []
		var distance = 550.0
		
		for v in obj.verts:
			var vert_pos = v
			if obj.is_glitching:
				vert_pos += Vector3(randf_range(-15, 15), randf_range(-15, 15), randf_range(-15, 15))
				
			var rot = _rotate_3d(vert_pos, obj.current_rot.x, obj.current_rot.y, obj.current_rot.z)
			var z_fact = distance / (distance + rot.z)
			projected.append(Vector2(rot.x * z_fact, rot.y * z_fact) + active_center)
		
		var total_edges = obj.edges.size()
		var float_edge_progress = total_edges * obj.draw_progress
		var full_edges_count = int(float_edge_progress)
		var partial_factor = float_edge_progress - full_edges_count
		
		for i in range(full_edges_count):
			if i < total_edges:
				var edge = obj.edges[i]
				draw_line(projected[edge.x], projected[edge.y], draw_color, 2.0, true)
		
		if not obj.is_drawn and full_edges_count < total_edges:
			var current_edge = obj.edges[full_edges_count]
			var p1 = projected[current_edge.x]
			var p2 = projected[current_edge.y]
			var current_draw_point = p1.lerp(p2, partial_factor)
			
			draw_line(p1, current_draw_point, draw_color, 2.0, true)
			draw_circle(current_draw_point, 3.5, cursor_color)

# --- ГЕОМЕТРИЯ ---
func _rotate_3d(v: Vector3, ax: float, ay: float, az: float) -> Vector3:
	var y1 = v.y * cos(ax) - v.z * sin(ax)
	var z1 = v.y * sin(ax) + v.z * cos(ax)
	var x2 = v.x * cos(ay) + z1 * sin(ay)
	var z2 = -v.x * sin(ay) + z1 * cos(ay)
	return Vector3(x2 * cos(az) - y1 * sin(az), x2 * sin(az) + y1 * cos(az), z2)

func _build_cube(obj: GeoObject, s: float):
	obj.verts = [Vector3(-s,-s,-s), Vector3(s,-s,-s), Vector3(s,s,-s), Vector3(-s,s,-s), Vector3(-s,-s,s), Vector3(s,-s,s), Vector3(s,s,s), Vector3(-s,s,s)]
	obj.edges = [Vector2i(0,1), Vector2i(1,2), Vector2i(2,3), Vector2i(3,0), Vector2i(4,5), Vector2i(5,6), Vector2i(6,7), Vector2i(7,4), Vector2i(0,4), Vector2i(1,5), Vector2i(2,6), Vector2i(3,7)]

func _build_tetrahedron(obj: GeoObject, s: float):
	obj.verts = [Vector3(s,s,s), Vector3(-s,-s,s), Vector3(-s,s,-s), Vector3(s,-s,-s)]
	obj.edges = [Vector2i(0,1), Vector2i(0,2), Vector2i(0,3), Vector2i(1,2), Vector2i(1,3), Vector2i(2,3)]

func _build_icosahedron(obj: GeoObject, s: float):
	var phi = (1.0 + sqrt(5.0)) / 2.0
	var raw = [Vector3(-1,phi,0), Vector3(1,phi,0), Vector3(-1,-phi,0), Vector3(1,-phi,0), Vector3(0,-1,phi), Vector3(0,1,phi), Vector3(0,-1,-phi), Vector3(0,1,-phi), Vector3(phi,0,-1), Vector3(phi,0,1), Vector3(-phi,0,-1), Vector3(-phi,0,1)]
	for v in raw: obj.verts.append(v.normalized() * s)
	for i in range(obj.verts.size()):
		for j in range(i + 1, obj.verts.size()):
			if obj.verts[i].distance_to(obj.verts[j]) < s * 1.3: obj.edges.append(Vector2i(i, j))
