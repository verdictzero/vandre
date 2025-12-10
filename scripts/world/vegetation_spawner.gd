class_name VegetationSpawner
extends RefCounted
## Static utility class for spawning vegetation in chunks

const BILLBOARD_SCENE = preload("res://scenes/world/billboard_sprite.tscn")

# Cached textures
static var _tree_texture: Texture2D
static var _bush_texture: Texture2D
static var _textures_loaded: bool = false

static func _ensure_textures_loaded() -> void:
	if _textures_loaded:
		return
	_tree_texture = load("res://assets/textures/sprites/tree_placeholder.png")
	_bush_texture = load("res://assets/textures/sprites/bush_placeholder.png")
	_textures_loaded = true

## Spawn vegetation in a chunk and return array of spawned nodes
static func spawn_vegetation(parent: Node3D, coord: Vector2i, chunk_size: float) -> Array[Node3D]:
	_ensure_textures_loaded()

	var spawned: Array[Node3D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(coord)

	var half_size := chunk_size / 2.0 - 2.0

	# Spawn trees (sparse)
	var tree_count := rng.randi_range(3, 8)
	for i in tree_count:
		var billboard: Node3D = _spawn_single(
			parent,
			_tree_texture,
			rng.randf_range(2.0, 4.0),
			Vector3(
				rng.randf_range(-half_size, half_size),
				0,
				rng.randf_range(-half_size, half_size)
			),
			true
		)
		spawned.append(billboard)

	# Spawn bushes (medium density)
	var bush_count := rng.randi_range(8, 15)
	for i in bush_count:
		var billboard: Node3D = _spawn_single(
			parent,
			_bush_texture,
			rng.randf_range(0.8, 1.5),
			Vector3(
				rng.randf_range(-half_size, half_size),
				0,
				rng.randf_range(-half_size, half_size)
			),
			false
		)
		spawned.append(billboard)

	return spawned

static func _spawn_single(parent: Node3D, tex: Texture2D, scale_factor: float, pos: Vector3, is_tree: bool) -> Node3D:
	var billboard: Node3D = BILLBOARD_SCENE.instantiate()
	parent.add_child(billboard)

	# Adjust Y based on type
	pos.y = scale_factor if is_tree else scale_factor * 0.5
	billboard.position = pos

	billboard.set_texture(tex)
	billboard.set_scale_factor(scale_factor)

	return billboard

## Clear all vegetation nodes from array
static func clear_vegetation(vegetation: Array[Node3D]) -> void:
	for veg in vegetation:
		if is_instance_valid(veg):
			veg.queue_free()
	vegetation.clear()
