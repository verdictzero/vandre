extends MeshInstance3D
## Y-axis billboard sprite for vegetation

@export var sprite_texture: Texture2D:
	set(value):
		sprite_texture = value
		_update_material()

@export var sprite_scale: float = 1.0:
	set(value):
		sprite_scale = value
		_update_mesh_size()

var _material: ShaderMaterial

func _ready() -> void:
	_setup_mesh()
	_update_material()

func _setup_mesh() -> void:
	# Create a quad mesh
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0) * sprite_scale
	quad.orientation = PlaneMesh.FACE_Z
	mesh = quad

func _update_mesh_size() -> void:
	if mesh and mesh is QuadMesh:
		(mesh as QuadMesh).size = Vector2(2.0, 2.0) * sprite_scale

func _update_material() -> void:
	if not _material:
		_material = ShaderMaterial.new()
		_material.shader = preload("res://shaders/billboard_y.gdshader")

	if sprite_texture:
		_material.set_shader_parameter("albedo_texture", sprite_texture)

	material_override = _material

func set_texture(tex: Texture2D) -> void:
	sprite_texture = tex

func set_scale_factor(s: float) -> void:
	sprite_scale = s
