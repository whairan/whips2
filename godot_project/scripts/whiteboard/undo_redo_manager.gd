class_name UndoRedoManager
extends Node
## Command-pattern undo/redo for whiteboard drawing.

const MAX_UNDO_STEPS := 50

var _undo_stack: Array[Image] = []
var _redo_stack: Array[Image] = []
var _stroke_in_progress: bool = false
var _pre_stroke_image: Image = null


func begin_stroke() -> void:
	_stroke_in_progress = true


func end_stroke(current_image: Image) -> void:
	if not _stroke_in_progress:
		return
	_stroke_in_progress = false
	_undo_stack.append(current_image.duplicate())
	_redo_stack.clear()
	# Trim stack
	while _undo_stack.size() > MAX_UNDO_STEPS:
		_undo_stack.pop_front()


func undo() -> Image:
	if _undo_stack.size() <= 1:
		return null
	var current = _undo_stack.pop_back()
	_redo_stack.append(current)
	return _undo_stack.back().duplicate()


func redo() -> Image:
	if _redo_stack.is_empty():
		return null
	var img = _redo_stack.pop_back()
	_undo_stack.append(img)
	return img.duplicate()


func clear() -> void:
	_undo_stack.clear()
	_redo_stack.clear()


func can_undo() -> bool:
	return _undo_stack.size() > 1


func can_redo() -> bool:
	return not _redo_stack.is_empty()
