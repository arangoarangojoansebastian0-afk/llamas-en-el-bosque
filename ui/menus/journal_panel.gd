class_name JournalPanel
extends OverlayPanel
## Diario de misiones: activas (con objetivos y progreso) y completadas.

func _init() -> void:
	title_text = "Diario de misiones"
	close_action = "journal"

func _build(box: VBoxContainer) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(520.0, 340.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(inner)
	var any := false
	for quest_id in Quests.ORDER:
		var id := str(quest_id)
		if not Quests.is_started(id):
			continue
		any = true
		var done := Quests.is_done(id)
		var title := Quests.get_title(id) + ("  (completada)" if done else "")
		inner.add_child(MenuStyle.label(title, 18, Color("a8d98f") if done else MenuStyle.ACCENT))
		if done:
			continue
		var summary := MenuStyle.label(Quests.get_summary(id), 13, Color(0.78, 0.76, 0.64, 1.0))
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		summary.custom_minimum_size = Vector2(480.0, 0.0)
		inner.add_child(summary)
		for objective in Quests.objectives(id):
			var mark := "[x] " if bool(objective["done"]) else "[ ] "
			var suffix := ""
			if int(objective["target"]) > 1:
				suffix = " (%d/%d)" % [int(objective["progress"]), int(objective["target"])]
			var line := MenuStyle.label(mark + str(objective["text"]) + suffix, 15, Color("a8d98f") if bool(objective["done"]) else MenuStyle.TEXT)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.custom_minimum_size = Vector2(480.0, 0.0)
			inner.add_child(line)
		inner.add_child(Control.new())
	if not any:
		inner.add_child(MenuStyle.label("Aún no tienes misiones.", 15))
