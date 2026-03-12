extends CanvasLayer
## TaskUI — Puzzle overlay for presenting math tasks.
## Dims the region background and shows the task panel.

signal answer_submitted(answer)
signal hint_requested
signal task_closed

@onready var background_dim: ColorRect = $BackgroundDim
@onready var task_panel: PanelContainer = $TaskPanel
@onready var prompt_label: RichTextLabel = $TaskPanel/VBox/PromptLabel
@onready var answer_input: LineEdit = $TaskPanel/VBox/AnswerInput
@onready var submit_button: Button = $TaskPanel/VBox/ButtonRow/SubmitButton
@onready var hint_button: Button = $TaskPanel/VBox/ButtonRow/HintButton
@onready var feedback_label: Label = $TaskPanel/VBox/FeedbackLabel
@onready var explanation_label: RichTextLabel = $TaskPanel/VBox/ExplanationLabel
@onready var close_button: Button = $TaskPanel/VBox/ButtonRow/CloseButton
@onready var approach_container: VBoxContainer = $TaskPanel/VBox/ApproachContainer

var _current_task: Dictionary = {}
var _task_manager: Node


func _ready() -> void:
	layer = 80
	visible = false

	if submit_button:
		submit_button.pressed.connect(_on_submit)
	if hint_button:
		hint_button.pressed.connect(_on_hint)
	if close_button:
		close_button.pressed.connect(_on_close)
	if answer_input:
		answer_input.text_submitted.connect(func(_t): _on_submit())


func show_task(task_data: Dictionary) -> void:
	_current_task = task_data
	visible = true

	# Dim background
	if background_dim:
		background_dim.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(background_dim, "modulate:a", 1.0, 0.3)

	# Set content
	if prompt_label:
		prompt_label.text = task_data.get("prompt", "")
	if answer_input:
		answer_input.text = ""
		answer_input.grab_focus()
	if feedback_label:
		feedback_label.text = ""
		feedback_label.visible = false
	if explanation_label:
		explanation_label.visible = false
	if close_button:
		close_button.visible = false

	# Show solution approaches
	_show_approaches(task_data.get("solution_approaches", []))

	# Whiteboard hint
	if task_data.get("whiteboard_enabled", true):
		if hint_button:
			hint_button.text = "Hint | Q: Whiteboard"


func _show_approaches(approaches: Array) -> void:
	if not approach_container:
		return
	for child in approach_container.get_children():
		child.queue_free()

	if approaches.size() > 1:
		var label = Label.new()
		label.text = "Approaches:"
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		approach_container.add_child(label)

		for approach in approaches:
			var btn = Button.new()
			btn.text = approach.get("method", "").replace("_", " ").capitalize()
			btn.tooltip_text = approach.get("hint", "")
			btn.flat = true
			btn.add_theme_font_size_override("font_size", 11)
			approach_container.add_child(btn)


func _on_submit() -> void:
	if not answer_input or answer_input.text.strip_edges().is_empty():
		return

	var raw_answer = answer_input.text.strip_edges()
	var answer: Variant = raw_answer

	# Try to convert to number
	if raw_answer.is_valid_float():
		answer = raw_answer.to_float()
		if answer == float(int(answer)):
			answer = int(answer)

	answer_submitted.emit(answer)


func show_result(result: Dictionary) -> void:
	var correct = result.get("correct", false)

	if feedback_label:
		feedback_label.visible = true
		feedback_label.text = result.get("feedback", "")
		if correct:
			feedback_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.3))
		else:
			feedback_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.2))

	if correct:
		# Show explanation
		if explanation_label:
			explanation_label.text = result.get("explanation", "")
			explanation_label.visible = true
		if close_button:
			close_button.visible = true
		if submit_button:
			submit_button.disabled = true
		if answer_input:
			answer_input.editable = false
	else:
		# Allow retry
		if answer_input:
			answer_input.text = ""
			answer_input.grab_focus()


func _on_hint() -> void:
	hint_requested.emit()


func show_hint(hint_data: Dictionary) -> void:
	if feedback_label:
		feedback_label.visible = true
		feedback_label.text = hint_data.get("text", "")
		feedback_label.add_theme_color_override("font_color", Color(0.4, 0.6, 0.9))


func _on_close() -> void:
	visible = false
	_current_task = {}
	if submit_button:
		submit_button.disabled = false
	if answer_input:
		answer_input.editable = true
	task_closed.emit()
