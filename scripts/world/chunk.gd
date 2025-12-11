extends Node3D
## Terrain chunk with vegetation spawning using tree lifecycle distribution

const CHUNK_SIZE: float = 64.0
const BILLBOARD_SCENE = preload("res://scenes/world/billboard_sprite.tscn")

# Configurable cluster settings
const CLUSTERS_MIN: int = 2
const CLUSTERS_MAX: int = 5

# Tree lifecycle stages (innermost to outermost)
# Each entry: [texture, height_min, height_max, radius_min, radius_max, count_min, count_max]
const LIFECYCLE_STAGES = [
	# Stage 0: Adult Large (center parent tree)
	{"name": "adult_large", "height": [10.0, 14.0], "radius": [0.0, 0.0], "count": [1, 1]},
	# Stage 1: Adult Medium (close to parent)
	{"name": "adult_medium", "height": [7.0, 10.0], "radius": [3.0, 7.0], "count": [1, 3]},
	# Stage 2: Sapling Large (outermost for now)
	{"name": "sapling_large", "height": [4.0, 6.0], "radius": [6.0, 12.0], "count": [2, 5]},
]

var chunk_coord: Vector2i = Vector2i.ZERO
var _terrain_mesh: MeshInstance3D
var _vegetation: Array[Node3D] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Tree lifecycle textures (loaded once)
static var _textures: Dictionary = {}
static var _textures_loaded: bool = false

func _ready() -> void:
	_setup_terrain()
	_load_textures()

static func _load_textures() -> void:
	if _textures_loaded:
		return
	var base_path := "res://assets/textures/sprites/tree_type_A/"
	_textures["adult_large"] = load(base_path + "tree_adult_large.png")
	_textures["adult_medium"] = load(base_path + "tree_adult_medium.png")
	_textures["sapling_large"] = load(base_path + "tree_sapling_large.png")
	_textures["sapling_small"] = load(base_path + "tree_sapling_small.png")
	_textures["seedling"] = load(base_path + "tree_seedling.png")
	_textures_loaded = true

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
	material.set_shader_parameter("albedo_texture", load("res://assets/textures/terrain/grass_checkered.tga"))
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

	# Determine number of tree clusters for this chunk
	var cluster_count := _rng.randi_range(CLUSTERS_MIN, CLUSTERS_MAX)
	var half_size := CHUNK_SIZE / 2.0 - 5.0  # Margin for cluster spread

	# Spawn each cluster
	for _c in cluster_count:
		# Random cluster center position
		var cluster_center := Vector2(
			_rng.randf_range(-half_size, half_size),
			_rng.randf_range(-half_size, half_size)
		)
		_spawn_tree_cluster(cluster_center)

func _spawn_tree_cluster(center: Vector2) -> void:
	# Spawn trees for each lifecycle stage radiating outward
	for stage in LIFECYCLE_STAGES:
		var tex: Texture2D = _textures[stage["name"]]
		var height_range: Array = stage["height"]
		var radius_range: Array = stage["radius"]
		var count_range: Array = stage["count"]

		var tree_count := _rng.randi_range(count_range[0], count_range[1])

		for _i in tree_count:
			# Random angle for radial distribution
			var angle := _rng.randf() * TAU
			# Random radius within stage's range (with some scatter)
			var radius := _rng.randf_range(radius_range[0], radius_range[1])
			# Add natural scatter/jitter
			radius += _rng.randf_range(-1.5, 1.5)
			radius = max(0.0, radius)

			# Calculate position
			var offset := Vector2(cos(angle), sin(angle)) * radius
			var pos := center + offset

			# Random height within stage's range
			var height := _rng.randf_range(height_range[0], height_range[1])

			_spawn_billboard_at(tex, height, Vector3(pos.x, 0, pos.y))

func _spawn_billboard_at(tex: Texture2D, height: float, pos: Vector3) -> void:
	var billboard: Node3D = BILLBOARD_SCENE.instantiate()
	add_child(billboard)

	# Y position: half the height (quad is centered, so offset to sit on ground)
	pos.y = height * 0.5

	billboard.position = pos
	billboard.set_texture(tex)
	billboard.set_scale_factor(height)

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
