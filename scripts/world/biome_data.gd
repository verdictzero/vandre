class_name BiomeData
extends Resource
## Configuration for a biome including terrain, vegetation, and atmosphere

@export var biome_name: String = "unnamed"
@export var biome_id: String = "unnamed"  # Unique identifier

@export_group("Terrain")
@export var ground_texture: String = ""
@export var ground_uv_scale: float = 8.0

@export_group("Vegetation")
@export var foliage_rings: Array[FoliageRing] = []
@export var clusters_min: int = 2
@export var clusters_max: int = 4
@export var cluster_margin: float = 10.0  # Distance from chunk edge for cluster centers

@export_group("Atmosphere")
@export var fog_color: Color = Color(0.7, 0.75, 0.8, 1.0)
@export var ambient_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var fog_start: float = 40.0
@export var fog_end: float = 128.0

@export_group("Spawn")
@export var spawn_clear_radius: float = 20.0  # Treeless area around world origin
