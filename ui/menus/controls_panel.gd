class_name ControlsPanel
extends OverlayPanel
## Instrucciones: lista de controles del juego.

const ROWS: Array = [
	["W A S D / Flechas", "Moverse"],
	["Shift", "Correr (gasta resistencia)"],
	["E", "Interactuar: recoger, rellenar agua, plantar"],
	["Espacio", "Lanzar agua al fuego / observar el entorno"],
	["J", "Diario de misiones"],
	["I", "Inventario y habilidades"],
	["ESC", "Pausa"],
]

func _init() -> void:
	title_text = "Controles"

func _build(box: VBoxContainer) -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 32)
	grid.add_theme_constant_override("v_separation", 10)
	box.add_child(grid)
	for row in ROWS:
		var keys: String = row[0]
		var action: String = row[1]
		grid.add_child(MenuStyle.label(keys, 16, MenuStyle.ACCENT))
		grid.add_child(MenuStyle.label(action, 16))
	var note := MenuStyle.label("Ante un incendio real, aléjate y avisa a emergencias. Apagar focos en el juego es una mecánica ficticia.", 13, Color(0.7, 0.75, 0.62, 1.0))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(500.0, 0.0)
	box.add_child(note)
