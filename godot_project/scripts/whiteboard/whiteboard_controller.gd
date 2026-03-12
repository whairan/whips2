extends CanvasLayer
## Whiteboard overlay — multi-page drawing canvas with tools.
## Can be opened from anywhere with toggle_whiteboard action.

signal whiteboard_opened
signal whiteboard_closed

enum Tool { PENCIL, ERASER, SELECT }

const CANVAS_WIDTH := 960
const CANVAS_HEIGHT := 540
const MAX_PAGES := 10

var is_open: bool = false
var current_tool: Tool = Tool.PENCIL
var current_color: Color = Color.BLACK
var brush_size: int = 3
var grid_visible: bool = false
var current_page: int = 0

var _pages: Array[Image] = []
var _is_drawing: bool = false
var _last_draw_pos: Vector2 = Vector2.ZERO
var _undo_manager: UndoRedoManager

@onready var background: ColorRect = $Background
@onready var canvas_sprite: Sprite2D = $CanvasContainer/CanvasSprite
@onready var grid_overlay: Sprite2D = $CanvasContainer/GridOverlay
@onready var toolbar: HBoxContainer = $Toolbar
@onready var page_label: Label = $PageLabel
@onready var canvas_container: Control = $CanvasContainer


func _ready() -> void:
	layer = 100
	visible = false

	_undo_manager = UndoRedoManager.new()
	add_child(_undo_manager)

	# Create first page
	_add_page()
	_update_canvas_display()
	_update_page_label()

	if grid_overlay:
		grid_overlay.visible = grid_visible


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_whiteboard"):
		toggle()
		get_viewport().set_input_as_handled()
		return

	if not is_open:
		return

	# Drawing input
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drawing(event.position)
			else:
				_stop_drawing()

	elif event is InputEventMouseMotion and _is_drawing:
		_continue_drawing(event.position)

	# Keyboard shortcuts
	if event is InputEventKey and event.pressed:
		if event.ctrl_pressed and event.keycode == KEY_Z:
			if event.shift_pressed:
				redo()
			else:
				undo()
			get_viewport().set_input_as_handled()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	is_open = true
	visible = true
	GameManager.whiteboard_open = true
	whiteboard_opened.emit()


func close() -> void:
	is_open = false
	visible = false
	_is_drawing = false
	GameManager.whiteboard_open = false
	whiteboard_closed.emit()


# --- Drawing ---

func _start_drawing(screen_pos: Vector2) -> void:
	var canvas_pos = _screen_to_canvas(screen_pos)
	if canvas_pos.x < 0:
		return  # Click outside canvas
	_is_drawing = true
	_last_draw_pos = canvas_pos
	_draw_point(canvas_pos)
	_undo_manager.begin_stroke()


func _continue_drawing(screen_pos: Vector2) -> void:
	var canvas_pos = _screen_to_canvas(screen_pos)
	if canvas_pos.x < 0:
		return
	_draw_line_bresenham(_last_draw_pos, canvas_pos)
	_last_draw_pos = canvas_pos
	_update_canvas_display()


func _stop_drawing() -> void:
	if _is_drawing:
		_is_drawing = false
		_undo_manager.end_stroke(_pages[current_page].duplicate())
		_update_canvas_display()


func _draw_point(pos: Vector2) -> void:
	var img = _pages[current_page]
	var color = Color.WHITE if current_tool == Tool.ERASER else current_color
	var half = brush_size / 2

	for dx in range(-half, half + 1):
		for dy in range(-half, half + 1):
			var px = int(pos.x) + dx
			var py = int(pos.y) + dy
			if px >= 0 and px < CANVAS_WIDTH and py >= 0 and py < CANVAS_HEIGHT:
				if Vector2(dx, dy).length() <= half:
					img.set_pixel(px, py, color)


func _draw_line_bresenham(from: Vector2, to: Vector2) -> void:
	var x0 = int(from.x)
	var y0 = int(from.y)
	var x1 = int(to.x)
	var y1 = int(to.y)

	var dx = abs(x1 - x0)
	var dy = -abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx + dy

	while true:
		_draw_point(Vector2(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


func _screen_to_canvas(screen_pos: Vector2) -> Vector2:
	if not canvas_container:
		return Vector2(-1, -1)
	var local = canvas_container.get_local_mouse_position()
	if local.x < 0 or local.y < 0 or local.x >= CANVAS_WIDTH or local.y >= CANVAS_HEIGHT:
		return Vector2(-1, -1)
	return local


func _update_canvas_display() -> void:
	if canvas_sprite and current_page < _pages.size():
		var tex = ImageTexture.create_from_image(_pages[current_page])
		canvas_sprite.texture = tex


# --- Page management ---

func _add_page() -> void:
	if _pages.size() >= MAX_PAGES:
		return
	var img = Image.create(CANVAS_WIDTH, CANVAS_HEIGHT, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_pages.append(img)


func next_page() -> void:
	if current_page < _pages.size() - 1:
		current_page += 1
	elif _pages.size() < MAX_PAGES:
		_add_page()
		current_page = _pages.size() - 1
	_update_canvas_display()
	_update_page_label()


func prev_page() -> void:
	if current_page > 0:
		current_page -= 1
		_update_canvas_display()
		_update_page_label()


func _update_page_label() -> void:
	if page_label:
		page_label.text = "%d / %d" % [current_page + 1, _pages.size()]


# --- Tool selection ---

func set_pencil() -> void:
	current_tool = Tool.PENCIL


func set_eraser() -> void:
	current_tool = Tool.ERASER


func set_color(color: Color) -> void:
	current_color = color
	current_tool = Tool.PENCIL


func toggle_grid() -> void:
	grid_visible = not grid_visible
	if grid_overlay:
		grid_overlay.visible = grid_visible


# --- Undo/Redo ---

func undo() -> void:
	var img = _undo_manager.undo()
	if img:
		_pages[current_page] = img
		_update_canvas_display()


func redo() -> void:
	var img = _undo_manager.redo()
	if img:
		_pages[current_page] = img
		_update_canvas_display()


func clear_page() -> void:
	_undo_manager.begin_stroke()
	_pages[current_page].fill(Color.WHITE)
	_undo_manager.end_stroke(_pages[current_page].duplicate())
	_update_canvas_display()


# --- Serialization ---

func get_state() -> Dictionary:
	var page_data: Array = []
	for img in _pages:
		page_data.append(Marshalls.raw_to_base64(img.save_png_to_buffer()))
	return {"pages": page_data, "current_page": current_page}


func load_state(state: Dictionary) -> void:
	_pages.clear()
	for b64 in state.get("pages", []):
		var buffer = Marshalls.base64_to_raw(b64)
		var img = Image.new()
		img.load_png_from_buffer(buffer)
		_pages.append(img)
	current_page = state.get("current_page", 0)
	if _pages.is_empty():
		_add_page()
	_update_canvas_display()
	_update_page_label()
