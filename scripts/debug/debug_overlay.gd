extends Control
## Debug overlay with additional controls and information

@export var day_night_controller: Node
@export var chunk_manager: Node3D
@export var player: Node3D

var _visible: bool = false

@onready var info_label: Label = $InfoPanel/InfoLabel
@onready var panel: Panel = $InfoPanel

func _ready() -> void:
	visible = false
	panel.visible = false

func _process(_delta: float) -> void:
	if _visible:
		_update_info()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		toggle_visibility()

func toggle_visibility() -> void:
	_visible = !_visible
	visible = _visible
	panel.visible = _visible

func _update_info() -> void:
	if not day_night_controller or not chunk_manager or not player:
		return

	var fps := Engine.get_frames_per_second()
	var time_str := day_night_controller.get_time_string() if day_night_controller.has_method("get_time_string") else "N/A"
	var chunk_coord := chunk_manager.get_player_chunk_coord() if chunk_manager.has_method("get_player_chunk_coord") else Vector2i.ZERO
	var active_chunks := chunk_manager.get_active_chunk_count() if chunk_manager.has_method("get_active_chunk_count") else 0

	var mem_usage := OS.get_static_memory_usage() / 1024.0 / 1024.0  # MB

	info_label.text = """=== DEBUG INFO ===
FPS: %d
Memory: %.1f MB
Time: %s

Player Position:
  X: %.2f
  Y: %.2f
  Z: %.2f

Chunk System:
  Current: (%d, %d)
  Active: %d chunks

=== CONTROLS ===
WASD - Move
Mouse - Look
Shift - Run
[ ] - Time +-1hr
F3/` - Toggle debug
ESC - Release mouse""" % [
		fps,
		mem_usage,
		time_str,
		player.position.x, player.position.y, player.position.z,
		chunk_coord.x, chunk_coord.y,
		active_chunks
	]
