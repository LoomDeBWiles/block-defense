## Manages map tiles and validates tower placement positions
## Grid is data, GridMap is visuals
class_name Grid
extends Node

var width: int = 15
var height: int = 15
var cell_size: float = 1.0
var tiles: Array[Array] = []

# Pre-defined waypoints per spawn point (0=west, 1=east, 2=north)
var _path_waypoints: Dictionary = {}


func init_grid(w: int, h: int) -> void:
	width = w
	height = h
	tiles.clear()
	for x in range(width):
		var column: Array[Types.TileType] = []
		column.resize(height)
		column.fill(Types.TileType.BLOCKED)
		tiles.append(column)


func load_map(map_data: Dictionary) -> void:
	var w: int = map_data.get("width", 15)
	var h: int = map_data.get("height", 15)
	init_grid(w, h)

	var flat_tiles: Array = map_data.get("tiles", [])
	for i in range(flat_tiles.size()):
		var x: int = i % width
		var y: int = i / width
		if x < width and y < height:
			tiles[x][y] = flat_tiles[i] as Types.TileType

	# Load pre-defined waypoints
	_path_waypoints = map_data.get("waypoints", {})


func get_tile(pos: Vector2i) -> Types.TileType:
	if pos.x < 0 or pos.x >= width or pos.y < 0 or pos.y >= height:
		return Types.TileType.BLOCKED
	return tiles[pos.x][pos.y]


func can_place(pos: Vector2i) -> bool:
	return get_tile(pos) == Types.TileType.GRASS


func mark_occupied(pos: Vector2i) -> void:
	if pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height:
		tiles[pos.x][pos.y] = Types.TileType.OCCUPIED


func clear_occupied(pos: Vector2i) -> void:
	if pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height:
		tiles[pos.x][pos.y] = Types.TileType.GRASS


func grid_to_world(pos: Vector2i) -> Vector3:
	return Vector3(
		pos.x * cell_size + cell_size / 2.0,
		0.0,
		pos.y * cell_size + cell_size / 2.0
	)


func world_to_grid(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / cell_size)),
		int(floor(world_pos.z / cell_size))
	)


func get_path_waypoints(spawn_id: int) -> Array[Vector3]:
	var waypoints: Array[Vector3] = []
	var raw: Array = _path_waypoints.get(spawn_id, [])
	for wp in raw:
		if wp is Vector3:
			waypoints.append(wp)
		elif wp is Array and wp.size() >= 3:
			waypoints.append(Vector3(wp[0], wp[1], wp[2]))
	return waypoints
