extends Node
## SaveSystem — Handles saving/loading player profiles to disk.

const SAVE_DIR := "user://saves/"
const SAVE_VERSION := 1


func _ready() -> void:
	# Ensure save directory exists
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func save_game(profile_name: String) -> bool:
	if profile_name.is_empty():
		return false

	var data = GameManager.get_save_data()
	var path = _get_save_path(profile_name)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("SaveSystem: Could not open file for writing: %s" % path)
		return false

	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	return true


func load_game(profile_name: String) -> Dictionary:
	var path = _get_save_path(profile_name)
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("SaveSystem: Could not open file for reading: %s" % path)
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("SaveSystem: JSON parse error: %s" % json.get_error_message())
		return {}

	var data = json.data
	if not data is Dictionary:
		push_error("SaveSystem: Invalid save data format")
		return {}

	# Run migrations if needed
	data = _migrate(data)
	return data


func delete_save(profile_name: String) -> bool:
	var path = _get_save_path(profile_name)
	if FileAccess.file_exists(path):
		return DirAccess.remove_absolute(path) == OK
	return false


func get_all_profiles() -> Array[String]:
	var profiles: Array[String] = []
	var dir = DirAccess.open(SAVE_DIR)
	if not dir:
		return profiles

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			profiles.append(file_name.trim_suffix(".json"))
		file_name = dir.get_next()
	dir.list_dir_end()

	profiles.sort()
	return profiles


func profile_exists(profile_name: String) -> bool:
	return FileAccess.file_exists(_get_save_path(profile_name))


func _get_save_path(profile_name: String) -> String:
	# Sanitize profile name for file system
	var safe_name = profile_name.to_lower().replace(" ", "_")
	safe_name = safe_name.strip_edges()
	return SAVE_DIR + safe_name + ".json"


func _migrate(data: Dictionary) -> Dictionary:
	var version = data.get("version", 0)

	if version < 1:
		data = _migrate_v0_to_v1(data)

	# Future migrations go here:
	# if version < 2:
	#     data = _migrate_v1_to_v2(data)

	return data


func _migrate_v0_to_v1(data: Dictionary) -> Dictionary:
	# Ensure all required keys exist
	if "mastery" not in data:
		data["mastery"] = {}
	if "regions" not in data:
		data["regions"] = {}
	if "unlocks" not in data:
		data["unlocks"] = {"tools": [], "traversal": [], "reference_pages": [], "cosmetics": []}
	if "inventory" not in data:
		data["inventory"] = {"fruits": {}, "collectibles": []}
	data["version"] = 1
	return data
