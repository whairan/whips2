class_name ManipulativeBase
extends Control
## Base class for all manipulatives — draggable math tools.

signal placed_on_canvas(tool_instance: ManipulativeBase)
signal removed_from_canvas(tool_instance: ManipulativeBase)

@export var tool_name: String = ""
@export var tool_icon: Texture2D
@export var snap_to_grid: bool = false
@export var grid_size: int = 16

var is_on_canvas: bool = false
var is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				_drag_offset = event.position
			else:
				is_dragging = false
				if snap_to_grid:
					position = _snap(position)

	elif event is InputEventMouseMotion and is_dragging:
		position += event.relative


func _snap(pos: Vector2) -> Vector2:
	return Vector2(
		round(pos.x / grid_size) * grid_size,
		round(pos.y / grid_size) * grid_size
	)


func place_on_canvas() -> void:
	is_on_canvas = true
	placed_on_canvas.emit(self)


func remove_from_canvas() -> void:
	is_on_canvas = false
	removed_from_canvas.emit(self)
	queue_free()
