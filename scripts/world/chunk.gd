extends Node3D
## Terrain chunk with vegetation spawning based on biome configuration

const CHUNK_SIZE: float = 64.0
const BILLBOARD_SCENE = preload("res://scenes/world/billboard_sprite.tscn")

var chunk_coord: Vector2i = Vector2i.ZERO
var _terrain_mesh: MeshInstance3D
var _vegetation: Array[Node3D] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _biome: BiomeData
var _biome_manager: BiomeManager

func _ready() -> void:
	_setup_terrain()

func set_biome_manager(manager: BiomeManager) -> void:
	_biome_manager = manager

func _setup_terrain() -> void:
	_terrain_mesh = MeshInstance3D.new()
	add_child(_terrain_mesh)

	# Create plane mesh
	var plane := PlaneMesh.new()
	plane.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
	plane.subdivide_width = 0
	plane.subdivide_depth = 0
	_terrain_mesh.mesh = plane

func _apply_biome_terrain() -> void:
	if not _biome or not _biome_manager:
		return

	# Create material with biome's ground texture
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/unlit_terrain.gdshader")

	var ground_tex := _biome_manager.get_texture(_biome.ground_texture)
	if ground_tex:
		material.set_shader_parameter("albedo_texture", ground_tex)
	material.set_shader_parameter("uv_scale", _biome.ground_uv_scale)

	_terrain_mesh.material_override = material

func initialize(coord: Vector2i, biome: BiomeData = null) -> void:
	chunk_coord = coord

	# Position chunk in world space
	position = Vector3(coord.x * CHUNK_SIZE, 0, coord.y * CHUNK_SIZE)

	# Seed RNG based on chunk coordinate for deterministic spawning
	_rng.seed = hash(coord)

	# Set biome (use provided or get from manager based on position)
	if biome:
		_biome = biome
	elif _biome_manager:
		_biome = _biome_manager.get_biome_for_position(position)

	if _biome:
		_apply_biome_terrain()
		_spawn_vegetation()

func _spawn_vegetation() -> void:
	if not _biome or not _biome_manager:
		return

	# Determine number of tree clusters for this chunk
	var cluster_count := _rng.randi_range(_biome.clusters_min, _biome.clusters_max)
	var half_size := CHUNK_SIZE / 2.0 - _biome.cluster_margin

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
	for ring in _biome.foliage_rings:
		var foliage_count := _rng.randi_range(ring.count_min, ring.count_max)

		for _i in foliage_count:
			# Select texture (main or variant)
			var tex_path := ring.texture_path
			if ring.variants.size() > 0 and _rng.randf() < 0.5:
				tex_path = ring.variants[_rng.randi() % ring.variants.size()]

			var tex := _biome_manager.get_texture(tex_path)
			if not tex:
				continue

			# Random angle for radial distribution
			var angle := _rng.randf() * TAU
			# Random radius within ring's range
			var radius := _rng.randf_range(ring.radius_min, ring.radius_max)

			# Calculate position
			var offset := Vector2(cos(angle), sin(angle)) * radius
			var pos := center + offset

			# Base height with variance
			var base_height := _rng.randf_range(ring.height_min, ring.height_max)
			var scale_factor := 1.0 + _rng.randf_range(-ring.size_variance, ring.size_variance)
			var final_height := base_height * scale_factor

			# Scale collision radius proportionally
			var final_collision_radius := ring.collision_radius * scale_factor

			_spawn_billboard_at(tex, final_height, Vector3(pos.x, 0, pos.y), final_collision_radius)

func _spawn_billboard_at(tex: Texture2D, height: float, pos: Vector3, collision_radius: float) -> void:
	# Check if too close to world origin (player spawn)
	var world_pos := position + pos
	if Vector2(world_pos.x, world_pos.z).length() < _biome.spawn_clear_radius:
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

func get_biome() -> BiomeData:
	return _biome
