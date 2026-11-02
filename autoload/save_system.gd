extends Node
## Guardado de progreso en user://save.json (un único punto de control).

const PATH := "user://save.json"

## Si es true, la región carga el guardado al iniciar en lugar de empezar de cero.
var pending_load := false

func has_save() -> bool:
	return FileAccess.file_exists(PATH)

func write(data: Dictionary) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))

func read() -> Dictionary:
	if not has_save():
		return {}
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}
