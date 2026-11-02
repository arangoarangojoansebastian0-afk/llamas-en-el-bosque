class_name CreditsPanel
extends OverlayPanel
## Créditos de la beta.

func _init() -> void:
	title_text = "Créditos"

func _build(box: VBoxContainer) -> void:
	var lines: Array[String] = [
		"Llamas en el Bosque — Beta",
		"Aventura educativa sobre prevención de incendios forestales.",
		"Motor: Godot Engine 4.7 · Lenguaje: GDScript",
		"Arte, sonido y código generados para este proyecto.",
		"Ante un incendio real: aléjate y llama a emergencias.",
	]
	for line in lines:
		var item := MenuStyle.label(line, 16)
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item.custom_minimum_size = Vector2(500.0, 0.0)
		box.add_child(item)
