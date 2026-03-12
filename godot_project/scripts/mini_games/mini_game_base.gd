class_name MiniGameBase
extends Control
## Base class for all mini-game templates.
## Each mini-game is parameterized by a config dictionary from content data.

signal game_completed(score: int, correct: int, total: int)
signal answer_submitted(answer, correct: bool)
signal hint_requested

var config: Dictionary = {}
var score: int = 0
var correct_count: int = 0
var total_count: int = 0
var is_active: bool = false


func initialize(game_config: Dictionary) -> void:
	config = game_config
	score = 0
	correct_count = 0
	total_count = 0
	is_active = true
	_setup_game()


## Override in subclass to set up game visuals and logic.
func _setup_game() -> void:
	pass


func check_answer(answer, expected) -> bool:
	total_count += 1
	var correct = _compare(answer, expected)
	if correct:
		correct_count += 1
		score += _calculate_score()
	answer_submitted.emit(answer, correct)
	return correct


func finish_game() -> void:
	is_active = false
	game_completed.emit(score, correct_count, total_count)


func _compare(a, b) -> bool:
	if typeof(a) == typeof(b):
		return a == b
	if (a is float or a is int) and (b is float or b is int):
		return abs(float(a) - float(b)) < 0.001
	return str(a) == str(b)


func _calculate_score() -> int:
	# Base score, can be overridden
	return 10
