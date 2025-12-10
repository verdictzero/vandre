extends CharacterBody3D
## First-person player controller for Flatland Walker
## Supports keyboard/mouse and gamepad input

@export var movement_speed: float = 5.0
@export var run_speed: float = 10.0
@export var mouse_sensitivity: float = 0.002
@export var gamepad_look_sensitivity: float = 3.0
@export var eye_height: float = 1.7

var _camera: Camera3D
var _is_running: bool = false

func _ready() -> void:
	_camera = $Camera3D
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Set initial position at eye height
	position.y = eye_height

func _unhandled_input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion:
		_apply_look_input(event.relative * mouse_sensitivity)

	# Toggle run
	if event.is_action_pressed("toggle_run"):
		_is_running = !_is_running

	# Escape to release mouse / Start button on gamepad
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_toggle_mouse_capture()
	elif event.is_action_pressed("gamepad_pause"):
		_toggle_mouse_capture()

func _toggle_mouse_capture() -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _apply_look_input(look_delta: Vector2) -> void:
	# Horizontal rotation (Y-axis) - rotate the whole player
	rotate_y(-look_delta.x)

	# Vertical rotation (X-axis) - rotate only the camera
	_camera.rotate_x(-look_delta.y)
	# Clamp vertical look to prevent over-rotation
	_camera.rotation.x = clamp(_camera.rotation.x, -PI/2.2, PI/2.2)

func _physics_process(delta: float) -> void:
	# Handle gamepad look (right stick)
	_process_gamepad_look(delta)

	# Get input direction
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_forward", "move_backward")

	# Calculate movement direction relative to player orientation
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Apply speed (analog stick gives gradual speed control)
	var speed := run_speed if _is_running else movement_speed
	var input_strength := input_dir.length()

	if direction:
		velocity.x = direction.x * speed * min(input_strength, 1.0)
		velocity.z = direction.z * speed * min(input_strength, 1.0)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# No vertical movement - stay at fixed height
	velocity.y = 0

	move_and_slide()

	# Ensure we stay at eye height
	position.y = eye_height

func _process_gamepad_look(delta: float) -> void:
	# Get right stick input for camera look
	var look_input := Vector2.ZERO
	look_input.x = Input.get_axis("look_left", "look_right")
	look_input.y = Input.get_axis("look_up", "look_down")

	if look_input.length() > 0.0:
		var look_delta := look_input * gamepad_look_sensitivity * delta
		_apply_look_input(look_delta)
