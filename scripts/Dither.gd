extends CanvasLayer
## Post-process dithering effect for 3D viewport only

var color_rect: ColorRect

func _ready():
	layer = 1  # Below UI layer so dithering doesn't affect UI text

	color_rect = ColorRect.new()
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var material = ShaderMaterial.new()
	material.shader = load("res://shaders/dither.gdshader")
	color_rect.material = material

	add_child(color_rect)
