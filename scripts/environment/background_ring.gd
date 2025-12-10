@tool
extends MeshInstance3D
## A cylindrical background ring for distant environment layers

@export var ring_radius: float = 100.0:
	set(value):
		ring_radius = value
		_update_mesh()

@export var ring_height: float = 20.0:
	set(value):
		ring_height = value
		_update_mesh()

@export var texture: Texture2D:
	set(value):
		texture = value
		_update_material()

@export_range(0.0, 1.0) var fog_amount: float = 0.5:
	set(value):
		fog_amount = value
		_update_material()

@export var scroll_speed: float = 0.0:
	set(value):
		scroll_speed = value
		_update_material()

@export var y_offset: float = 0.0:
	set(value):
		y_offset = value
		position.y = y_offset

@export var use_cloud_shader: bool = false:
	set(value):
		use_cloud_shader = value
		_update_material()

@export var use_mist_shader: bool = false:
	set(value):
		use_mist_shader = value
		_update_material()

@export_range(0.0, 1.0) var cloud_opacity: float = 0.5:
	set(value):
		cloud_opacity = value
		_update_material()

@export_range(0.5, 4.0) var mist_gradient_power: float = 1.5:
	set(value):
		mist_gradient_power = value
		_update_material()

@export var render_priority: int = 0:
	set(value):
		render_priority = value
		_update_material()

@export var uv_scale_x: float = 1.0:
	set(value):
		uv_scale_x = value
		_update_material()

@export var uv_scale_y: float = 1.0:
	set(value):
		uv_scale_y = value
		_update_material()

var _material: ShaderMaterial

func _ready() -> void:
	_update_mesh()
	_update_material()
	position.y = y_offset

func _update_mesh() -> void:
	# Create a cylinder mesh (open top/bottom, normals inward)
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = ring_radius
	cylinder.bottom_radius = ring_radius
	cylinder.height = ring_height
	cylinder.radial_segments = 32
	cylinder.rings = 1
	cylinder.cap_top = false
	cylinder.cap_bottom = false
	mesh = cylinder

func _update_material() -> void:
	if not _material:
		_material = ShaderMaterial.new()

	if use_mist_shader:
		_material.shader = load("res://shaders/mist_layer.gdshader")
		_material.set_shader_parameter("gradient_power", mist_gradient_power)
		_material.set_shader_parameter("opacity", cloud_opacity)
	elif use_cloud_shader:
		_material.shader = load("res://shaders/clouds.gdshader")
		_material.set_shader_parameter("scroll_speed", scroll_speed)
		_material.set_shader_parameter("opacity", cloud_opacity)
		_material.set_shader_parameter("uv_scale_x", uv_scale_x)
		_material.set_shader_parameter("uv_scale_y", uv_scale_y)
	else:
		_material.shader = load("res://shaders/background_ring.gdshader")
		_material.set_shader_parameter("fog_amount", fog_amount)
		_material.set_shader_parameter("scroll_speed", scroll_speed)
		_material.set_shader_parameter("uv_scale_x", uv_scale_x)
		_material.set_shader_parameter("uv_scale_y", uv_scale_y)

	if texture:
		_material.set_shader_parameter("albedo_texture", texture)

	_material.render_priority = render_priority
	material_override = _material
