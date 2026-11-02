extends TextureRect
## Minimapa del mundo conectado al autoload WorldManager.

const MINIMAP_SIZE := Vector2i(200, 150)
const MARKER_SIZE := Vector2(7.0, 7.0)

@onready var _player_marker := get_node_or_null("PlayerMarker") as ColorRect
@onready var _location_markers := get_node_or_null("LocationMarkers") as Control
@onready var _region_markers := get_node_or_null("RegionMarkers") as Control
@onready var _minimap_texture := get_node_or_null("MinimapTexture") as TextureRect

var _world_manager: Node
var _terrain_texture: ImageTexture


func _ready() -> void:
	_world_manager = WorldManager
	custom_minimum_size = Vector2(MINIMAP_SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color(1.0, 1.0, 1.0, 0.94)

	if _player_marker == null or _location_markers == null or _region_markers == null or _minimap_texture == null:
		push_error("Minimap: falta uno o más nodos requeridos en scenes/minimap.tscn.")
		return

	_world_manager.regions_changed.connect(_refresh_map)
	_world_manager.location_discovered.connect(_on_location_discovered)
	_world_manager.player_position_updated.connect(_on_player_position_updated)
	_refresh_map()


func _refresh_map() -> void:
	if not is_instance_valid(_world_manager):
		return
	_draw_minimap_terrain()
	_create_region_markers()
	_update_location_markers()
	_update_player_marker()


func _draw_minimap_terrain() -> void:
	var image := Image.create(MINIMAP_SIZE.x, MINIMAP_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color("17211b"))
	var regions: Dictionary = _world_manager.get_regions()

	for region_id in _world_manager.get_region_ids():
		var region: Dictionary = regions[region_id]
		var world_rect: Rect2 = _world_manager.get_region_bounds(region_id)
		var top_left := _world_to_minimap(world_rect.position)
		var bottom_right := _world_to_minimap(world_rect.end)
		var start_x := clampi(floori(top_left.x), 0, MINIMAP_SIZE.x)
		var start_y := clampi(floori(top_left.y), 0, MINIMAP_SIZE.y)
		var end_x := clampi(ceili(bottom_right.x), 0, MINIMAP_SIZE.x)
		var end_y := clampi(ceili(bottom_right.y), 0, MINIMAP_SIZE.y)
		if end_x <= start_x or end_y <= start_y:
			continue

		var color: Color = region.get("map_color", Color("50634b"))
		if not _world_manager.is_discovered(region_id):
			color = Color(color.r * 0.27, color.g * 0.28, color.b * 0.28, 1.0)
		for y in range(start_y, end_y):
			for x in range(start_x, end_x):
				image.set_pixel(x, y, color)

	_terrain_texture = ImageTexture.create_from_image(image)
	_minimap_texture.texture = _terrain_texture


func _create_region_markers() -> void:
	for child in _region_markers.get_children():
		_region_markers.remove_child(child)
		child.queue_free()

	for region_id in _world_manager.get_region_ids():
		var region_rect: Rect2 = _world_manager.get_region_bounds(region_id)
		var marker := ColorRect.new()
		marker.name = "RegionMarker_" + region_id
		marker.size = Vector2(4.0, 4.0)
		var color: Color = _world_manager.get_region_info(region_id).get("map_color", Color.WHITE)
		color.a = 1.0 if _world_manager.is_discovered(region_id) else 0.48
		marker.color = color
		marker.position = _world_to_minimap(region_rect.get_center()) - marker.size * 0.5
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_region_markers.add_child(marker)


func _update_location_markers() -> void:
	for child in _location_markers.get_children():
		_location_markers.remove_child(child)
		child.queue_free()

	for marker_data in _world_manager.get_map_markers():
		if not bool(marker_data.get("discovered", false)) or not bool(marker_data.get("region_discovered", false)):
			continue
		var marker := ColorRect.new()
		marker.name = "LocationMarker_" + str(marker_data.get("id", "unknown"))
		marker.size = MARKER_SIZE
		marker.color = _get_marker_color(marker_data)
		marker.position = _world_to_minimap(marker_data.get("global_position", Vector2.ZERO)) - marker.size * 0.5
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_location_markers.add_child(marker)


func _get_marker_color(marker_data: Dictionary) -> Color:
	if bool(marker_data.get("active_quest", false)):
		return Color("f0bd5e")
	match str(marker_data.get("type", "")):
		"spawn", "safe_zone":
			return Color("88ce8d")
		"resource":
			return Color("71c9df")
		"fire_zone":
			return Color("ed7250")
		"entrance", "exit":
			return Color("f2d176")
		"town_center":
			return Color("d98bd8")
		"npc":
			return Color("e3d4aa")
		"clue":
			return Color("ec9b61")
		"animal":
			return Color("9bd38d")
		_:
			return Color("e1dfce")


func _update_player_marker() -> void:
	if not _world_manager.has_player_position():
		_player_marker.visible = false
		return
	_player_marker.visible = true
	_player_marker.position = _world_to_minimap(_world_manager.get_player_position()) - _player_marker.size * 0.5


func _world_to_minimap(world_position: Vector2) -> Vector2:
	var bounds: Rect2 = _world_manager.get_world_bounds()
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return Vector2.ZERO
	var scale := minf(float(MINIMAP_SIZE.x) / bounds.size.x, float(MINIMAP_SIZE.y) / bounds.size.y)
	var drawn_size := bounds.size * scale
	var padding := (Vector2(MINIMAP_SIZE) - drawn_size) * 0.5
	return padding + (world_position - bounds.position) * scale


func _on_player_position_updated(_global_position: Vector2, _region_id: String) -> void:
	_update_player_marker()

func _on_location_discovered(_location_id: String) -> void:
	_refresh_map()

func get_world_size() -> Vector2:
	return _world_manager.get_world_size()


func get_regions() -> Dictionary:
	return _world_manager.get_regions()
