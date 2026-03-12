extends Node
## RegionController — Orchestrates the full gameplay loop within a region.
## Lives as a child of the region scene and wires:
##   Player interaction → TaskManager → TaskUI → grading → eco puzzle → region restore
##
## This is the central nervous system of each region.

var task_manager: Node
var task_ui: Node
var region_manager: RegionManager
var whiteboard: Node
var tool_tray: Node
var player: CharacterBody2D

var _current_task_data: Dictionary = {}
var _pending_eco_trigger: String = ""


func _ready() -> void:
	# Find siblings and children in the region scene tree
	region_manager = _find_typed_parent_or_sibling(RegionManager)
	task_ui = _find_node_in_tree("TaskUI")
	player = _find_node_in_tree("Player") as CharacterBody2D
	whiteboard = _find_node_in_tree("WhiteboardOverlay")
	tool_tray = _find_node_in_tree("ToolTray")

	# Create TaskManager as a local node (not autoload — per-region lifecycle)
	task_manager = preload("res://scripts/math/task_manager.gd").new()
	task_manager.name = "TaskManager"
	add_child(task_manager)

	_connect_signals()

	# Auto-start warmup quest when region loads
	if region_manager and not region_manager.is_complete:
		# Small delay so everything initializes
		await get_tree().create_timer(0.5).timeout
		_offer_quest_start()


func _connect_signals() -> void:
	# TaskManager signals
	if task_manager:
		task_manager.task_started.connect(_on_task_started)
		task_manager.task_completed.connect(_on_task_completed)

	# TaskUI signals
	if task_ui:
		if task_ui.has_signal("answer_submitted"):
			task_ui.answer_submitted.connect(_on_answer_submitted)
		if task_ui.has_signal("hint_requested"):
			task_ui.hint_requested.connect(_on_hint_requested)
		if task_ui.has_signal("task_closed"):
			task_ui.task_closed.connect(_on_task_closed)

	# Player interaction
	if player and player.has_signal("interacted_with"):
		player.interacted_with.connect(_on_player_interacted)

	# Region manager
	if region_manager:
		region_manager.region_complete.connect(_on_region_complete)
		region_manager.region_restored.connect(_on_region_restored)

	# Connect all interactables in the scene
	_connect_interactables()


func _connect_interactables() -> void:
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is FruitTree:
			node.harvest_requested.connect(_on_fruit_harvest.bind(node))
		elif node is InteractableBase:
			node.interacted.connect(_on_interactable_used.bind(node))


# --- Quest Flow ---

func _offer_quest_start() -> void:
	if not region_manager or region_manager.level_data.is_empty():
		return

	var quest = region_manager.level_data.get("quest_line", {})
	var warmup_id = quest.get("warmup", "")
	if warmup_id and not region_manager.quest_stages_done.get("warmup", false):
		# Start with warmup diagnostic
		_start_task(warmup_id)


func _start_task(task_id: String) -> void:
	if task_manager:
		task_manager.start_task(task_id)


# --- Signal handlers ---

func _on_task_started(task_data: Dictionary) -> void:
	_current_task_data = task_data
	GameManager.puzzle_active = true

	# Show task UI
	if task_ui and task_ui.has_method("show_task"):
		task_ui.visible = true
		task_ui.show_task(task_data)

	# Update tool tray with available tools for this task
	if tool_tray and tool_tray.has_method("refresh"):
		tool_tray.refresh()


func _on_answer_submitted(answer) -> void:
	if not task_manager:
		return

	var result = task_manager.submit_answer(answer)

	# Show result in UI
	if task_ui and task_ui.has_method("show_result"):
		task_ui.show_result(result)

	if result.get("correct", false):
		_handle_correct_answer()


func _on_hint_requested() -> void:
	if not task_manager:
		return

	var hint = task_manager.request_hint()
	if task_ui and task_ui.has_method("show_hint"):
		task_ui.show_hint(hint)


func _on_task_completed(task_id: String, correct: bool) -> void:
	# Forward to region manager for quest tracking
	if region_manager:
		region_manager._on_task_completed(task_id, correct)


func _on_task_closed() -> void:
	GameManager.puzzle_active = false
	_current_task_data = {}

	# Check if we should offer the next quest task
	_advance_quest()


func _handle_correct_answer() -> void:
	var task_id = _current_task_data.get("task_id", "")

	# Check if this task triggers an eco puzzle
	if region_manager:
		var eco = region_manager.level_data.get("eco_puzzle", {})
		if task_id == eco.get("task_ref", ""):
			_pending_eco_trigger = task_id


func _advance_quest() -> void:
	if not region_manager or region_manager.level_data.is_empty():
		return
	if region_manager.is_complete:
		return

	var quest = region_manager.level_data.get("quest_line", {})

	# Execute pending eco trigger
	if not _pending_eco_trigger.is_empty():
		region_manager._trigger_eco_effect()
		_pending_eco_trigger = ""

	# Find next uncompleted task in sequence
	var next_task = _find_next_quest_task(quest)
	if next_task:
		# Small delay between tasks
		await get_tree().create_timer(1.0).timeout
		_start_task(next_task)


func _find_next_quest_task(quest: Dictionary) -> String:
	# Check stages in order: warmup → teach → practice → apply → boss
	if not region_manager.quest_stages_done.get("warmup", false):
		var warmup = quest.get("warmup", "")
		if warmup:
			return warmup

	# Teach phase
	for tid in quest.get("teach", []):
		if not region_manager.quest_stages_done.get("teach_" + tid, false):
			return tid

	# Practice phase (player can choose — offer first uncompleted)
	for tid in quest.get("practice", []):
		if not region_manager.quest_stages_done.get("practice_" + tid, false):
			return tid

	# Apply phase
	for tid in quest.get("apply", []):
		if not region_manager.quest_stages_done.get("apply_" + tid, false):
			return tid

	# Boss
	if not region_manager.quest_stages_done.get("boss", false):
		var boss = quest.get("boss", "")
		if boss:
			return boss

	return ""


# --- Interactable handlers ---

func _on_player_interacted(interactable: Node2D) -> void:
	# Generic interactable — check if it triggers a task
	if interactable is InteractableBase and interactable.region_state_key:
		# Check if this interactable has a linked task in the quest
		pass  # Specific handling per interactable type


func _on_fruit_harvest(fruit_type: String, count: int, tree: FruitTree) -> void:
	# A fruit tree interaction — start a counting task
	# Find the appropriate task or generate one
	var quest = region_manager.level_data.get("quest_line", {}) if region_manager else {}
	var practice_tasks = quest.get("practice", [])

	# Start the first available practice task
	for tid in practice_tasks:
		if not region_manager.quest_stages_done.get("practice_" + tid, false):
			_start_task(tid)
			return

	# If all practice done, just count and harvest
	tree.harvest()


func _on_interactable_used(player_node: Node2D, interactable: InteractableBase) -> void:
	# Handle various interactable types
	pass


# --- Region events ---

func _on_region_complete() -> void:
	# Show completion celebration
	print("Region %s complete!" % region_manager.region_id)
	# Could show a reward screen here


func _on_region_restored() -> void:
	# Full restoration celebration
	print("Region %s restored!" % region_manager.region_id)


# --- Utility ---

func _find_typed_parent_or_sibling(type) -> Node:
	# Check parent
	var parent = get_parent()
	if parent is RegionManager:
		return parent
	# Check siblings
	if parent:
		for child in parent.get_children():
			if child is RegionManager:
				return child
	# Check if we ARE the region root
	if get_parent() and get_parent().has_method("get"):
		return get_parent()
	return null


func _find_node_in_tree(node_name: String) -> Node:
	# Search up the tree for named nodes
	var root = get_tree().root
	return _recursive_find(root, node_name)


func _recursive_find(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found = _recursive_find(child, target_name)
		if found:
			return found
	return null
