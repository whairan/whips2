extends Node
## GameManager — Global state singleton (autoload)
## Manages game state, profile data, and coordinates between systems.

signal profile_loaded(profile_name: String)
signal region_entered(region_id: String)
signal region_completed(region_id: String)
signal region_restored(region_id: String)
signal task_completed(task_id: String, correct: bool)
signal skill_leveled_up(skill_tag: String, new_level: int)
signal reward_unlocked(reward_id: String, category: String)
signal tool_unlocked(tool_name: String)
signal traversal_unlocked(ability_name: String)

# Current state
var current_profile: String = ""
var current_region: String = ""
var game_state: Dictionary = {}

# Profile data (loaded from save)
var mastery: Dictionary = {}          # skill_tag -> {level, streak, attempts, correct, ...}
var regions: Dictionary = {}          # region_id -> {completed, restored, collectibles}
var unlocks: Dictionary = {           # What's been unlocked
	"tools": [],
	"traversal": [],
	"reference_pages": [],
	"cosmetics": []
}
var inventory: Dictionary = {         # Player inventory
	"fruits": {},
	"collectibles": []
}

# Runtime flags
var whiteboard_open: bool = false
var puzzle_active: bool = false
var in_calm_mode: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func new_profile(profile_name: String) -> void:
	current_profile = profile_name
	mastery = {}
	regions = {}
	unlocks = {"tools": [], "traversal": [], "reference_pages": [], "cosmetics": []}
	inventory = {"fruits": {}, "collectibles": []}
	# Level 01 always starts revealed
	regions["level_01"] = {"completed": false, "restored": false, "collectibles": []}
	SaveSystem.save_game(current_profile)
	profile_loaded.emit(profile_name)


func load_profile(profile_name: String) -> bool:
	var data = SaveSystem.load_game(profile_name)
	if data.is_empty():
		return false
	current_profile = profile_name
	mastery = data.get("mastery", {})
	regions = data.get("regions", {})
	unlocks = data.get("unlocks", {"tools": [], "traversal": [], "reference_pages": [], "cosmetics": []})
	inventory = data.get("inventory", {"fruits": {}, "collectibles": []})
	profile_loaded.emit(profile_name)
	return true


func get_save_data() -> Dictionary:
	return {
		"version": 1,
		"profile": {
			"name": current_profile,
			"created": Time.get_datetime_string_from_system()
		},
		"mastery": mastery,
		"regions": regions,
		"unlocks": unlocks,
		"inventory": inventory,
		"settings": SettingsManager.get_settings_data()
	}


# --- Region Management ---

func enter_region(region_id: String) -> void:
	current_region = region_id
	if region_id not in regions:
		regions[region_id] = {"completed": false, "restored": false, "collectibles": []}
	region_entered.emit(region_id)


func complete_region(region_id: String) -> void:
	if region_id in regions:
		regions[region_id]["completed"] = true
		region_completed.emit(region_id)
		_reveal_adjacent_regions(region_id)
		SaveSystem.save_game(current_profile)


func restore_region(region_id: String) -> void:
	if region_id in regions:
		regions[region_id]["restored"] = true
		region_restored.emit(region_id)
		SaveSystem.save_game(current_profile)


func is_region_available(region_id: String) -> bool:
	return region_id in regions


func is_region_completed(region_id: String) -> bool:
	return regions.get(region_id, {}).get("completed", false)


func is_region_restored(region_id: String) -> bool:
	return regions.get(region_id, {}).get("restored", false)


func _reveal_adjacent_regions(region_id: String) -> void:
	var level_data = ContentLoader.get_level_data(region_id)
	if level_data.is_empty():
		return
	var connections = level_data.get("connections", {})
	for direction in ["north", "south", "east", "west"]:
		var target = connections.get(direction)
		if target and target is String and target not in regions:
			regions[target] = {"completed": false, "restored": false, "collectibles": []}


# --- Mastery ---

func record_task_result(skill_tags: Array, correct: bool, difficulty: int) -> void:
	for tag in skill_tags:
		if tag not in mastery:
			mastery[tag] = {"level": 0, "streak": 0, "attempts": 0, "correct": 0}
		var record = mastery[tag]
		record["attempts"] += 1
		if correct:
			record["correct"] += 1
			record["streak"] += 1
			_check_level_up(tag, record, difficulty)
		else:
			record["streak"] = 0
	SaveSystem.save_game(current_profile)


func get_mastery_level(skill_tag: String) -> int:
	return mastery.get(skill_tag, {}).get("level", 0)


func _check_level_up(tag: String, record: Dictionary, difficulty: int) -> void:
	var level = record["level"]
	var streak = record["streak"]
	var correct = record["correct"]
	var new_level = level

	if level == 0 and record["attempts"] >= 1:
		new_level = 1  # Introduced
	elif level == 1 and correct >= 3:
		new_level = 2  # Practiced
	elif level == 2 and correct >= 5 and streak >= 3 and difficulty >= 2:
		new_level = 3  # Proficient
	elif level == 3 and streak >= 5:
		new_level = 4  # Mastered

	if new_level > level:
		record["level"] = new_level
		skill_leveled_up.emit(tag, new_level)


# --- Unlocks ---

func unlock_tool(tool_name: String) -> void:
	if tool_name not in unlocks["tools"]:
		unlocks["tools"].append(tool_name)
		tool_unlocked.emit(tool_name)
		SaveSystem.save_game(current_profile)


func unlock_traversal(ability_name: String) -> void:
	if ability_name not in unlocks["traversal"]:
		unlocks["traversal"].append(ability_name)
		traversal_unlocked.emit(ability_name)
		SaveSystem.save_game(current_profile)


func unlock_reference_page(page_id: String) -> void:
	if page_id not in unlocks["reference_pages"]:
		unlocks["reference_pages"].append(page_id)
		SaveSystem.save_game(current_profile)


func has_tool(tool_name: String) -> bool:
	return tool_name in unlocks["tools"]


func has_traversal(ability_name: String) -> bool:
	return ability_name in unlocks["traversal"]


func has_reference_page(page_id: String) -> bool:
	return page_id in unlocks["reference_pages"]


# --- Collectibles ---

func add_collectible(region_id: String, collectible_id: String) -> void:
	if region_id in regions:
		var collectibles = regions[region_id].get("collectibles", [])
		if collectible_id not in collectibles:
			collectibles.append(collectible_id)
			regions[region_id]["collectibles"] = collectibles
			inventory["collectibles"].append(collectible_id)
			SaveSystem.save_game(current_profile)
