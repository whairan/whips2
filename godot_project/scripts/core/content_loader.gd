extends Node
## ContentLoader — Loads content data from JSON files.
## Supports hot-reload in development by watching for file changes.

signal content_reloaded(content_type: String)

var _content_cache: Dictionary = {}
var _content_base_path: String = ""


func _ready() -> void:
	# Determine content path — look for external content dir first (dev mode),
	# then fall back to bundled resources
	var external_path = OS.get_executable_path().get_base_dir().path_join("../../content")
	if DirAccess.dir_exists_absolute(external_path):
		_content_base_path = external_path
		print("ContentLoader: Using external content at %s" % external_path)
	else:
		_content_base_path = "res://resources/generated"
		print("ContentLoader: Using bundled content")

	_load_all_content()


func _load_all_content() -> void:
	_load_directory("zones")
	_load_directory("levels")
	_load_directory("tasks")
	_load_directory("reference_pages")
	_load_directory("dialogues")


func _load_directory(subdir: String) -> void:
	var dir_path = _content_base_path.path_join(subdir)
	var dir = DirAccess.open(dir_path)
	if not dir:
		push_warning("ContentLoader: Directory not found: %s" % dir_path)
		return

	if subdir not in _content_cache:
		_content_cache[subdir] = {}

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			var file_path = dir_path.path_join(file_name)
			var data = _load_json_file(file_path)
			if data != null:
				# Handle arrays (task banks) and objects
				if data is Array:
					for item in data:
						var id_key = _get_id_key(subdir)
						if id_key and id_key in item:
							_content_cache[subdir][item[id_key]] = item
				elif data is Dictionary:
					var id_key = _get_id_key(subdir)
					if id_key and id_key in data:
						_content_cache[subdir][data[id_key]] = data
		file_name = dir.get_next()
	dir.list_dir_end()


func _get_id_key(subdir: String) -> String:
	match subdir:
		"zones": return "zone_id"
		"levels": return "level_id"
		"tasks": return "task_id"
		"reference_pages": return "page_id"
		"dialogues": return "dialogue_id"
		_: return ""


func _load_json_file(path: String) -> Variant:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_warning("ContentLoader: Cannot open %s" % path)
		return null

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("ContentLoader: JSON parse error in %s: %s" % [path, json.get_error_message()])
		return null

	return json.data


# --- Public API ---

func get_zone_data(zone_id: String) -> Dictionary:
	return _content_cache.get("zones", {}).get(zone_id, {})


func get_level_data(level_id: String) -> Dictionary:
	return _content_cache.get("levels", {}).get(level_id, {})


func get_task_data(task_id: String) -> Dictionary:
	return _content_cache.get("tasks", {}).get(task_id, {})


func get_reference_page(page_id: String) -> Dictionary:
	return _content_cache.get("reference_pages", {}).get(page_id, {})


func get_dialogue(dialogue_id: String) -> Dictionary:
	return _content_cache.get("dialogues", {}).get(dialogue_id, {})


func get_all_levels() -> Dictionary:
	return _content_cache.get("levels", {})


func get_all_reference_pages() -> Dictionary:
	return _content_cache.get("reference_pages", {})


func get_tasks_for_skill(skill_tag: String) -> Array:
	var result: Array = []
	for task in _content_cache.get("tasks", {}).values():
		if skill_tag in task.get("skill_tags", []):
			result.append(task)
	return result


func get_tasks_for_level(level_id: String) -> Array:
	var level_data = get_level_data(level_id)
	if level_data.is_empty():
		return []

	var result: Array = []
	var quest = level_data.get("quest_line", {})
	var task_ids: Array = []

	# Collect all task IDs from the quest line
	var warmup = quest.get("warmup", "")
	if warmup: task_ids.append(warmup)
	task_ids.append_array(quest.get("teach", []))
	task_ids.append_array(quest.get("practice", []))
	task_ids.append_array(quest.get("apply", []))
	var boss = quest.get("boss", "")
	if boss: task_ids.append(boss)

	for tid in task_ids:
		var task = get_task_data(tid)
		if not task.is_empty():
			result.append(task)

	return result


## Hot reload support — call from editor plugin or dev tools
func reload_content(subdir: String = "") -> void:
	if subdir.is_empty():
		_content_cache.clear()
		_load_all_content()
		content_reloaded.emit("all")
	else:
		_content_cache[subdir] = {}
		_load_directory(subdir)
		content_reloaded.emit(subdir)
	print("ContentLoader: Content reloaded (%s)" % (subdir if subdir else "all"))
