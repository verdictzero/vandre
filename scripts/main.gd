extends Node3D
## Main scene controller - sets up references and debug UI

@onready var player: Node3D = $Player
@onready var chunk_manager: Node3D = $ChunkManager
@onready var day_night_controller: Node = $DayNightController
@onready var debug_label: Label = $UI/DebugLabel
@onready var fps_label: Label = $UI/FPSLabel
@onready var time_label: Label = $UI/TimeLabel

var _debug_visible: bool = false

func _ready() -> void:
	# Connect player to chunk manager
	chunk_manager.set_player(player)

	# Set background elements to follow player position (not rotation)
	$BackgroundRings.target = player
	$CloudLayers.target = player
	$SkyDome.target = player

	# Hide debug by default
	debug_label.visible = false

	# Connect to gamepad manager signals
	if GamepadManager:
		GamepadManager.gamepad_connected.connect(_on_gamepad_connected)
		GamepadManager.gamepad_disconnected.connect(_on_gamepad_disconnected)

func _on_gamepad_connected(device_id: int, device_name: String) -> void:
	print("Gamepad connected: %s" % device_name)

func _on_gamepad_disconnected(device_id: int) -> void:
	print("Gamepad disconnected: %d" % device_id)

func _process(_delta: float) -> void:
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	time_label.text = day_night_controller.get_time_string()
	if _debug_visible:
		_update_debug_label()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		_debug_visible = !_debug_visible
		debug_label.visible = _debug_visible

	# Time skip shortcuts (for testing)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_BRACKETRIGHT:  # ] = skip 1 hour
			day_night_controller.skip_hours(1.0)
		elif event.keycode == KEY_BRACKETLEFT:  # [ = go back 1 hour
			day_night_controller.skip_hours(-1.0)

func _update_debug_label() -> void:
	var fps: int = Engine.get_frames_per_second()
	var time_str: String = day_night_controller.get_time_string()
	var chunk_coord: Vector2i = chunk_manager.get_player_chunk_coord()
	var active_chunks: int = chunk_manager.get_active_chunk_count()

	# Gamepad info
	var gamepad_info := "None"
	var input_mode := "Keyboard/Mouse"
	if GamepadManager:
		if GamepadManager.has_gamepad():
			gamepad_info = "%d connected" % GamepadManager.get_gamepad_count()
			if GamepadManager.primary_gamepad >= 0:
				gamepad_info += "\n  Primary: %s" % GamepadManager.get_gamepad_name(GamepadManager.primary_gamepad)
		if GamepadManager.using_gamepad:
			input_mode = "Gamepad"

	debug_label.text = """FPS: %d
Time: %s
Chunk: (%d, %d)
Active Chunks: %d
Position: (%.1f, %.1f, %.1f)

Input: %s
Gamepads: %s

Controls:
WASD/Left Stick - Move
Mouse/Right Stick - Look
Shift/RT - Run
[ ] - Time skip
F3/`/Back - Toggle debug
ESC/Start - Release mouse""" % [
		fps,
		time_str,
		chunk_coord.x, chunk_coord.y,
		active_chunks,
		player.position.x, player.position.y, player.position.z,
		input_mode,
		gamepad_info
	]
