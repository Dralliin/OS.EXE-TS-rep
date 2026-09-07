extends Control

@onready var chess_grid = $ChessGrid
@onready var health_bar = $HealthBar
@onready var turn_timer = $TurnTimer
@onready var player_timer_label = $PlayerTimerLabel
@onready var virus_timer_label = $VirusTimerLabel
@onready var glitch_overlay = $GlitchColorRect
@onready var win_popup = $WinPopupContainer
@onready var win_title_label = $WinPopupContainer/VBox/TitleLabel
@onready var win_sub_label = $WinPopupContainer/VBox/SubLabel
@onready var win_continue_button = $WinPopupContainer/VBox/ContinueButton

@onready var death_flash_rect = $DeathFlashColorRect

var player_time_left = 300
var virus_time_left = 300

var board_state = []
var board_buttons = []

var piece_textures = {
	0: null,
	1: preload("res://icons/chess/w_pawn.png"),
	2: preload("res://icons/chess/w_knight.png"),
	3: preload("res://icons/chess/w_bishop.png"),
	4: preload("res://icons/chess/w_rook.png"),
	5: preload("res://icons/chess/w_queen.png"),
	6: preload("res://icons/chess/w_king.png"),
	
	-1: preload("res://icons/chess/b_pawn.png"),
	-2: preload("res://icons/chess/b_knight.png"),
	-3: preload("res://icons/chess/b_bishop.png"),
	-4: preload("res://icons/chess/b_rook.png"),
	-5: preload("res://icons/chess/b_queen.png"),
	-6: preload("res://icons/chess/b_king.png")
}

var backup_symbols = {
	0: "",
	1: "♙", 2: "♘", 3: "♗", 4: "♖", 5: "♕", 6: "♔",
	-1: "♟", -2: "♞", -3: "♝", -4: "♜", -5: "♛", -6: "♚"
}

var is_player_turn: bool = true
var is_piece_selected: bool = false
var selected_row: int = -1
var selected_col: int = -1

var last_virus_from: Vector2i = Vector2i(-1, -1)
var last_virus_to: Vector2i = Vector2i(-1, -1)

var move_sound = preload("res://sounds/chess-com-check-sound.mp3")
var audio_player: AudioStreamPlayer

var glitch_sound = preload("res://sounds/b1432bcef1b0835.mp3")
var glitch_audio_player: AudioStreamPlayer

var current_base_glitch: float = 0.0
var is_game_over: bool = false

func _ready():
	if win_popup:
		win_popup.visible = false
		
	if death_flash_rect:
		death_flash_rect.visible = false
		
	if win_continue_button:
		win_continue_button.pressed.connect(_on_win_continue_pressed)

	# Инициализация звуковых плееров
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	if move_sound:
		audio_player.stream = move_sound
		
	glitch_audio_player = AudioStreamPlayer.new()
	add_child(glitch_audio_player)
	if glitch_sound:
		glitch_audio_player.stream = glitch_sound

	# Инициализация игры и сетки
	_init_board_state()
	_create_ui_grid()
	_update_timer_labels()
	
	if turn_timer:
		turn_timer.wait_time = 1.0
		turn_timer.autostart = true
		if not turn_timer.timeout.is_connected(_on_turn_timer_timeout):
			turn_timer.timeout.connect(_on_turn_timer_timeout)
		turn_timer.start()

	print("ПАРТИЯ НАЧАТА: Система против Вируса.")

# ====================================================
#  ОБРАБОТКА ПОБЕДЫ И ПОРАЖЕНИЯ
# ====================================================
func _trigger_player_victory(reason: String = "Уровень девиации 1 повержен!"):
	if is_game_over: return
	is_game_over = true
	
	if turn_timer:
		turn_timer.stop()
		
	if win_popup:
		win_title_label.text = "СИСТЕМА: ПОБЕДА"
		win_sub_label.text = reason + "\nЗапуск диалогового протокола..."
		win_popup.visible = true

func _on_win_continue_pressed():
	if win_popup:
		win_popup.visible = false
	_start_post_chess_dialogue()

func _start_post_chess_dialogue():
	print("СИСТЕМА: Переход к сюжетному диалогу...")
	# GameManager.return_to_os()

func _trigger_player_defeat(reason: String = "Вирус перехватил контроль!"):
	if is_game_over: return
	is_game_over = true
	
	print("ПОРАЖЕНИЕ: " + reason)
	
	if turn_timer:
		turn_timer.stop()
		
	if death_flash_rect and death_flash_rect.material:
		death_flash_rect.visible = true
		var mat = death_flash_rect.material as ShaderMaterial
		
		var tween = create_tween()
		tween.tween_property(mat, "shader_parameter/flash_progress", 1.0, 0.45)\
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
			
		await tween.finished
		await get_tree().create_timer(0.2).timeout
		
	if is_game_over: return
	is_game_over = true
	
	if turn_timer:
		turn_timer.stop()
		
	await get_tree().create_timer(0.5).timeout
	
	get_tree().change_scene_to_file("res://scenes/defeat_scene.tscn")

# ====================================================
#  ДОСКА И ИНТЕРФЕЙС
# ====================================================
func _init_board_state():
	board_state = [
		[-4, -2, -3, -5, -6, -3, -2, -4],
		[-1, -1, -1, -1, -1, -1, -1, -1],
		[ 0,  0,  0,  0,  0,  0,  0,  0],
		[ 0,  0,  0,  0,  0,  0,  0,  0],
		[ 0,  0,  0,  0,  0,  0,  0,  0],
		[ 0,  0,  0,  0,  0,  0,  0,  0],
		[ 1,  1,  1,  1,  1,  1,  1,  1],
		[ 4,  2,  3,  5,  6,  3,  2,  4]
	]

func _create_ui_grid():
	if chess_grid is GridContainer:
		chess_grid.columns = 8
		
	for child in chess_grid.get_children():
		child.queue_free()
		
	board_buttons.clear()
	
	for r in range(8):
		var row_buttons = []
		for c in range(8):
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(64, 64)
			btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			
			# --- ДОБАВЛЕННЫЕ СТРОКИ ДЛЯ ИСПРАВЛЕНИЯ КЛИКОВ ---
			btn.focus_mode = Control.FOCUS_NONE
			btn.mouse_filter = Control.MOUSE_FILTER_PASS
			# ------------------------------------------------
			
			_apply_cell_style(btn, r, c, false)
			
			var piece = board_state[r][c]
			if piece_textures.get(piece) != null:
				btn.icon = piece_textures[piece]
				btn.expand_icon = true
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			else:
				btn.text = backup_symbols[piece]
				if piece > 0:
					btn.add_theme_color_override("font_color", Color(0.0, 1.0, 0.3))
				elif piece < 0:
					btn.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))
			
			btn.pressed.connect(func(): _on_cell_pressed(r, c))
			chess_grid.add_child(btn)
			row_buttons.append(btn)
		board_buttons.append(row_buttons)

func _apply_cell_style(btn: Button, r: int, c: int, is_highlighted: bool):
	var sb = StyleBoxFlat.new()
	if is_highlighted:
		sb.bg_color = Color(0.0, 0.4, 0.15, 0.8)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.0, 1.0, 0.3)
	elif Vector2i(r, c) == last_virus_from or Vector2i(r, c) == last_virus_to:
		sb.bg_color = Color(0.4, 0.0, 0.0, 0.6)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(1.0, 0.2, 0.2)
	else:
		if (r + c) % 2 == 0:
			sb.bg_color = Color(0.05, 0.05, 0.05)
		else:
			sb.bg_color = Color(0.12, 0.12, 0.12)
			
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)

func _on_cell_pressed(r: int, c: int):
	if is_game_over or not is_player_turn:
		return
		
	var piece = board_state[r][c]
	
	if not is_piece_selected:
		if piece > 0:
			is_piece_selected = true
			selected_row = r
			selected_col = c
			_highlight_legal_moves(r, c)
	else:
		if r == selected_row and c == selected_col:
			is_piece_selected = false
			_clear_board_highlights()
			return
			
		if is_move_valid(selected_row, selected_col, r, c):
			var moving_piece = board_state[selected_row][selected_col]
			var victim_piece = board_state[r][c]
			
			_clear_board_highlights()
			
			board_state[selected_row][selected_col] = 0
			board_state[r][c] = moving_piece
			
			if moving_piece == 1 and r == 0:
				board_state[r][c] = 5
				moving_piece = 5
			
			board_buttons[selected_row][selected_col].icon = null
			board_buttons[selected_row][selected_col].text = ""
			
			if piece_textures.get(moving_piece) != null:
				board_buttons[r][c].icon = piece_textures[moving_piece]
				board_buttons[r][c].expand_icon = true
				board_buttons[r][c].icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			else:
				board_buttons[r][c].text = backup_symbols[moving_piece]
				board_buttons[r][c].add_theme_color_override("font_color", Color(0.0, 1.0, 0.3))
				
			is_piece_selected = false
			_play_move_sound()
			
			if victim_piece == -6:
				_trigger_player_victory("Король Вируса уничтожен!")
				return
				
			if not _has_legal_moves(false):
				if is_king_in_check(false):
					_trigger_player_victory("ВИРУСУ ПОСТАВЛЕН МАТ!")
				else:
					_trigger_player_victory("ПАТ!")
				return
				
			_end_player_turn()
		else:
			if piece > 0:
				_clear_board_highlights()
				selected_row = r
				selected_col = c
				_highlight_legal_moves(r, c)

func _highlight_legal_moves(fr: int, fc: int):
	for r in range(8):
		for c in range(8):
			if is_move_valid(fr, fc, r, c):
				_apply_cell_style(board_buttons[r][c], r, c, true)

func _clear_board_highlights():
	for r in range(8):
		for c in range(8):
			_apply_cell_style(board_buttons[r][c], r, c, false)

func _end_player_turn():
	is_player_turn = false
	var virus_thinking_delay = randf_range(1.5, 4.0)
	await get_tree().create_timer(virus_thinking_delay).timeout
	_make_virus_ai_move()

func _make_virus_ai_move():
	if is_game_over: return
	
	var valid_moves = []
	for fr in range(8):
		for fc in range(8):
			if board_state[fr][fc] < 0:
				for target_r in range(8):
					for target_c in range(8):
						if is_move_valid(fr, fc, target_r, target_c):
							var target_piece = board_state[target_r][target_c]
							var score = 0
							if target_piece > 0:
								score += abs(target_piece) * 10
							if is_king_in_check(false):
								score += 1000
							valid_moves.append({
								"from_r": fr, "from_c": fc,
								"to_r": target_r, "to_c": target_c,
								"score": score
							})

	if valid_moves.size() == 0:
		_trigger_player_victory("У Вируса нет легальных ходов.")
		return

	var max_score = -9999
	for move in valid_moves:
		if move["score"] > max_score:
			max_score = move["score"]

	var best_moves = []
	for move in valid_moves:
		if move["score"] == max_score:
			best_moves.append(move)

	var chosen_move = best_moves[randi() % best_moves.size()]
	var fr = chosen_move["from_r"]
	var fc = chosen_move["from_c"]
	var target_r = chosen_move["to_r"]
	var target_c = chosen_move["to_c"]
	
	var virus_piece = board_state[fr][fc]
	var victim_piece = board_state[target_r][target_c]
	
	if virus_piece == -1 and abs(target_c - fc) == 1 and victim_piece == 0:
		if board_state[fr][target_c] == 1:
			board_state[fr][target_c] = 0
			board_buttons[fr][target_c].icon = null
			board_buttons[fr][target_c].text = ""
	
	if virus_piece == -1 and target_r == 7:
		virus_piece = -5
		
	if victim_piece > 0:
		take_damage(5)
		_play_glitch_sound()
		if victim_piece == 6:
			_trigger_player_defeat("Ваш Король уничтожен!")
			return
	else:
		_play_move_sound()
			
	board_state[fr][fc] = 0
	board_state[target_r][target_c] = virus_piece
	
	board_buttons[fr][fc].icon = null
	board_buttons[fr][fc].text = ""
	
	if piece_textures.get(virus_piece) != null:
		board_buttons[target_r][target_c].icon = piece_textures[virus_piece]
		board_buttons[target_r][target_c].expand_icon = true
		board_buttons[target_r][target_c].icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		board_buttons[target_r][target_c].text = backup_symbols[virus_piece]
		
	if not _has_legal_moves(true):
		_trigger_player_defeat("Вам поставлен МАТ!")
		return

	last_virus_from = Vector2i(fr, fc)
	last_virus_to = Vector2i(target_r, target_c)
	_clear_board_highlights()

	is_player_turn = true

func _on_turn_timer_timeout():
	if is_game_over: return
	
	if is_player_turn:
		player_time_left -= 1
		if player_time_left <= 0:
			player_time_left = 30
			take_damage(10)
			is_piece_selected = false
			_clear_board_highlights()
			_end_player_turn()
	else:
		virus_time_left -= 1
		if virus_time_left <= 0:
			virus_time_left = 0
			
	_update_timer_labels()

func _update_timer_labels():
	if player_timer_label:
		player_timer_label.text = "ИГРОК: " + _format_time(player_time_left)
	if virus_timer_label:
		virus_timer_label.text = "ВИРУС: " + _format_time(virus_time_left)

func take_damage(amount: int):
	if health_bar:
		health_bar.value -= amount
		var hp = health_bar.value
		
		if hp <= 20: current_base_glitch = 0.8
		elif hp <= 40: current_base_glitch = 0.55
		elif hp <= 60: current_base_glitch = 0.35
		elif hp <= 80: current_base_glitch = 0.15
		else: current_base_glitch = 0.0
			
		_trigger_glitch_burst()

		if hp <= 0:
			_trigger_player_defeat("Здоровье системы исчерпано!")

func _trigger_glitch_burst():
	if not glitch_overlay: return
	var mat = glitch_overlay.material as ShaderMaterial
	if not mat: return
	
	var tween = create_tween()
	var burst_intensity = min(1.0, current_base_glitch + 0.4)
	mat.set_shader_parameter("glitch_intensity", burst_intensity)
	mat.set_shader_parameter("color_split", 0.01)
	
	tween.tween_property(mat, "shader_parameter/glitch_intensity", current_base_glitch, 0.3)
	tween.parallel().tween_property(mat, "shader_parameter/color_split", current_base_glitch * 0.005, 0.3)

func _has_legal_moves(for_player: bool) -> bool:
	for r in range(8):
		for c in range(8):
			var piece = board_state[r][c]
			if (for_player and piece > 0) or (not for_player and piece < 0):
				for target_r in range(8):
					for target_c in range(8):
						if is_move_valid(r, c, target_r, target_c):
							return true
	return false

func _format_time(seconds: int) -> String:
	var mins = floori(seconds / 60.0)
	var secs = seconds % 60
	return "%02d:%02d" % [mins, secs]

# ====================================================
# ЕДИНЫЙ БЛОК ПРАВИЛ, ПРОВЕРКИ ШАХА И ГЕОМЕТРИИ
# ====================================================

func is_king_in_check(for_player: bool, custom_board: Array = []) -> bool:
	var b = custom_board if custom_board.size() > 0 else board_state
	var king_val = 6 if for_player else -6
	var king_r = -1
	var king_c = -1

	for r in range(8):
		for c in range(8):
			if b[r][c] == king_val:
				king_r = r
				king_c = c
				break
		if king_r != -1: break

	if king_r == -1: return true

	for r in range(8):
		for c in range(8):
			var p = b[r][c]
			if (for_player and p < 0) or (not for_player and p > 0):
				if _can_piece_attack_target(r, c, king_r, king_c, b):
					return true
	return false

func _can_piece_attack_target(from_r: int, from_c: int, to_r: int, to_c: int, b: Array) -> bool:
	if from_r == to_r and from_c == to_c: return false
	
	var piece = b[from_r][from_c]
	var target = b[to_r][to_c]
	
	if piece > 0 and target > 0: return false
	if piece < 0 and target < 0: return false

	var abs_p = abs(piece)
	var dr = to_r - from_r
	var dc = to_c - from_c
	var abs_r = abs(dr)
	var abs_c = abs(dc)

	match abs_p:
		1:
			if piece > 0 and dr == -1 and abs_c == 1 and target < 0: return true
			if piece < 0 and dr == 1 and abs_c == 1 and target > 0: return true
			return false
		4: if dr == 0 or dc == 0: return _is_path_clear_on_board(from_r, from_c, to_r, to_c, b)
		3: if abs_r == abs_c: return _is_path_clear_on_board(from_r, from_c, to_r, to_c, b)
		5: if dr == 0 or dc == 0 or abs_r == abs_c: return _is_path_clear_on_board(from_r, from_c, to_r, to_c, b)
		2: if (abs_r == 2 and abs_c == 1) or (abs_r == 1 and abs_c == 2): return true
		6: if abs_r <= 1 and abs_c <= 1: return true
	return false

func _is_path_clear_on_board(from_r: int, from_c: int, to_r: int, to_c: int, b: Array) -> bool:
	var step_r = sign(to_r - from_r)
	var step_c = sign(to_c - from_c)
	var curr_r = from_r + step_r
	var curr_c = from_c + step_c
	
	while curr_r != to_r or curr_c != to_c:
		if b[curr_r][curr_c] != 0:
			return false
		curr_r += step_r
		curr_c += step_c
	return true

func is_move_valid(from_r: int, from_c: int, to_r: int, to_c: int) -> bool:
	if to_r < 0 or to_r > 7 or to_c < 0 or to_c > 7: return false
	if from_r == to_r and from_c == to_c: return false

	var piece = board_state[from_r][from_c]
	if piece == 0: return false
	
	var can_attack = _can_piece_attack_target(from_r, from_c, to_r, to_c, board_state)
	
	if not can_attack:
		if abs(piece) == 1 and to_c == from_c:
			var dr = to_r - from_r
			if piece > 0:
				if dr == -1 and board_state[to_r][to_c] == 0: pass
				elif dr == -2 and from_r == 6 and board_state[to_r][to_c] == 0 and board_state[5][from_c] == 0: pass
				else: return false
			else:
				if dr == 1 and board_state[to_r][to_c] == 0: pass
				elif dr == 2 and from_r == 1 and board_state[to_r][to_c] == 0 and board_state[2][from_c] == 0: pass
				else: return false
		else:
			return false

	var temp_board = []
	for r in range(8):
		temp_board.append(board_state[r].duplicate())

	temp_board[from_r][from_c] = 0
	temp_board[to_r][to_c] = piece

	var is_player = piece > 0
	if is_king_in_check(is_player, temp_board):
		return false

	return true

func _play_move_sound():
	if audio_player and audio_player.stream:
		audio_player.play()

func _play_glitch_sound():
	if glitch_audio_player and glitch_audio_player.stream:
		glitch_audio_player.play()
