class_name EcoPuzzle
extends Node2D
## Links a math task to an environment change. The core "math restores the jungle" mechanic.

signal puzzle_solved
signal puzzle_progress(amount: float)

@export var puzzle_id: String = ""
@export var task_ref: String = ""
@export var target_node_path: NodePath
@export var solve_effect: String = ""  # Method name to call on target

var solved: bool = false
var _task_manager: Node


func _ready() -> void:
	_task_manager = get_node_or_null("/root/GameManager")


func trigger_puzzle() -> void:
	if solved:
		return
	# Start the linked math task
	var tm = get_node_or_null("/root/TaskManager")
	if tm:
		tm.start_task(task_ref)
		tm.task_completed.connect(_on_task_completed, CONNECT_ONE_SHOT)
	else:
		push_warning("EcoPuzzle: No TaskManager found")


func _on_task_completed(task_id: String, correct: bool) -> void:
	if task_id != task_ref:
		return
	if not correct:
		return

	solved = true
	_apply_effect()
	puzzle_solved.emit()


func _apply_effect() -> void:
	if target_node_path.is_empty():
		return

	var target = get_node_or_null(target_node_path)
	if not target:
		push_warning("EcoPuzzle: Target node not found: %s" % target_node_path)
		return

	# Call the solve effect method on the target
	if not solve_effect.is_empty() and target.has_method(solve_effect):
		target.call(solve_effect)
	elif target.has_method("rebuild"):
		target.rebuild()
	elif target.has_method("activate"):
		target.activate()
	else:
		push_warning("EcoPuzzle: Target has no method '%s'" % solve_effect)
