extends Control
## Tool tray — collapsible panel showing available manipulatives.

signal tool_selected(tool_name: String)
signal tray_toggled(is_open: bool)

@export var start_collapsed: bool = true

var is_expanded: bool = false

# All possible tools and their scene paths
const TOOL_SCENES := {
	"counter_seeds": "res://scenes/toolkit/counter_seeds.tscn",
	"number_line_vine": "res://scenes/toolkit/number_line_vine.tscn",
	"ruler_tool": "res://scenes/toolkit/ruler_tool.tscn",
	"totem_array_grid": "res://scenes/toolkit/totem_array_grid.tscn",
	"fraction_bamboo": "res://scenes/toolkit/fraction_bamboo.tscn",
	"algebra_tablets": "res://scenes/toolkit/algebra_tablets.tscn",
}

@onready var toggle_button: Button = $ToggleButton
@onready var tools_container: VBoxContainer = $ToolsContainer


func _ready() -> void:
	is_expanded = not start_collapsed
	_update_visibility()
	_populate_tools()

	if toggle_button:
		toggle_button.pressed.connect(_on_toggle)


func _populate_tools() -> void:
	if not tools_container:
		return

	# Clear existing
	for child in tools_container.get_children():
		child.queue_free()

	# Add buttons for unlocked tools
	for tool_name in TOOL_SCENES.keys():
		if GameManager.has_tool(tool_name):
			var btn = Button.new()
			btn.text = tool_name.replace("_", " ").capitalize()
			btn.custom_minimum_size = Vector2(140, 36)
			btn.pressed.connect(_on_tool_pressed.bind(tool_name))
			tools_container.add_child(btn)


func _on_toggle() -> void:
	is_expanded = not is_expanded
	_update_visibility()
	tray_toggled.emit(is_expanded)


func _on_tool_pressed(tool_name: String) -> void:
	tool_selected.emit(tool_name)


func _update_visibility() -> void:
	if tools_container:
		tools_container.visible = is_expanded
	if toggle_button:
		toggle_button.text = "Tools <<" if is_expanded else "Tools >>"


func refresh() -> void:
	_populate_tools()
