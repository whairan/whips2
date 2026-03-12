extends ManipulativeBase
## Counter seeds — draggable counting tokens.
## Can be placed individually, grouped, and counted.

var seed_count: int = 0
var seeds: Array[Control] = []

const SEED_SIZE := 12
const SEED_COLORS := [
	Color(0.55, 0.35, 0.17),  # Brown
	Color(0.45, 0.55, 0.25),  # Olive
	Color(0.65, 0.45, 0.20),  # Tan
]


func _ready() -> void:
	tool_name = "counter_seeds"
	custom_minimum_size = Vector2(200, 80)


func add_seed(pos: Vector2 = Vector2.ZERO) -> void:
	seed_count += 1
	var seed_node = _create_seed_visual()
	if pos == Vector2.ZERO:
		pos = Vector2(
			randf_range(10, size.x - 10),
			randf_range(10, size.y - 10)
		)
	seed_node.position = pos
	add_child(seed_node)
	seeds.append(seed_node)
	queue_redraw()


func remove_last_seed() -> void:
	if seeds.is_empty():
		return
	var last = seeds.pop_back()
	last.queue_free()
	seed_count -= 1
	queue_redraw()


func clear_seeds() -> void:
	for s in seeds:
		s.queue_free()
	seeds.clear()
	seed_count = 0
	queue_redraw()


func get_count() -> int:
	return seed_count


func _create_seed_visual() -> Control:
	var seed_ctrl = Control.new()
	seed_ctrl.custom_minimum_size = Vector2(SEED_SIZE, SEED_SIZE)
	seed_ctrl.size = Vector2(SEED_SIZE, SEED_SIZE)

	# Make it draggable within the counter area
	var color_rect = ColorRect.new()
	color_rect.size = Vector2(SEED_SIZE, SEED_SIZE)
	color_rect.color = SEED_COLORS[seed_count % SEED_COLORS.size()]
	# Round appearance via shader or just use a small sprite
	seed_ctrl.add_child(color_rect)

	return seed_ctrl


func _draw() -> void:
	# Draw count label
	if seed_count > 0:
		var font = ThemeDB.fallback_font
		var text = str(seed_count)
		draw_string(font, Vector2(5, size.y - 5), "Count: " + text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.BLACK)
