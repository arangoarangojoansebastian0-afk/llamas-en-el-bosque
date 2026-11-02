extends Node2D
## Escena de pruebas (F6): valida movimiento, resistencia, vida y zona de peligro.

var _label: Label

func _ready() -> void:
	GameState.reset()
	var player := Player.new()
	player.position = Vector2(200, 200)
	add_child(player)
	var hazard := HazardZone.new()
	hazard.position = Vector2(420, 200)
	add_child(hazard)
	var layer := CanvasLayer.new()
	_label = Label.new()
	_label.position = Vector2(12, 8)
	layer.add_child(_label)
	add_child(layer)
	GameState.player_died.connect(_on_died)

func _process(_delta: float) -> void:
	_label.text = "Vida %d   Resistencia %d   (WASD mover, Shift correr, R reiniciar)" % [GameState.health, GameState.stamina]
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 800, 400), Color("344a35"))

func _on_died() -> void:
	_label.text = "Has caído. Pulsa R para reiniciar."
