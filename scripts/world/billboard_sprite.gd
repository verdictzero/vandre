extends MeshInstance3D
## Y-axis billboard sprite for vegetation

@export var sprite_texture: Texture2D:
	set(value):
		sprite_texture = value
		_update_material()
		_update_mesh_size()

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
	quad.size = _calculate_size()
	quad.orientation = PlaneMesh.FACE_Z
	mesh = quad

func _calculate_size() -> Vector2:
	# Calculate size preserving texture aspect ratio
	# Height is the base dimension (sprite_scale), width derived from aspect
	if sprite_texture:
		var tex_size := sprite_texture.get_size()
		var aspect := tex_size.x / tex_size.y  # width / height
		return Vector2(sprite_scale * aspect, sprite_scale)
	return Vector2(sprite_scale, sprite_scale)

func _update_mesh_size() -> void:
	if mesh and mesh is QuadMesh:
		(mesh as QuadMesh).size = _calculate_size()

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
