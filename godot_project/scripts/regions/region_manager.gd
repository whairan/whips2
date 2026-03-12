class_name RegionManager
extends Node2D
## Manages a region's lifecycle: loads data, connects interactables, tracks quests, handles restoration.

signal region_loaded(region_id: String)
signal quest_stage_complete(stage: String)
signal region_complete
signal region_restored

@export var region_id: String = "level_01"

var level_data: Dictionary = {}
var quest_stages_done: Dictionary = {}
var is_complete: bool = false
var is_restored: bool = false

@onready var fog_overlay: CanvasModulate = $FogOverlay if has_node("FogOverlay") else null
@onready var restoration_particles: GPUParticles2D = $RestorationParticles if has_node("RestorationParticles") else null


func _ready() -> void:
	_load_region_data()
	_apply_saved_state()
	region_loaded.emit(region_id)


func _load_region_data() -> void:
	level_data = ContentLoader.get_level_data(region_id)
	if level_data.is_empty():
		push_warning("RegionManager: No data for region %s" % region_id)
		return

	# Connect TaskManager signals for quest tracking
	var tm = _get_task_manager()
	if tm:
		if not tm.task_completed.is_connected(_on_task_completed):
			tm.task_completed.connect(_on_task_completed)


func _apply_saved_state() -> void:
	var region_save = GameManager.regions.get(region_id, {})
	is_complete = region_save.get("completed", false)
	is_restored = region_save.get("restored", false)

	if is_restored:
		_show_restored_state()
	elif is_complete:
		_show_completed_state()

	# Mark collected collectibles as already collected
	var saved_collectibles = region_save.get("collectibles", [])
	for collectible_node in get_tree().get_nodes_in_group("collectible"):
		if collectible_node is Collectible and collectible_node.collectible_id in saved_collectibles:
			collectible_node.is_collected = true
			collectible_node.visible = false


func start_quest() -> void:
	var quest = level_data.get("quest_line", {})
	var warmup = quest.get("warmup", "")
	if warmup and not quest_stages_done.get("warmup", false):
		var tm = _get_task_manager()
		if tm:
			tm.start_task(warmup)


func start_task(task_id: String) -> void:
	var tm = _get_task_manager()
	if tm:
		tm.start_task(task_id)


func _on_task_completed(task_id: String, correct: bool) -> void:
	if not correct:
		return

	var quest = level_data.get("quest_line", {})

	# Check which quest stage this task belongs to
	if task_id == quest.get("warmup", ""):
		quest_stages_done["warmup"] = true
		quest_stage_complete.emit("warmup")

	if task_id in quest.get("teach", []):
		quest_stages_done["teach_" + task_id] = true
		if _all_done(quest.get("teach", []), "teach_"):
			quest_stage_complete.emit("teach")

	if task_id in quest.get("practice", []):
		quest_stages_done["practice_" + task_id] = true

	if task_id in quest.get("apply", []):
		quest_stages_done["apply_" + task_id] = true

	if task_id == quest.get("boss", ""):
		quest_stages_done["boss"] = true
		_complete_region()

	# Check eco puzzle
	var eco = level_data.get("eco_puzzle", {})
	if task_id == eco.get("task_ref", ""):
		_trigger_eco_effect()


func _all_done(task_ids: Array, prefix: String) -> bool:
	for tid in task_ids:
		if not quest_stages_done.get(prefix + tid, false):
			return false
	return true


func _complete_region() -> void:
	is_complete = true
	GameManager.complete_region(region_id)

	# Apply rewards
	var rewards = level_data.get("rewards", {})
	var tool = rewards.get("tool_unlock")
	if tool and tool is String:
		GameManager.unlock_tool(tool)
	var traversal = rewards.get("traversal_unlock")
	if traversal and traversal is String:
		GameManager.unlock_traversal(traversal)
	for page_id in rewards.get("reference_pages", []):
		GameManager.unlock_reference_page(page_id)

	region_complete.emit()
	_restore_region()


func _restore_region() -> void:
	is_restored = true
	GameManager.restore_region(region_id)
	_animate_restoration()
	region_restored.emit()


func _trigger_eco_effect() -> void:
	var eco = level_data.get("eco_puzzle", {})
	var on_solve = eco.get("on_solve", {})
	var target_id = on_solve.get("target", "")
	var effect = on_solve.get("effect", "")

	# Find the target node in the scene
	for child in get_children():
		if child.name == target_id or (child.has_method("get") and child.get("id") == target_id):
			if child.has_method("rebuild"):
				child.rebuild()
			elif child.has_method("activate"):
				child.activate()
			break


func _show_restored_state() -> void:
	# Full color, wildlife active, fog cleared
	if fog_overlay:
		fog_overlay.color = Color.WHITE
	modulate = Color.WHITE


func _show_completed_state() -> void:
	# Mostly restored but not fully vibrant yet
	if fog_overlay:
		fog_overlay.color = Color(0.9, 0.95, 0.9)


func _animate_restoration() -> void:
	# Fog dissolve
	if fog_overlay:
		var tween = create_tween()
		tween.tween_property(fog_overlay, "color", Color.WHITE, 3.0)

	# Restoration particles
	if restoration_particles:
		restoration_particles.emitting = true

	# Brighten region
	var tween2 = create_tween()
	tween2.tween_property(self, "modulate", Color.WHITE, 2.0)


func _get_task_manager():
	# TaskManager may be a child of the current scene or a singleton
	return get_node_or_null("/root/TaskManager")
