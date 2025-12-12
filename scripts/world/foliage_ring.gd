class_name FoliageRing
extends Resource
## Configuration for a single ring of foliage in a cluster

@export var name: String = ""
@export var texture_path: String = ""
@export var variants: Array[String] = []  # Additional texture variants (e.g., bush_b, grass_b)

@export_group("Size")
@export var height_min: float = 1.0
@export var height_max: float = 2.0
@export var size_variance: float = 0.25  # Random scale factor (0.25 = +/-25%)

@export_group("Distribution")
@export var radius_min: float = 0.0
@export var radius_max: float = 5.0
@export var count_min: int = 1
@export var count_max: int = 3

@export_group("Collision")
@export var collision_radius: float = 0.0  # 0 = no collision (passable)
