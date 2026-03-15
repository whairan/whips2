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
	# Use GameManager's current region (set by SceneManager before scene load)
	if not GameManager.current_region.is_empty():
		region_id = GameManager.current_region
	_load_region_data()
	_spawn_interactables()
	_spawn_collectibles()
	_apply_saved_state()
	region_loaded.emit(region_id)


func _load_region_data() -> void:
	level_data = ContentLoader.get_level_data(region_id)
	if level_data.is_empty():
		push_warning("RegionManager: No data for region %s" % region_id)
		return

	# Connect TaskManager signals for quest tracking (deferred to let RegionController create it)
	_connect_task_manager_deferred.call_deferred()


func _connect_task_manager_deferred() -> void:
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


# --- Dynamic Interactable Spawning ---

func _spawn_interactables() -> void:
	if level_data.is_empty():
		return

	var container = get_node_or_null("../World/Interactables")
	if not container:
		container = get_node_or_null("World/Interactables")
	if not container:
		push_warning("RegionManager: No Interactables container found")
		return

	var interactables = level_data.get("interactables", [])
	for data in interactables:
		var type_name: String = data.get("type", "")
		var id: String = data.get("id", "")
		var pos_arr: Array = data.get("position", [0, 0])
		var pos := Vector2(pos_arr[0], pos_arr[1]) if pos_arr.size() >= 2 else Vector2.ZERO
		var props: Dictionary = data.get("properties", {})

		var node = _create_interactable(type_name, id, props)
		if node:
			node.position = pos
			node.name = id
			container.add_child(node)


func _create_interactable(type_name: String, id: String, props: Dictionary) -> Node2D:
	match type_name:
		"fruit_tree":
			return _create_fruit_tree(id, props)
		"rope_bridge":
			return _create_rope_bridge(id, props)
		"climbable_tree":
			return _create_climbable_tree(id, props)
		_:
			return _create_generic_interactable(type_name, id, props)


func _create_fruit_tree(id: String, props: Dictionary) -> FruitTree:
	var tree = FruitTree.new()
	tree.fruit_type = props.get("fruit_type", "mango")
	var count_range = props.get("count_range", [5, 5])
	tree.fruit_count = count_range[0] if count_range is Array and count_range.size() > 0 else 5
	tree.region_state_key = id

	# Create placeholder visuals
	_add_placeholder_visual(tree, Vector2(40, 60), Color(0.2, 0.5, 0.15), "tree")

	# Create fruit sprites container
	var fruit_container = Node2D.new()
	fruit_container.name = "FruitSprites"
	tree.add_child(fruit_container)
	var fruit_color = _get_fruit_color(tree.fruit_type)
	for i in range(tree.fruit_count):
		var fruit = ColorRect.new()
		fruit.size = Vector2(8, 8)
		fruit.color = fruit_color
		# Scatter fruit around the tree top
		var angle = (float(i) / tree.fruit_count) * TAU
		var radius = 12.0 + randf() * 8.0
		fruit.position = Vector2(cos(angle) * radius - 4, sin(angle) * radius - 40)
		fruit_container.add_child(fruit)

	# Collision shape for interaction
	_add_interaction_collision(tree, 30.0)
	return tree


func _create_rope_bridge(id: String, props: Dictionary) -> RopeBridge:
	var bridge = RopeBridge.new()
	var state_str = props.get("state", "broken")
	if state_str == "intact":
		bridge.bridge_state = RopeBridge.BridgeState.INTACT
	else:
		bridge.bridge_state = RopeBridge.BridgeState.BROKEN
	bridge.region_state_key = id

	# Create placeholder visuals — broken and intact versions
	var broken_visual = ColorRect.new()
	broken_visual.name = "BrokenSprite"
	broken_visual.size = Vector2(120, 6)
	broken_visual.position = Vector2(-60, -3)
	broken_visual.color = Color(0.4, 0.25, 0.15, 0.5)
	bridge.add_child(broken_visual)

	var intact_visual = ColorRect.new()
	intact_visual.name = "IntactSprite"
	intact_visual.size = Vector2(120, 8)
	intact_visual.position = Vector2(-60, -4)
	intact_visual.color = Color(0.5, 0.35, 0.2, 1.0)
	intact_visual.visible = bridge.bridge_state == RopeBridge.BridgeState.INTACT
	bridge.add_child(intact_visual)

	# Bridge body (walkable surface when intact)
	var body = StaticBody2D.new()
	body.name = "BridgeBody"
	body.collision_layer = 1
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(120, 6)
	shape.shape = rect
	body.add_child(shape)
	bridge.add_child(body)
	if bridge.bridge_state == RopeBridge.BridgeState.BROKEN:
		body.process_mode = Node.PROCESS_MODE_DISABLED

	_add_interaction_collision(bridge, 40.0)
	return bridge


func _create_climbable_tree(id: String, props: Dictionary) -> ClimbableSurface:
	var surface = ClimbableSurface.new()
	surface.surface_type = props.get("surface_type", "tree")

	# Vertical brown rect as tree trunk
	var visual = ColorRect.new()
	visual.size = Vector2(16, 80)
	visual.position = Vector2(-8, -80)
	visual.color = Color(0.4, 0.28, 0.15)
	surface.add_child(visual)

	# Collision shape for climbing detection
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(20, 80)
	shape.shape = rect
	shape.position = Vector2(0, -40)
	surface.add_child(shape)

	return surface


func _create_generic_interactable(type_name: String, id: String, props: Dictionary) -> InteractableBase:
	var node = InteractableBase.new()
	node.prompt_text = "[E] %s" % type_name.replace("_", " ").capitalize()
	node.region_state_key = id

	# Color-coded by type
	var color := Color(0.5, 0.5, 0.5)
	match type_name:
		"berry_bush":
			color = Color(0.6, 0.2, 0.3)
		"stone_pile":
			color = Color(0.5, 0.5, 0.45)
		"seed_pouch":
			color = Color(0.6, 0.5, 0.3)
		"counting_birds":
			color = Color(0.3, 0.5, 0.7)
		"leaf_pile":
			color = Color(0.3, 0.6, 0.2)
		"butterfly_cluster":
			color = Color(0.7, 0.5, 0.8)

	_add_placeholder_visual(node, Vector2(24, 24), color, type_name)
	_add_interaction_collision(node, 24.0)

	# Add a type label
	var label = Label.new()
	label.text = type_name.replace("_", " ")
	label.position = Vector2(-30, -40)
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color.WHITE)
	node.add_child(label)

	return node


func _add_placeholder_visual(node: Node2D, size: Vector2, color: Color, _type: String) -> void:
	var visual = ColorRect.new()
	visual.size = size
	visual.position = -size / 2.0
	visual.color = color
	node.add_child(visual)


func _add_interaction_collision(node: Area2D, radius: float) -> void:
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	node.add_child(shape)


func _get_fruit_color(fruit_type: String) -> Color:
	match fruit_type:
		"mango": return Color(1.0, 0.8, 0.2)
		"coconut": return Color(0.6, 0.45, 0.3)
		"berry": return Color(0.7, 0.15, 0.2)
		_: return Color(0.8, 0.6, 0.2)


# --- Collectible Spawning ---

func _spawn_collectibles() -> void:
	if level_data.is_empty():
		return

	var container = get_node_or_null("../World/Collectibles")
	if not container:
		container = get_node_or_null("World/Collectibles")
	if not container:
		return

	var collectible_ids = level_data.get("rewards", {}).get("collectibles", [])
	for i in range(collectible_ids.size()):
		var cid: String = collectible_ids[i]
		var collectible = Collectible.new()
		collectible.collectible_id = cid

		# Spread collectibles across the region
		var x_pos = 150.0 + (float(i) / maxf(collectible_ids.size() - 1, 1)) * 900.0
		collectible.position = Vector2(x_pos, 380 + randf() * 80)

		# Visual — golden seed
		var visual = ColorRect.new()
		visual.size = Vector2(10, 10)
		visual.position = Vector2(-5, -5)
		visual.color = Color(1.0, 0.85, 0.0)
		collectible.add_child(visual)

		# Collision shape
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 12.0
		shape.shape = circle
		collectible.add_child(shape)

		collectible.name = cid
		container.add_child(collectible)


# --- Quest Management ---

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

	# Find the target node in the interactables
	var container = get_node_or_null("../World/Interactables")
	if not container:
		container = get_node_or_null("World/Interactables")
	if container:
		var target = container.get_node_or_null(target_id)
		if target:
			if target.has_method("rebuild"):
				target.rebuild()
			elif target.has_method("activate"):
				target.activate()
			return

	# Fallback: search direct children
	for child in get_children():
		if child.name == target_id:
			if child.has_method("rebuild"):
				child.rebuild()
			elif child.has_method("activate"):
				child.activate()
			break


func _show_restored_state() -> void:
	if fog_overlay:
		fog_overlay.color = Color.WHITE
	modulate = Color.WHITE


func _show_completed_state() -> void:
	if fog_overlay:
		fog_overlay.color = Color(0.9, 0.95, 0.9)


func _animate_restoration() -> void:
	if fog_overlay:
		var tween = create_tween()
		tween.tween_property(fog_overlay, "color", Color.WHITE, 3.0)

	if restoration_particles:
		restoration_particles.emitting = true

	var tween2 = create_tween()
	tween2.tween_property(self, "modulate", Color.WHITE, 2.0)


func _get_task_manager():
	# TaskManager is created by RegionController as a child node
	var controller = get_node_or_null("RegionController")
	if controller:
		var tm = controller.get_node_or_null("TaskManager")
		if tm:
			return tm
	# Fallback: search siblings
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child.name == "RegionController":
				var tm = child.get_node_or_null("TaskManager")
				if tm:
					return tm
	return null
