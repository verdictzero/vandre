extends Node3D
## Manages terrain chunk loading/unloading based on player position

const CHUNK_SIZE: float = 64.0
const VIEW_DISTANCE: int = 2  # 5x5 grid = 25 chunks (1.5x increased)

const ChunkScript = preload("res://scripts/world/chunk.gd")
const BiomeManagerScript = preload("res://scripts/world/biome_manager.gd")

var player: Node3D
var _active_chunks: Dictionary = {}  # Vector2i -> Node3D
var _chunk_pool: Array[Node3D] = []
var _last_player_chunk: Vector2i = Vector2i(999999, 999999)  # Invalid initial value
var _biome_manager: BiomeManager

func _ready() -> void:
	# Create biome manager
	_biome_manager = BiomeManager.new()
	_biome_manager.set_script(BiomeManagerScript)
	add_child(_biome_manager)

	# Pre-create some chunks for the pool
	for i in range(25):
		var chunk := _create_new_chunk()
		chunk.hide()
		_chunk_pool.append(chunk)

func set_player(p: Node3D) -> void:
	player = p
	# Force initial chunk update
	_last_player_chunk = Vector2i(999999, 999999)

func _process(_delta: float) -> void:
	if not player:
		return

	var current_chunk := world_to_chunk(player.global_position)

	# Only update if player moved to a different chunk
	if current_chunk != _last_player_chunk:
		_last_player_chunk = current_chunk
		_update_chunks(current_chunk)

func world_to_chunk(pos: Vector3) -> Vector2i:
	return Vector2i(
		floori(pos.x / CHUNK_SIZE + 0.5),
		floori(pos.z / CHUNK_SIZE + 0.5)
	)

func _update_chunks(center: Vector2i) -> void:
	# Determine which chunks should be active
	var needed_coords: Array[Vector2i] = []
	for x in range(-VIEW_DISTANCE, VIEW_DISTANCE + 1):
		for z in range(-VIEW_DISTANCE, VIEW_DISTANCE + 1):
			needed_coords.append(Vector2i(center.x + x, center.y + z))

	# Deactivate chunks that are no longer needed
	var to_remove: Array[Vector2i] = []
	for coord in _active_chunks:
		if coord not in needed_coords:
			to_remove.append(coord)

	for coord in to_remove:
		var chunk: Node3D = _active_chunks[coord]
		chunk.deactivate()
		_chunk_pool.append(chunk)
		_active_chunks.erase(coord)

	# Activate chunks that are needed
	for coord in needed_coords:
		if coord not in _active_chunks:
			var chunk := _get_or_create_chunk()
			chunk.set_biome_manager(_biome_manager)
			chunk.initialize(coord)
			chunk.activate()
			_active_chunks[coord] = chunk

func _get_or_create_chunk() -> Node3D:
	if _chunk_pool.size() > 0:
		return _chunk_pool.pop_back()
	return _create_new_chunk()

func _create_new_chunk() -> Node3D:
	var chunk := Node3D.new()
	chunk.set_script(ChunkScript)
	add_child(chunk)
	return chunk

func get_active_chunk_count() -> int:
	return _active_chunks.size()

func get_player_chunk_coord() -> Vector2i:
	return _last_player_chunk

func get_biome_manager() -> BiomeManager:
	return _biome_manager
