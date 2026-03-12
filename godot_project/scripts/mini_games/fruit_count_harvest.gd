extends MiniGameBase
## Fruit Count Harvest — Count, compare, add, or subtract scattered fruit.
## Config: object_type, count_range, operation, time_limit_optional

var _target_count: int = 0
var _object_type: String = "mango"
var _operation: String = "count"

@onready var fruit_container: Control = $FruitArea if has_node("FruitArea") else null
@onready var answer_input: LineEdit = $AnswerInput if has_node("AnswerInput") else null
@onready var prompt_label: Label = $PromptLabel if has_node("PromptLabel") else null
@onready var submit_btn: Button = $SubmitButton if has_node("SubmitButton") else null


func _setup_game() -> void:
	_object_type = config.get("object_type", "mango")
	var count_range = config.get("count_range", [1, 10])
	_operation = config.get("operation", "count")
	_target_count = randi_range(count_range[0], count_range[1])

	if prompt_label:
		match _operation:
			"count":
				prompt_label.text = "How many %s do you see?" % _object_type
			"compare":
				prompt_label.text = "Which group has more?"
			_:
				prompt_label.text = "Count the %s!" % _object_type

	_spawn_objects(_target_count)

	if submit_btn:
		submit_btn.pressed.connect(_on_submit)


func _spawn_objects(count: int) -> void:
	if not fruit_container:
		return

	for i in range(count):
		var obj = ColorRect.new()
		obj.size = Vector2(16, 16)
		obj.color = _get_fruit_color(_object_type)
		obj.position = Vector2(
			randf_range(20, fruit_container.size.x - 36),
			randf_range(20, fruit_container.size.y - 36)
		)
		fruit_container.add_child(obj)


func _get_fruit_color(fruit: String) -> Color:
	match fruit:
		"mango": return Color(1.0, 0.8, 0.2)
		"coconut": return Color(0.55, 0.35, 0.17)
		"berry": return Color(0.8, 0.1, 0.2)
		_: return Color(0.3, 0.7, 0.3)


func _on_submit() -> void:
	if not answer_input:
		return
	var answer_text = answer_input.text.strip_edges()
	if answer_text.is_valid_int():
		var answer = answer_text.to_int()
		var correct = check_answer(answer, _target_count)
		if correct:
			finish_game()
		else:
			answer_input.text = ""
