extends Node
## SceneManager — Handles scene transitions with fade effects.

signal transition_started
signal transition_finished

var _current_scene: Node = null
var _transition_layer: CanvasLayer
var _transition_rect: ColorRect
var _is_transitioning: bool = false

const FADE_DURATION := 0.3


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_transition_layer()
	# Get the initial scene
	var root = get_tree().root
	_current_scene = root.get_child(root.get_child_count() - 1)


func _setup_transition_layer() -> void:
	_transition_layer = CanvasLayer.new()
	_transition_layer.layer = 128  # Always on top
	add_child(_transition_layer)

	_transition_rect = ColorRect.new()
	_transition_rect.color = Color(0.05, 0.08, 0.05, 1.0)  # Dark jungle green
	_transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_rect.modulate.a = 0.0
	_transition_layer.add_child(_transition_rect)


func change_scene(scene_path: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	transition_started.emit()

	# Fade out
	var tween = create_tween()
	tween.tween_property(_transition_rect, "modulate:a", 1.0, FADE_DURATION)
	await tween.finished

	# Change scene
	if _current_scene:
		_current_scene.queue_free()

	var new_scene = load(scene_path)
	if new_scene:
		_current_scene = new_scene.instantiate()
		get_tree().root.add_child(_current_scene)
		get_tree().current_scene = _current_scene

	# Fade in
	var tween2 = create_tween()
	tween2.tween_property(_transition_rect, "modulate:a", 0.0, FADE_DURATION)
	await tween2.finished

	_is_transitioning = false
	transition_finished.emit()


func change_scene_to_region(region_id: String) -> void:
	# Map region_id to scene path
	var level_num = region_id.replace("level_", "").to_int()
	var zone_num = 1
	if level_num <= 6: zone_num = 1
	elif level_num <= 14: zone_num = 2
	elif level_num <= 24: zone_num = 3
	elif level_num <= 33: zone_num = 4
	elif level_num <= 38: zone_num = 5
	elif level_num <= 44: zone_num = 6
	elif level_num <= 50: zone_num = 7
	else: zone_num = 8

	var scene_path = "res://scenes/regions/zone_%d/region_%02d.tscn" % [zone_num, level_num]
	# Check if the specific scene exists; if not, use the generic region base
	if not ResourceLoader.exists(scene_path):
		scene_path = "res://scenes/regions/region_base.tscn"

	GameManager.enter_region(region_id)
	change_scene(scene_path)


func go_to_title() -> void:
	change_scene("res://scenes/menus/title_screen.tscn")


func go_to_profile_select() -> void:
	change_scene("res://scenes/menus/profile_select.tscn")


func go_to_map() -> void:
	change_scene("res://scenes/map/jungle_map.tscn")


func go_to_settings() -> void:
	change_scene("res://scenes/menus/settings.tscn")
