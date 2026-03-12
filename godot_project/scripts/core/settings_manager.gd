extends Node
## SettingsManager — Accessibility and display settings.

signal settings_changed

# Accessibility
var high_contrast: bool = false
var reduced_motion: bool = false
var calm_mode: bool = false
var color_blind_mode: String = "none"  # "none", "deuteranopia", "protanopia", "tritanopia"
var font_size: String = "medium"       # "small", "medium", "large"

# Audio
var master_volume: float = 1.0
var music_volume: float = 0.4
var sfx_volume: float = 0.7
var ambient_volume: float = 0.5

# Gameplay
var hint_level: String = "normal"      # "minimal", "normal", "generous"
var difficulty: String = "adaptive"    # "adaptive", "sprout", "sapling", "tree"
var show_timer: bool = false


func _ready() -> void:
	_load_settings()


func get_settings_data() -> Dictionary:
	return {
		"accessibility": {
			"high_contrast": high_contrast,
			"reduced_motion": reduced_motion,
			"calm_mode": calm_mode,
			"color_blind_mode": color_blind_mode,
			"font_size": font_size
		},
		"audio": {
			"master_volume": master_volume,
			"music_volume": music_volume,
			"sfx_volume": sfx_volume,
			"ambient_volume": ambient_volume
		},
		"gameplay": {
			"hint_level": hint_level,
			"difficulty": difficulty,
			"show_timer": show_timer
		}
	}


func apply_settings(data: Dictionary) -> void:
	var acc = data.get("accessibility", {})
	high_contrast = acc.get("high_contrast", false)
	reduced_motion = acc.get("reduced_motion", false)
	calm_mode = acc.get("calm_mode", false)
	color_blind_mode = acc.get("color_blind_mode", "none")
	font_size = acc.get("font_size", "medium")

	var audio = data.get("audio", {})
	master_volume = audio.get("master_volume", 1.0)
	music_volume = audio.get("music_volume", 0.4)
	sfx_volume = audio.get("sfx_volume", 0.7)
	ambient_volume = audio.get("ambient_volume", 0.5)

	var gameplay = data.get("gameplay", {})
	hint_level = gameplay.get("hint_level", "normal")
	difficulty = gameplay.get("difficulty", "adaptive")
	show_timer = gameplay.get("show_timer", false)

	_apply_audio_bus_volumes()
	settings_changed.emit()


func set_high_contrast(enabled: bool) -> void:
	high_contrast = enabled
	settings_changed.emit()


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	settings_changed.emit()


func set_calm_mode(enabled: bool) -> void:
	calm_mode = enabled
	GameManager.in_calm_mode = enabled
	settings_changed.emit()


func set_color_blind_mode(mode: String) -> void:
	color_blind_mode = mode
	settings_changed.emit()


func set_font_size(size: String) -> void:
	font_size = size
	settings_changed.emit()


func get_font_scale() -> float:
	match font_size:
		"small": return 0.85
		"large": return 1.25
		_: return 1.0


func _apply_audio_bus_volumes() -> void:
	# Apply volumes to audio buses if they exist
	var master_idx = AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))

	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))

	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume))


func _load_settings() -> void:
	var path = "user://settings.json"
	if not FileAccess.file_exists(path):
		return

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return

	var json = JSON.new()
	if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
		apply_settings(json.data)
	file.close()


func save_settings() -> void:
	var path = "user://settings.json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(get_settings_data(), "\t"))
		file.close()
