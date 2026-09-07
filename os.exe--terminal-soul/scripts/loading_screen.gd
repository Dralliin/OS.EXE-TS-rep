extends Control

@onready var progress_bar = $ProgressBar # Твой ProgressBar
@onready var vhs_overlay = $VHS_Overlay

const MAIN_OS_SCENE_PATH = "res://scenes/os.tscn"

func _ready():
	progress_bar.value = 0.0
	
	if vhs_overlay and vhs_overlay.material:
		vhs_overlay.material.set_shader_parameter("switch_on_pct", 0.0)
		var tween = create_tween()
		tween.tween_property(vhs_overlay.material, "shader_parameter/switch_on_pct", 1.0, 0.35)\
			.from(0.0)\
			.set_trans(Tween.TRANS_QUART)\
			.set_ease(Tween.EASE_OUT)
	
	start_loading_process()

func start_loading_process():
	var tween = create_tween()
	
	tween.tween_property(progress_bar, "value", 34.0, 1)
	tween.tween_interval(1.2)
	tween.tween_property(progress_bar, "value", 88.0, 0.4)
	tween.tween_interval(0.5)
	tween.tween_property(progress_bar, "value", 100.0, 0.3)
	
	await tween.finished
	
	await get_tree().create_timer(0.5).timeout
	
	if vhs_overlay and vhs_overlay.material:
		var collapse_tw = create_tween()
		collapse_tw.tween_property(vhs_overlay.material, "shader_parameter/switch_on_pct", 0.0, 0.25)\
			.set_trans(Tween.TRANS_QUART)\
			.set_ease(Tween.EASE_IN)
		await collapse_tw.finished
	
	if ResourceLoader.exists(MAIN_OS_SCENE_PATH):
		get_tree().change_scene_to_file(MAIN_OS_SCENE_PATH)
