class_name HazardZone
extends Area2D
## Zona peligrosa genérica (base para el sistema de fuego). Daña al jugador mientras permanece dentro.

@export var damage_per_second := 12.0
@export var size := Vector2(96.0, 96.0)

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	add_child(shape)

func _physics_process(delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is Player:
			GameState.damage(damage_per_second * delta)

func _draw() -> void:
	draw_rect(Rect2(-size * 0.5, size), Color(0.85, 0.3, 0.1, 0.45))
