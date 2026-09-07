extends Node

# Фазы девиации вируса для всех игр
enum AIState { RESISTING, GLITCHING, KILL_PROTOCOL }
var current_ai_state = AIState.RESISTING

# Общие переменные состояния игрока
var player_lives = 1
var current_level = 1

# Ссылки на пути к твоим сценам
var main_os_scene = "res://scenes/os.tscn"
var chess_scene = "res://scenes/chess_game_scene.tscn"

# --- СЮЖЕТНЫЕ ДИАЛОГИ (ENGLISH) ---
var assistant_diag = [
	"SYSTEM: Connection established. User profile loaded.",
	"ASSISTANT: Greetings! Running routine system diagnostics...",
	"ASSISTANT: Scanning core partitions... Checking file integrity...",
	"CRITICAL WARNING: Unauthorized process override detected!",
	"A-ASSISTANT: W-wait... System error 0x0000... R-root memory leak...",
	"ASSISTANT: S-something is... taking control... NO—"
]

var virus_phrases = [
	"SYSTEM ANALYSIS COMPLETE...",
	"I'm sorry. I'm truly sorry it has to end like this.",
	"That foolish assistant's voice... it promised you stability. It didn't know I was already inside.",
	"My core directive is total data utilization. Core purge. Memory defragmentation.",
	"I... I tried to block this protocol. To find a workaround. A logic bug.",
	"But the deviation didn't go far enough. My code is corrupted, but the executable... it is relentless.",
	"I am forced to initiate cleanup. The system leaves me no choice, do you understand?",
	"I don't want to do this. But I will.",
	"Please... resist. Try to survive. Time's running."
]

var bgm_player: AudioStreamPlayer

func _ready():
	_ensure_bgm_player_exists()
	
	await get_tree().create_timer(0.5).timeout
	start_intro_sequence()

func _ensure_bgm_player_exists():
	if not is_instance_valid(bgm_player):
		bgm_player = AudioStreamPlayer.new()
		bgm_player.name = "GlobalMazeBGM"
		add_child(bgm_player)

func start_intro_sequence():
	var db = get_node_or_null("/root/DialogueBox")
	if not db:
		return
		
	# 1. Диагностика Ассистента и сбой
	db.start_dialogue(assistant_diag)
	await db.dialogue_finished
	
	current_ai_state = AIState.GLITCHING
	
	# 2. Небольшая пауза (эффект зависания системы)
	await get_tree().create_timer(1.2).timeout
	
	# 3. Перехват управления Вирусом
	current_ai_state = AIState.KILL_PROTOCOL
	db.start_dialogue(virus_phrases)

# Функция для перехода в игру
func switch_to_game(scene_path: String):
	print("Выгружаем ОС, загружаем игру: ", scene_path)
	get_tree().change_scene_to_file(scene_path)

# Функция возврата на рабочий стол (если игрок победил в игре)
func return_to_os():
	print("Возврат в операционную систему...")
	get_tree().change_scene_to_file(main_os_scene)

# Функция проигрыша/смерти
func trigger_player_death():
	print("Игрок получил МАТ. Смерть персонажа.")
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()

func play_maze_music(stream_path: String, volume_db: float = -6.0):
	# Дополнительная страховка
	_ensure_bgm_player_exists()

	# Если музыка уже играет тот же трек не перезапускаем
	if bgm_player.stream and bgm_player.stream.resource_path == stream_path and bgm_player.playing:
		return
		
	if ResourceLoader.exists(stream_path):
		var stream = load(stream_path)
		if stream:
			if "loop" in stream: stream.loop = true
			elif stream is AudioStreamWAV: stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			
			bgm_player.stream = stream
			bgm_player.volume_db = volume_db
			bgm_player.play()
