extends Control
## Simple compass bar showing N S E W with tick marks

const COMPASS_WIDTH: float = 200.0
const BAR_HEIGHT: float = 12.0
const TICK_HEIGHT: float = 6.0
const SMALL_TICK_HEIGHT: float = 3.0

var player: Node3D
var _pixel_font: Font

# Cardinal directions: angle (degrees from +Z), label
const CARDINALS = [
	[0.0, "N"],
	[90.0, "E"],
	[180.0, "S"],
	[270.0, "W"],
]

func _ready() -> void:
	# Load font
	_pixel_font = load("res://assets/fonts/Jersey_10,Roboto_Mono/Roboto_Mono/static/RobotoMono-Bold.ttf")

	# Position at bottom center
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -COMPASS_WIDTH / 2.0
	offset_right = COMPASS_WIDTH / 2.0
	offset_top = -30.0
	offset_bottom = -10.0

func set_player(p: Node3D) -> void:
	player = p

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not player:
		return

	# Get player's Y rotation in degrees (0-360)
	var player_angle := rad_to_deg(-player.rotation.y)
	player_angle = fmod(player_angle + 360.0, 360.0)

	var center_x := COMPASS_WIDTH / 2.0
	var bar_y := BAR_HEIGHT

	# Draw background bar
	draw_rect(Rect2(0, 0, COMPASS_WIDTH, BAR_HEIGHT), Color(0, 0, 0, 0.5))

	# Draw center marker (where player is looking)
	draw_line(Vector2(center_x, 0), Vector2(center_x, BAR_HEIGHT), Color(1, 1, 1, 0.8), 1.0)

	# Draw tick marks and cardinals
	# We show ~90 degrees of compass (45 on each side)
	var view_range := 90.0
	var pixels_per_degree := COMPASS_WIDTH / view_range

	# Draw ticks every 15 degrees, cardinals at 0, 90, 180, 270
	for deg_offset in range(-50, 51):
		var world_angle := fmod(player_angle + deg_offset + 360.0, 360.0)
		var screen_x := center_x + (deg_offset * pixels_per_degree)

		if screen_x < 0 or screen_x > COMPASS_WIDTH:
			continue

		# Check if this is a cardinal direction
		var is_cardinal := false
		var cardinal_label := ""
		for cardinal in CARDINALS:
			if abs(world_angle - cardinal[0]) < 0.5 or abs(world_angle - cardinal[0] - 360.0) < 0.5:
				is_cardinal = true
				cardinal_label = cardinal[1]
				break

		if is_cardinal:
			# Draw cardinal tick and label
			draw_line(Vector2(screen_x, bar_y - TICK_HEIGHT), Vector2(screen_x, bar_y), Color.WHITE, 1.0)
			draw_string(_pixel_font, Vector2(screen_x - 4, bar_y - TICK_HEIGHT - 1), cardinal_label, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)
		elif int(world_angle) % 15 == 0:
			# Draw small tick every 15 degrees
			draw_line(Vector2(screen_x, bar_y - SMALL_TICK_HEIGHT), Vector2(screen_x, bar_y), Color(1, 1, 1, 0.5), 1.0)
