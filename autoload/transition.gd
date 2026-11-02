extends CanvasLayer
## Transición con fundido a negro entre escenas. Uso: Transition.go_to(ruta).

const MENU_SCENE := "res://scenes/menus/main_menu.tscn"
const FRONTERA_SCENE := "res://world/regions/frontera/frontera.tscn"

var _rect: ColorRect
var _busy := false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0.0, 0.0, 0.0, 1.0)
	_rect.modulate.a = 0.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func go_to(path: String) -> void:
	if _busy:
		return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var fade_in := create_tween()
	fade_in.tween_property(_rect, "modulate:a", 1.0, 0.35)
	await fade_in.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var fade_out := create_tween()
	fade_out.tween_property(_rect, "modulate:a", 0.0, 0.4)
	await fade_out.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false

func reload() -> void:
	go_to(get_tree().current_scene.scene_file_path)
