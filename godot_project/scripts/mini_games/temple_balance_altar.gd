extends MiniGameBase
## Temple Balance Altar — Balance equations on a visual scale.
## Config: equation_type, num_steps, allow_negative

var _left_value: int = 0
var _right_value: int = 0
var _target_missing: int = 0

@onready var left_label: Label = $LeftSide if has_node("LeftSide") else null
@onready var right_label: Label = $RightSide if has_node("RightSide") else null
@onready var answer_input: LineEdit = $AnswerInput if has_node("AnswerInput") else null
@onready var prompt_label: Label = $PromptLabel if has_node("PromptLabel") else null
@onready var balance_visual: Control = $BalanceVisual if has_node("BalanceVisual") else null


func _setup_game() -> void:
	var eq_type = config.get("equation_type", "addition")
	var allow_neg = config.get("allow_negative", false)

	_generate_equation(eq_type, allow_neg)


func _generate_equation(eq_type: String, allow_neg: bool) -> void:
	match eq_type:
		"addition":
			var a = randi_range(1, 15)
			var b = randi_range(1, 15)
			_left_value = a
			_target_missing = b
			_right_value = a + b
			if prompt_label:
				prompt_label.text = "Find the missing number: %d + ? = %d" % [a, _right_value]
		"comparison":
			var a = randi_range(1, 20)
			var b = randi_range(1, 20)
			_left_value = a
			_right_value = b
			if prompt_label:
				prompt_label.text = "Which is greater: %d or %d?" % [a, b]
			_target_missing = max(a, b)
		"subtraction":
			var total = randi_range(5, 20)
			var part = randi_range(1, total - 1)
			_left_value = total
			_target_missing = part
			_right_value = total - part
			if prompt_label:
				prompt_label.text = "Find the missing number: %d - ? = %d" % [total, _right_value]
		_:
			var a = randi_range(1, 10)
			var b = randi_range(1, 10)
			_left_value = a
			_target_missing = b
			_right_value = a + b
			if prompt_label:
				prompt_label.text = "%d + ? = %d" % [a, _right_value]

	if left_label:
		left_label.text = str(_left_value)
	if right_label:
		right_label.text = str(_right_value)
