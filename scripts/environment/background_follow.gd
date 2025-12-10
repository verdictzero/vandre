extends Node3D
## Makes background elements follow player position but not rotation
## Creates natural parallax effect for distant scenery

@export var target: Node3D
@export var follow_y: bool = false

func _process(_delta: float) -> void:
	if target:
		if follow_y:
			global_position = target.global_position
		else:
			# Follow X/Z only, keep Y at 0
			global_position.x = target.global_position.x
			global_position.z = target.global_position.z
