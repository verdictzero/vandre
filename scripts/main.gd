extends Node3D
## Main scene controller - sets up references and debug UI

@onready var player: Node3D = $Player
@onready var chunk_manager: Node3D = $ChunkManager
@onready var day_night_controller: Node = $DayNightController
@onready var debug_label: Label = $UI/DebugLabel
@onready var system_label: Label = $UI/SystemLabel
@onready var render_label: Label = $UI/RenderLabel

var _debug_visible: bool = false
var _system_info: String = ""

func _ready() -> void:
	# Connect player to chunk manager
	chunk_manager.set_player(player)

	# Set sky to follow player position
	$SkyDome.target = player

	# Hide debug by default
	debug_label.visible = false
	system_label.visible = false
	render_label.visible = false

	# Cache static system info
	_system_info = "%s | %s" % [OS.get_name(), Engine.get_architecture_name()]

	# Apply styling to debug labels with Roboto Mono
	var font_bold := load("res://assets/fonts/Jersey_10,Roboto_Mono/Roboto_Mono/static/RobotoMono-Bold.ttf")
	var font_medium := load("res://assets/fonts/Jersey_10,Roboto_Mono/Roboto_Mono/static/RobotoMono-Medium.ttf")
	var font_regular := load("res://assets/fonts/Jersey_10,Roboto_Mono/Roboto_Mono/static/RobotoMono-Regular.ttf")
	_apply_label_style(debug_label, font_bold, 12)
	_apply_label_style(system_label, font_medium, 11)
	_apply_label_style(render_label, font_regular, 11)

	# Connect to gamepad manager signals
	if GamepadManager:
		GamepadManager.gamepad_connected.connect(_on_gamepad_connected)
		GamepadManager.gamepad_disconnected.connect(_on_gamepad_disconnected)

func _apply_label_style(label: Label, font: Font, size: int) -> void:
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

func _on_gamepad_connected(device_id: int, device_name: String) -> void:
	print("Gamepad connected: %s" % device_name)

func _on_gamepad_disconnected(device_id: int) -> void:
	print("Gamepad disconnected: %d" % device_id)

func _process(_delta: float) -> void:
	if _debug_visible:
		_update_debug_label()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		_debug_visible = !_debug_visible
		debug_label.visible = _debug_visible
		system_label.visible = _debug_visible
		render_label.visible = _debug_visible

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
				gamepad_info += " | %s" % GamepadManager.get_gamepad_name(GamepadManager.primary_gamepad)
		if GamepadManager.using_gamepad:
			input_mode = "Gamepad"

	# Main debug label (top left area)
	debug_label.text = """FPS: %d | Time: %s | Chunk: (%d, %d)
Position: (%.1f, %.1f, %.1f) | Input: %s
Gamepads: %s

Controls: WASD/Stick=Move | Mouse/RStick=Look | Shift/RT=Run
[ ]=Time skip | F3/Back=Debug | ESC/Start=Release mouse""" % [
		fps, time_str, chunk_coord.x, chunk_coord.y,
		player.position.x, player.position.y, player.position.z,
		input_mode, gamepad_info
	]

	# System label (bottom left) - CPU | RAM | GPU | VRAM | Architecture
	var cpu_time := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0  # ms
	var frame_target := 1000.0 / Engine.max_fps if Engine.max_fps > 0 else 16.67  # target frame time
	var cpu_pct := (cpu_time / frame_target) * 100.0
	var mem_static := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0  # MB
	var video_mem := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0

	system_label.text = "CPU: %.0f%% (%.1fms) | RAM: %.1fMB | VRAM: %.1fMB\n%s" % [
		cpu_pct, cpu_time, mem_static, video_mem, _system_info
	]

	# Render label (bottom right) - Chunks | Objects | Draw Calls | Primitives
	var draw_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var objects := Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	var primitives := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var texture_mem := Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0
	var buffer_mem := Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0

	render_label.text = "Chunks: %d | Objects: %d | Draw Calls: %d\nPrimitives: %d | TexMem: %.1fMB | BufMem: %.1fMB" % [
		active_chunks, int(objects), int(draw_calls),
		int(primitives), texture_mem, buffer_mem
	]
