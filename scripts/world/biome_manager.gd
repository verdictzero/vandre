class_name BiomeManager
extends Node
## Manages loading and providing biome configurations

const BIOMES_PATH = "res://config/biomes/"

var _biomes: Dictionary = {}  # biome_id -> BiomeData
var _default_biome: BiomeData
var _textures: Dictionary = {}  # texture_path -> Texture2D (cached)

signal biomes_loaded

func _ready() -> void:
	_load_all_biomes()

func _load_all_biomes() -> void:
	var dir := DirAccess.open(BIOMES_PATH)
	if not dir:
		push_warning("BiomeManager: Could not open biomes directory: " + BIOMES_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var biome_path := BIOMES_PATH + file_name
			var biome: BiomeData = load(biome_path)
			if biome:
				_biomes[biome.biome_id] = biome
				# First loaded biome becomes default
				if not _default_biome:
					_default_biome = biome
				print("BiomeManager: Loaded biome '%s' from %s" % [biome.biome_id, file_name])
		file_name = dir.get_next()
	dir.list_dir_end()

	# Preload all textures for loaded biomes
	_preload_biome_textures()
	biomes_loaded.emit()

func _preload_biome_textures() -> void:
	for biome_id in _biomes:
		var biome: BiomeData = _biomes[biome_id]

		# Load ground texture
		if biome.ground_texture and not _textures.has(biome.ground_texture):
			var tex := load(biome.ground_texture)
			if tex:
				_textures[biome.ground_texture] = tex

		# Load foliage textures
		for ring in biome.foliage_rings:
			# Main texture
			if ring.texture_path and not _textures.has(ring.texture_path):
				var tex := load(ring.texture_path)
				if tex:
					_textures[ring.texture_path] = tex

			# Variant textures
			for variant_path in ring.variants:
				if variant_path and not _textures.has(variant_path):
					var tex := load(variant_path)
					if tex:
						_textures[variant_path] = tex

func get_biome(biome_id: String) -> BiomeData:
	if _biomes.has(biome_id):
		return _biomes[biome_id]
	return _default_biome

func get_default_biome() -> BiomeData:
	return _default_biome

func get_texture(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path]
	# Try to load on demand if not cached
	var tex := load(path) as Texture2D
	if tex:
		_textures[path] = tex
	return tex

func get_biome_for_position(_world_pos: Vector3) -> BiomeData:
	# TODO: Implement biome selection based on world position
	# For now, return default biome
	# Future: Use noise, regions, or other logic to determine biome
	return _default_biome

func get_all_biome_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in _biomes.keys():
		ids.append(id)
	return ids
