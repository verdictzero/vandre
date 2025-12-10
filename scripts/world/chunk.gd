extends Node3D
## Terrain chunk with vegetation spawning

const CHUNK_SIZE: float = 64.0
const BILLBOARD_SCENE = preload("res://scenes/world/billboard_sprite.tscn")

var chunk_coord: Vector2i = Vector2i.ZERO
var _terrain_mesh: MeshInstance3D
var _vegetation: Array[Node3D] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Vegetation textures (loaded once)
static var tree_texture: Texture2D
static var bush_texture: Texture2D

func _ready() -> void:
	_setup_terrain()
	_load_textures()

static func _load_textures() -> void:
	if not tree_texture:
		tree_texture = load("res://assets/textures/sprites/tree_placeholder.png")
	if not bush_texture:
		bush_texture = load("res://assets/textures/sprites/bush_placeholder.png")

func _setup_terrain() -> void:
	_terrain_mesh = MeshInstance3D.new()
	add_child(_terrain_mesh)

	# Create plane mesh
	var plane := PlaneMesh.new()
	plane.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
	plane.subdivide_width = 0
	plane.subdivide_depth = 0
	_terrain_mesh.mesh = plane

	# Create material
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/unlit_terrain.gdshader")
	material.set_shader_parameter("albedo_texture", load("res://assets/textures/terrain/grass_placeholder.png"))
	material.set_shader_parameter("uv_scale", 8.0)
	_terrain_mesh.material_override = material

func initialize(coord: Vector2i) -> void:
	chunk_coord = coord

	# Position chunk in world space
	position = Vector3(coord.x * CHUNK_SIZE, 0, coord.y * CHUNK_SIZE)

	# Seed RNG based on chunk coordinate for deterministic spawning
	_rng.seed = hash(coord)

	# Spawn vegetation
	_spawn_vegetation()

func _spawn_vegetation() -> void:
	_load_textures()

	# Spawn trees (sparse)
	var tree_count := _rng.randi_range(3, 8)
	for i in tree_count:
		_spawn_billboard(tree_texture, _rng.randf_range(2.0, 4.0), true)

	# Spawn bushes (medium density)
	var bush_count := _rng.randi_range(8, 15)
	for i in bush_count:
		_spawn_billboard(bush_texture, _rng.randf_range(0.8, 1.5), false)

func _spawn_billboard(tex: Texture2D, scale_factor: float, is_tree: bool) -> void:
	var billboard: Node3D = BILLBOARD_SCENE.instantiate()
	add_child(billboard)

	# Random position within chunk bounds
	var half_size := CHUNK_SIZE / 2.0 - 2.0  # Slight margin
	var x := _rng.randf_range(-half_size, half_size)
	var z := _rng.randf_range(-half_size, half_size)

	# Y position based on type (trees are taller)
	var y := scale_factor if is_tree else scale_factor * 0.5

	billboard.position = Vector3(x, y, z)
	billboard.set_texture(tex)
	billboard.set_scale_factor(scale_factor)

	_vegetation.append(billboard)

func activate() -> void:
	show()
	set_process(true)

func deactivate() -> void:
	hide()
	set_process(false)
	_clear_vegetation()

func _clear_vegetation() -> void:
	for veg in _vegetation:
		if is_instance_valid(veg):
			veg.queue_free()
	_vegetation.clear()

func get_chunk_coord() -> Vector2i:
	return chunk_coord
