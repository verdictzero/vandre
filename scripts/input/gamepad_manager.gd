extends Node
## Autoload singleton for gamepad detection and management
## Emits signals when gamepads connect/disconnect and tracks active controllers

signal gamepad_connected(device_id: int, device_name: String)
signal gamepad_disconnected(device_id: int)
signal input_device_changed(is_gamepad: bool)

## Currently connected gamepad device IDs
var connected_gamepads: Array[int] = []

## Whether the last input was from a gamepad
var using_gamepad: bool = false:
	set(value):
		if using_gamepad != value:
			using_gamepad = value
			input_device_changed.emit(value)

## Primary gamepad device ID (-1 if none)
var primary_gamepad: int = -1

## Gamepad info cache
var _gamepad_info: Dictionary = {}  # device_id -> {name, guid}

func _ready() -> void:
	# Connect to input signals
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

	# Check for already connected gamepads
	_scan_connected_gamepads()

	# Log initial state
	if connected_gamepads.size() > 0:
		print("[GamepadManager] Found %d gamepad(s) on startup" % connected_gamepads.size())
	else:
		print("[GamepadManager] No gamepads detected")

func _scan_connected_gamepads() -> void:
	connected_gamepads.clear()
	_gamepad_info.clear()

	for device_id in Input.get_connected_joypads():
		_register_gamepad(device_id)

	_update_primary_gamepad()

func _register_gamepad(device_id: int) -> void:
	if device_id in connected_gamepads:
		return

	var device_name := Input.get_joy_name(device_id)
	var device_guid := Input.get_joy_guid(device_id)

	connected_gamepads.append(device_id)
	_gamepad_info[device_id] = {
		"name": device_name,
		"guid": device_guid,
		"vibration_supported": _check_vibration_support(device_id)
	}

	print("[GamepadManager] Gamepad connected: %s (ID: %d, GUID: %s)" % [device_name, device_id, device_guid])

func _unregister_gamepad(device_id: int) -> void:
	if device_id not in connected_gamepads:
		return

	var device_name: String = _gamepad_info.get(device_id, {}).get("name", "Unknown")
	connected_gamepads.erase(device_id)
	_gamepad_info.erase(device_id)

	print("[GamepadManager] Gamepad disconnected: %s (ID: %d)" % [device_name, device_id])

func _update_primary_gamepad() -> void:
	if connected_gamepads.size() > 0:
		primary_gamepad = connected_gamepads[0]
	else:
		primary_gamepad = -1

func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		_register_gamepad(device_id)
		_update_primary_gamepad()
		gamepad_connected.emit(device_id, get_gamepad_name(device_id))
	else:
		_unregister_gamepad(device_id)
		_update_primary_gamepad()
		gamepad_disconnected.emit(device_id)

func _input(event: InputEvent) -> void:
	# Track whether input is coming from gamepad or keyboard/mouse
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		using_gamepad = true
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		using_gamepad = false

func _check_vibration_support(device_id: int) -> bool:
	# Try a zero-strength vibration to check if it's supported
	Input.start_joy_vibration(device_id, 0.0, 0.0, 0.01)
	return true  # Most modern controllers support it

## Get the display name for a gamepad
func get_gamepad_name(device_id: int) -> String:
	if device_id in _gamepad_info:
		return _gamepad_info[device_id]["name"]
	return Input.get_joy_name(device_id)

## Get the GUID for a gamepad (useful for custom mappings)
func get_gamepad_guid(device_id: int) -> String:
	if device_id in _gamepad_info:
		return _gamepad_info[device_id]["guid"]
	return Input.get_joy_guid(device_id)

## Check if any gamepad is connected
func has_gamepad() -> bool:
	return connected_gamepads.size() > 0

## Get count of connected gamepads
func get_gamepad_count() -> int:
	return connected_gamepads.size()

## Vibrate the primary gamepad (or specific device)
func vibrate(weak_magnitude: float = 0.5, strong_magnitude: float = 0.5, duration: float = 0.2, device_id: int = -1) -> void:
	var target_device := device_id if device_id >= 0 else primary_gamepad
	if target_device >= 0:
		Input.start_joy_vibration(target_device, weak_magnitude, strong_magnitude, duration)

## Stop vibration on a gamepad
func stop_vibration(device_id: int = -1) -> void:
	var target_device := device_id if device_id >= 0 else primary_gamepad
	if target_device >= 0:
		Input.stop_joy_vibration(target_device)

## Get a formatted string of all connected gamepads for debug display
func get_debug_info() -> String:
	if connected_gamepads.size() == 0:
		return "No gamepads connected"

	var info := "Gamepads (%d):\n" % connected_gamepads.size()
	for device_id in connected_gamepads:
		var name: String = _gamepad_info.get(device_id, {}).get("name", "Unknown")
		var is_primary := " [PRIMARY]" if device_id == primary_gamepad else ""
		info += "  %d: %s%s\n" % [device_id, name, is_primary]
	return info

## Get axis value with applied deadzone (for custom handling)
func get_axis_with_deadzone(device_id: int, axis: JoyAxis, deadzone: float = 0.2) -> float:
	var value := Input.get_joy_axis(device_id, axis)
	if abs(value) < deadzone:
		return 0.0
	# Remap value outside deadzone to 0-1 range
	var sign_val := signf(value)
	value = (abs(value) - deadzone) / (1.0 - deadzone)
	return value * sign_val

## Get a Vector2 for a stick (left or right) with deadzone applied
func get_stick_vector(device_id: int, stick: String = "left", deadzone: float = 0.2) -> Vector2:
	var x_axis: JoyAxis
	var y_axis: JoyAxis

	if stick == "left":
		x_axis = JOY_AXIS_LEFT_X
		y_axis = JOY_AXIS_LEFT_Y
	else:  # right
		x_axis = JOY_AXIS_RIGHT_X
		y_axis = JOY_AXIS_RIGHT_Y

	var raw := Vector2(
		Input.get_joy_axis(device_id, x_axis),
		Input.get_joy_axis(device_id, y_axis)
	)

	# Radial deadzone
	if raw.length() < deadzone:
		return Vector2.ZERO

	# Remap to 0-1 range outside deadzone
	var normalized := raw.normalized()
	var remapped_length := (raw.length() - deadzone) / (1.0 - deadzone)
	return normalized * remapped_length
