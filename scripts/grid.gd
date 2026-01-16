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

# Container for tile mesh visuals
var _tile_meshes: Node3D


const TILE_COLORS: Dictionary = {
	Types.TileType.GRASS: Color(0.3, 0.6, 0.2),      # Green
	Types.TileType.PATH: Color(0.6, 0.5, 0.3),        # Tan/brown
	Types.TileType.CASTLE: Color(0.5, 0.5, 0.55),     # Grey
	Types.TileType.BLOCKED: Color(0.2, 0.2, 0.2),     # Dark grey
	Types.TileType.OCCUPIED: Color(0.2, 0.45, 0.15),  # Darker green
}


func _ready() -> void:
	_load_default_map()
	_render_tiles()


func _load_default_map() -> void:
	# MVP 15x15 map: grass border, paths from 3 sides to castle at center
	init_grid(15, 15)

	# Fill with grass (placeable)
	for x in range(width):
		for y in range(height):
			tiles[x][y] = Types.TileType.GRASS

	# Castle at center (7,7) - 3x3 area
	for x in range(6, 9):
		for y in range(6, 9):
			tiles[x][y] = Types.TileType.CASTLE

	# West path: (0,7) -> (6,7)
	for x in range(0, 7):
		tiles[x][7] = Types.TileType.PATH

	# East path: (14,7) -> (8,7)
	for x in range(8, 15):
		tiles[x][7] = Types.TileType.PATH

	# North path: (7,0) -> (7,6)
	for y in range(0, 7):
		tiles[7][y] = Types.TileType.PATH

	# Waypoints for each spawn point
	_path_waypoints = {
		0: [Vector3(0.5, 0, 7.5), Vector3(6.5, 0, 7.5), Vector3(7.5, 0, 7.5)],  # West -> Castle
		1: [Vector3(14.5, 0, 7.5), Vector3(8.5, 0, 7.5), Vector3(7.5, 0, 7.5)],  # East -> Castle
		2: [Vector3(7.5, 0, 0.5), Vector3(7.5, 0, 6.5), Vector3(7.5, 0, 7.5)],   # North -> Castle
	}


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


func _render_tiles() -> void:
	# Create container for tile meshes under parent World node
	var parent := get_parent()
	if parent == null:
		return

	_tile_meshes = Node3D.new()
	_tile_meshes.name = "TileMeshes"
	parent.add_child.call_deferred(_tile_meshes)

	# Create a plane mesh to reuse
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(cell_size * 0.98, cell_size * 0.98)

	# Spawn a MeshInstance3D for each tile
	for x in range(width):
		for y in range(height):
			var tile_type: Types.TileType = tiles[x][y]
			var mesh_instance := MeshInstance3D.new()
			mesh_instance.mesh = plane_mesh

			# Create material with tile color
			var material := StandardMaterial3D.new()
			material.albedo_color = TILE_COLORS.get(tile_type, Color.MAGENTA)
			mesh_instance.material_override = material

			# Position at tile center, slightly above ground to avoid z-fighting
			mesh_instance.position = Vector3(
				x * cell_size + cell_size / 2.0,
				0.01,
				y * cell_size + cell_size / 2.0
			)

			_tile_meshes.add_child(mesh_instance)
