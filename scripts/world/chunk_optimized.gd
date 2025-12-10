extends Node3D
## Optimized terrain chunk using MultiMesh for vegetation

const CHUNK_SIZE: float = 64.0

var chunk_coord: Vector2i = Vector2i.ZERO
var _terrain_mesh: MeshInstance3D
var _tree_multimesh: MultiMeshInstance3D
var _bush_multimesh: MultiMeshInstance3D
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Shared resources (loaded once)
static var _tree_texture: Texture2D
static var _bush_texture: Texture2D
static var _tree_material: ShaderMaterial
static var _bush_material: ShaderMaterial
static var _terrain_material: ShaderMaterial
static var _resources_loaded: bool = false

func _ready() -> void:
	_load_resources()
	_setup_terrain()
	_setup_multimeshes()

static func _load_resources() -> void:
	if _resources_loaded:
		return

	_tree_texture = load("res://assets/textures/sprites/tree_placeholder.png")
	_bush_texture = load("res://assets/textures/sprites/bush_placeholder.png")

	# Create shared materials
	var shader := load("res://shaders/billboard_y.gdshader")

	_tree_material = ShaderMaterial.new()
	_tree_material.shader = shader
	_tree_material.set_shader_parameter("albedo_texture", _tree_texture)

	_bush_material = ShaderMaterial.new()
	_bush_material.shader = shader
	_bush_material.set_shader_parameter("albedo_texture", _bush_texture)

	_terrain_material = ShaderMaterial.new()
	_terrain_material.shader = load("res://shaders/unlit_terrain.gdshader")
	_terrain_material.set_shader_parameter("albedo_texture", load("res://assets/textures/terrain/grass_placeholder.png"))
	_terrain_material.set_shader_parameter("uv_scale", 8.0)

	_resources_loaded = true

func _setup_terrain() -> void:
	_terrain_mesh = MeshInstance3D.new()
	add_child(_terrain_mesh)

	var plane := PlaneMesh.new()
	plane.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
	plane.subdivide_width = 0
	plane.subdivide_depth = 0
	_terrain_mesh.mesh = plane
	_terrain_mesh.material_override = _terrain_material

func _setup_multimeshes() -> void:
	# Tree MultiMesh
	_tree_multimesh = MultiMeshInstance3D.new()
	add_child(_tree_multimesh)

	var tree_mm := MultiMesh.new()
	tree_mm.transform_format = MultiMesh.TRANSFORM_3D
	tree_mm.mesh = _create_quad_mesh(Vector2(4.0, 8.0))  # Tree size
	_tree_multimesh.multimesh = tree_mm
	_tree_multimesh.material_override = _tree_material

	# Bush MultiMesh
	_bush_multimesh = MultiMeshInstance3D.new()
	add_child(_bush_multimesh)

	var bush_mm := MultiMesh.new()
	bush_mm.transform_format = MultiMesh.TRANSFORM_3D
	bush_mm.mesh = _create_quad_mesh(Vector2(2.0, 1.0))  # Bush size
	_bush_multimesh.multimesh = bush_mm
	_bush_multimesh.material_override = _bush_material

func _create_quad_mesh(size: Vector2) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = size
	quad.orientation = PlaneMesh.FACE_Z
	quad.center_offset = Vector3(0, size.y / 2.0, 0)  # Bottom-centered
	return quad

func initialize(coord: Vector2i) -> void:
	chunk_coord = coord
	position = Vector3(coord.x * CHUNK_SIZE, 0, coord.y * CHUNK_SIZE)

	# Seed RNG based on chunk coordinate for deterministic spawning
	_rng.seed = hash(coord)

	_spawn_vegetation()

func _spawn_vegetation() -> void:
	var half_size := CHUNK_SIZE / 2.0 - 2.0

	# Spawn trees
	var tree_count := _rng.randi_range(3, 8)
	_tree_multimesh.multimesh.instance_count = tree_count

	for i in tree_count:
		var x := _rng.randf_range(-half_size, half_size)
		var z := _rng.randf_range(-half_size, half_size)
		var scale := _rng.randf_range(0.8, 1.2)

		var transform := Transform3D()
		transform = transform.scaled(Vector3(scale, scale, scale))
		transform.origin = Vector3(x, 0, z)
		_tree_multimesh.multimesh.set_instance_transform(i, transform)

	# Spawn bushes
	var bush_count := _rng.randi_range(8, 15)
	_bush_multimesh.multimesh.instance_count = bush_count

	for i in bush_count:
		var x := _rng.randf_range(-half_size, half_size)
		var z := _rng.randf_range(-half_size, half_size)
		var scale := _rng.randf_range(0.8, 1.5)

		var transform := Transform3D()
		transform = transform.scaled(Vector3(scale, scale, scale))
		transform.origin = Vector3(x, 0, z)
		_bush_multimesh.multimesh.set_instance_transform(i, transform)

func activate() -> void:
	show()
	set_process(true)

func deactivate() -> void:
	hide()
	set_process(false)
	# Clear vegetation by setting instance count to 0
	if _tree_multimesh and _tree_multimesh.multimesh:
		_tree_multimesh.multimesh.instance_count = 0
	if _bush_multimesh and _bush_multimesh.multimesh:
		_bush_multimesh.multimesh.instance_count = 0

func get_chunk_coord() -> Vector2i:
	return chunk_coord
