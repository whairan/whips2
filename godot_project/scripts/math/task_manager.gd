extends Node
## TaskManager — Handles task selection, presentation, grading, and outcomes.

signal task_started(task_data: Dictionary)
signal task_completed(task_id: String, correct: bool)
signal task_hint_requested(task_id: String, hint_level: int)
signal all_tasks_done

var current_task: Dictionary = {}
var current_hint_level: int = 0
var attempts: int = 0
var _quest_progress: Dictionary = {}  # Tracks quest stage completion


func start_task(task_id: String) -> void:
	var task_data = ContentLoader.get_task_data(task_id)
	if task_data.is_empty():
		push_error("TaskManager: Task not found: %s" % task_id)
		return

	current_task = task_data
	current_hint_level = 0
	attempts = 0
	GameManager.puzzle_active = true
	task_started.emit(task_data)


func submit_answer(answer) -> Dictionary:
	if current_task.is_empty():
		return {"correct": false, "feedback": "No active task"}

	attempts += 1
	var correct = _check_answer(answer, current_task)
	var result = {
		"correct": correct,
		"attempts": attempts,
		"task_id": current_task.get("task_id", ""),
		"feedback": "",
		"explanation": ""
	}

	if correct:
		result["feedback"] = "Correct!"
		result["explanation"] = current_task.get("explanation", "")
		_on_task_correct()
	else:
		result["feedback"] = _get_incorrect_feedback(answer)
		if current_task.get("on_incorrect", {}).get("offer_hint", false):
			result["offer_hint"] = true

	return result


func request_hint() -> Dictionary:
	var hints = current_task.get("hints", [])
	current_hint_level += 1

	for hint in hints:
		if hint.get("level", 0) == current_hint_level:
			task_hint_requested.emit(current_task.get("task_id", ""), current_hint_level)
			return {"level": current_hint_level, "text": hint.get("text", ""), "has_more": current_hint_level < hints.size()}

	return {"level": current_hint_level, "text": "Try your best! You've got this.", "has_more": false}


func skip_task() -> void:
	# In calm mode or after many attempts, allow skipping
	var task_id = current_task.get("task_id", "")
	GameManager.record_task_result(current_task.get("skill_tags", []), false, current_task.get("difficulty", 1))
	_end_task()
	task_completed.emit(task_id, false)


func get_available_approaches() -> Array:
	return current_task.get("solution_approaches", [])


func is_whiteboard_enabled() -> bool:
	return current_task.get("whiteboard_enabled", true)


func get_available_tools() -> Array:
	var task_tools = current_task.get("tools_available", [])
	# Filter to only unlocked tools
	var available: Array = []
	for tool_name in task_tools:
		if GameManager.has_tool(tool_name):
			available.append(tool_name)
	return available


func _check_answer(answer, task: Dictionary) -> bool:
	var correct_answer = task.get("answer")

	# Handle "variable" answers (boss tasks with generated content)
	if correct_answer is String and correct_answer == "variable":
		return true  # Boss tasks use their own validation

	# Direct comparison
	if typeof(answer) == typeof(correct_answer) and answer == correct_answer:
		return true

	# Numeric comparison with tolerance
	if (answer is float or answer is int) and (correct_answer is float or correct_answer is int):
		return abs(float(answer) - float(correct_answer)) < 0.001

	# String comparison (case-insensitive, trimmed)
	if answer is String and correct_answer is String:
		return answer.strip_edges().to_lower() == correct_answer.strip_edges().to_lower()

	# Check equivalent answers
	var equivalents = task.get("accept_equivalent", [])
	for equiv in equivalents:
		if typeof(answer) == typeof(equiv) and answer == equiv:
			return true

	# Array answer (fill-in-the-blank)
	if answer is Array and correct_answer is Array:
		if answer.size() != correct_answer.size():
			return false
		for i in range(answer.size()):
			if not _values_match(answer[i], correct_answer[i]):
				return false
		return true

	return false


func _values_match(a, b) -> bool:
	if typeof(a) == typeof(b):
		return a == b
	if (a is float or a is int) and (b is float or b is int):
		return abs(float(a) - float(b)) < 0.001
	return str(a) == str(b)


func _get_incorrect_feedback(answer) -> String:
	# Check for common mistakes with specific feedback
	var common_mistakes = current_task.get("on_incorrect", {}).get("common_mistakes", [])
	for mistake in common_mistakes:
		if _values_match(answer, mistake.get("wrong_answer")):
			return mistake.get("feedback", "Not quite. Try again!")

	# Generic gentle feedback
	var feedback_type = current_task.get("on_incorrect", {}).get("feedback", "gentle_retry")
	match feedback_type:
		"gentle_retry":
			return "Not quite — give it another try!"
		"show_hint":
			return "Almost! Here's a hint to help."
		"offer_easier":
			return "That's tricky. Want to try an easier version?"
		"explain_mistake":
			return "Let's think about this differently."
		_:
			return "Try again!"


func _on_task_correct() -> void:
	var task_id = current_task.get("task_id", "")
	var skill_tags = current_task.get("skill_tags", [])
	var difficulty = current_task.get("difficulty", 1)

	# Record mastery
	GameManager.record_task_result(skill_tags, true, difficulty)

	# Handle on_correct triggers
	var on_correct = current_task.get("on_correct", {})
	var trigger = on_correct.get("trigger", "")
	var target = on_correct.get("target", "")

	match trigger:
		"eco_puzzle_progress":
			_progress_eco_puzzle(target)
		"quest_progress":
			_progress_quest(target)
		"boss_defeat":
			_handle_boss_defeat(target)

	_end_task()
	task_completed.emit(task_id, true)


func _end_task() -> void:
	current_task = {}
	current_hint_level = 0
	attempts = 0
	GameManager.puzzle_active = false


func _progress_eco_puzzle(puzzle_id: String) -> void:
	# Signal the region manager to handle eco puzzle progress
	_quest_progress[puzzle_id] = true


func _progress_quest(stage: String) -> void:
	_quest_progress[stage] = true


func _handle_boss_defeat(boss_id: String) -> void:
	_quest_progress[boss_id] = true
	# Region completion is handled by the region manager checking this


func is_quest_stage_complete(stage: String) -> bool:
	return _quest_progress.get(stage, false)


func reset_quest_progress() -> void:
	_quest_progress.clear()
