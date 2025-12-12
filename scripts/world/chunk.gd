extends Node3D
## Terrain chunk with vegetation spawning using tight cluster distribution

const CHUNK_SIZE: float = 64.0
const BILLBOARD_SCENE = preload("res://scenes/world/billboard_sprite.tscn")

# Configurable cluster settings
const CLUSTERS_MIN: int = 3
const CLUSTERS_MAX: int = 6
const SPAWN_CLEAR_RADIUS: float = 20.0  # Treeless area around world origin

# Size randomness factor (25% = 0.25)
const SIZE_VARIANCE: float = 0.25

# Foliage rings (innermost to outermost) - tight clusters
# collision_radius is the cylinder collider radius for blocking player
const FOLIAGE_RINGS = [
	# Ring 0: Biggest tree (center) - 2x size, huge collider
	{"name": "adult_large", "height": [24.0, 28.0], "radius": [0.0, 1.0], "count": [1, 1], "collision_radius": 8.0},
	# Ring 1: Large trees (first ring) - 2x size, huge collider
	{"name": "adult_medium", "height": [16.0, 20.0], "radius": [3.0, 6.0], "count": [1, 3], "collision_radius": 6.0},
	# Ring 2: Medium trees (second ring) - 2x size, huge collider
	{"name": "sapling_large", "height": [10.0, 14.0], "radius": [6.0, 10.0], "count": [2, 5], "collision_radius": 5.0},
	# Ring 3: Bushes (outer ring) - no collider (passable), high density, varied size
	{"name": "bush_a", "height": [1.0, 2.0], "radius": [8.0, 18.0], "count": [10, 20], "collision_radius": 0.0},
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
	var base_path := "res://assets/textures/sprites/foliage/genocide_meadows/"
	# Trees
	_textures["adult_large"] = load(base_path + "tree_really_big.tga")
	_textures["adult_medium"] = load(base_path + "tree_big.tga")
	_textures["sapling_large"] = load(base_path + "tree_medium.tga")
	# Bushes
	_textures["bush_a"] = load(base_path + "bush_var_A.tga")
	_textures["bush_b"] = load(base_path + "bush_var_B.tga")
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
	material.set_shader_parameter("albedo_texture", load("res://assets/textures/terrain/grass_checkered.png"))
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
		_spawn_foliage_cluster(cluster_center)

func _spawn_foliage_cluster(center: Vector2) -> void:
	# Spawn foliage for each ring radiating outward
	for ring in FOLIAGE_RINGS:
		var tex_name: String = ring["name"]
		# Randomly select bush variant
		if tex_name == "bush_a":
			tex_name = "bush_a" if _rng.randf() < 0.5 else "bush_b"
		var tex: Texture2D = _textures[tex_name]
		var height_range: Array = ring["height"]
		var radius_range: Array = ring["radius"]
		var count_range: Array = ring["count"]
		var collision_radius: float = ring["collision_radius"]

		var foliage_count := _rng.randi_range(count_range[0], count_range[1])

		for _i in foliage_count:
			# Random angle for radial distribution
			var angle := _rng.randf() * TAU
			# Random radius within ring's range (tight, minimal scatter)
			var radius := _rng.randf_range(radius_range[0], radius_range[1])

			# Calculate position
			var offset := Vector2(cos(angle), sin(angle)) * radius
			var pos := center + offset

			# Base height with 25% randomness
			var base_height := _rng.randf_range(height_range[0], height_range[1])
			var scale_factor := 1.0 + _rng.randf_range(-SIZE_VARIANCE, SIZE_VARIANCE)
			var final_height := base_height * scale_factor

			# Scale collision radius proportionally
			var final_collision_radius := collision_radius * scale_factor

			_spawn_billboard_at(tex, final_height, Vector3(pos.x, 0, pos.y), final_collision_radius)

func _spawn_billboard_at(tex: Texture2D, height: float, pos: Vector3, collision_radius: float) -> void:
	# Check if too close to world origin (player spawn)
	var world_pos := position + pos
	if Vector2(world_pos.x, world_pos.z).length() < SPAWN_CLEAR_RADIUS:
		return

	var billboard: Node3D = BILLBOARD_SCENE.instantiate()
	add_child(billboard)

	billboard.position = pos
	billboard.set_texture(tex)
	billboard.set_scale_factor(height)

	# Add capsule collider for player blocking (skip if radius is 0)
	if collision_radius > 0.0:
		var static_body := StaticBody3D.new()
		var collision_shape := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = collision_radius
		capsule.height = height
		collision_shape.shape = capsule
		# Position collider so it sits on ground (center at half height)
		collision_shape.position.y = height * 0.5
		static_body.add_child(collision_shape)
		billboard.add_child(static_body)

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
