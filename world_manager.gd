extends Node
## Adaptador de compatibilidad. El autoload WorldManager es la única fuente de datos.

func get_regions() -> Dictionary:
	return WorldManager.get_regions()

func get_region_info(region_id: String) -> Dictionary:
	return WorldManager.get_region_info(region_id)

func get_region_bounds(region_id: String) -> Rect2:
	return WorldManager.get_region_bounds(region_id)

func get_player_position() -> Vector2:
	return WorldManager.get_player_position()

func get_player_region() -> String:
	return WorldManager.get_player_region()

func update_player_position(local_position: Vector2) -> void:
	WorldManager.update_player_position(GameState.current_region, local_position)

func set_player_region(region_id: String) -> void:
	WorldManager.set_player_region(region_id)

func is_location_discovered(location_id: String) -> bool:
	return WorldManager.is_location_discovered(location_id)

func discover_location(location_id: String) -> void:
	WorldManager.discover_location(location_id)

func get_map_markets() -> Array[Dictionary]:
	return WorldManager.get_map_markers()

func get_world_size() -> Vector2:
	return WorldManager.get_world_size()
