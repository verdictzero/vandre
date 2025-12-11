extends Node
## Controls the day/night cycle by updating global shader uniforms

@export var day_length_seconds: float = 300.0  # 5 minutes for full cycle (2x speed)
@export var starting_hour: float = 8.0
@export var paused: bool = false

var current_time: float = 8.0  # 0.0 to 24.0

# Color keyframes for different times of day
# Format: [hour, sky_top, sky_horizon, fog, ambient]
const COLOR_KEYFRAMES: Array = [
	# Night (0:00-5:00)
	[0.0, Color(0.05, 0.05, 0.15), Color(0.1, 0.1, 0.2), Color(0.08, 0.08, 0.15), Color(0.3, 0.3, 0.4)],
	# Dawn (5:00)
	[5.0, Color(0.2, 0.15, 0.3), Color(0.6, 0.4, 0.3), Color(0.4, 0.3, 0.35), Color(0.6, 0.5, 0.5)],
	# Morning (8:00)
	[8.0, Color(0.4, 0.6, 0.9), Color(0.7, 0.8, 0.95), Color(0.6, 0.7, 0.85), Color(1.0, 1.0, 1.0)],
	# Noon (12:00)
	[12.0, Color(0.3, 0.5, 0.9), Color(0.6, 0.75, 0.95), Color(0.55, 0.65, 0.85), Color(1.0, 1.0, 0.95)],
	# Afternoon (16:00)
	[16.0, Color(0.4, 0.55, 0.85), Color(0.7, 0.75, 0.9), Color(0.6, 0.68, 0.82), Color(1.0, 0.95, 0.9)],
	# Sunset (18:00)
	[18.0, Color(0.3, 0.3, 0.5), Color(0.9, 0.5, 0.3), Color(0.6, 0.45, 0.4), Color(0.9, 0.7, 0.6)],
	# Dusk (21:00)
	[21.0, Color(0.1, 0.1, 0.25), Color(0.3, 0.2, 0.35), Color(0.2, 0.18, 0.28), Color(0.5, 0.45, 0.55)],
	# Night (24:00 - wraps to 0:00)
	[24.0, Color(0.05, 0.05, 0.15), Color(0.1, 0.1, 0.2), Color(0.08, 0.08, 0.15), Color(0.3, 0.3, 0.4)],
]

func _ready() -> void:
	current_time = starting_hour
	_update_colors()

func _process(delta: float) -> void:
	if paused:
		return

	# Advance time
	var hours_per_second := 24.0 / day_length_seconds
	current_time += delta * hours_per_second

	# Wrap at 24 hours
	if current_time >= 24.0:
		current_time -= 24.0

	_update_colors()

func _update_colors() -> void:
	var colors := get_interpolated_colors(current_time)

	RenderingServer.global_shader_parameter_set("sky_color_top", colors["sky_top"])
	RenderingServer.global_shader_parameter_set("sky_color_horizon", colors["sky_horizon"])
	RenderingServer.global_shader_parameter_set("fog_color", colors["fog"])
	RenderingServer.global_shader_parameter_set("ambient_tint", colors["ambient"])
	RenderingServer.global_shader_parameter_set("time_of_day", current_time)

func get_interpolated_colors(time: float) -> Dictionary:
	# Find the two keyframes to interpolate between
	var prev_idx := 0
	var next_idx := 1

	for i in range(COLOR_KEYFRAMES.size() - 1):
		if time >= COLOR_KEYFRAMES[i][0] and time < COLOR_KEYFRAMES[i + 1][0]:
			prev_idx = i
			next_idx = i + 1
			break

	var prev_frame: Array = COLOR_KEYFRAMES[prev_idx]
	var next_frame: Array = COLOR_KEYFRAMES[next_idx]

	# Calculate interpolation factor
	var range_size: float = next_frame[0] - prev_frame[0]
	var t: float = (time - prev_frame[0]) / range_size if range_size > 0 else 0.0

	# Smooth interpolation
	t = smoothstep(0.0, 1.0, t)

	return {
		"sky_top": prev_frame[1].lerp(next_frame[1], t),
		"sky_horizon": prev_frame[2].lerp(next_frame[2], t),
		"fog": prev_frame[3].lerp(next_frame[3], t),
		"ambient": prev_frame[4].lerp(next_frame[4], t),
	}

func set_time(hour: float) -> void:
	current_time = fmod(hour, 24.0)
	if current_time < 0:
		current_time += 24.0
	_update_colors()

func get_time_string() -> String:
	var hours := int(current_time)
	var minutes := int((current_time - hours) * 60)
	return "%02d:%02d" % [hours, minutes]

func skip_hours(hours: float) -> void:
	set_time(current_time + hours)
