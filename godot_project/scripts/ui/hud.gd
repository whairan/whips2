extends CanvasLayer
## HUD — Minimal gameplay overlay with region name, collectibles, quick buttons.

@onready var region_label: Label = $RegionLabel
@onready var collectible_counter: Label = $CollectibleCounter
@onready var map_button: Button = $ButtonBar/MapButton
@onready var reference_button: Button = $ButtonBar/ReferenceButton
@onready var whiteboard_button: Button = $ButtonBar/WhiteboardButton
@onready var settings_button: Button = $ButtonBar/SettingsButton

var _region_fade_timer: float = 0.0


func _ready() -> void:
	layer = 50

	if map_button:
		map_button.pressed.connect(func(): SceneManager.go_to_map())
	if whiteboard_button:
		whiteboard_button.pressed.connect(func(): Input.action_press("toggle_whiteboard"))
	if settings_button:
		settings_button.pressed.connect(func(): SceneManager.go_to_settings())

	GameManager.region_entered.connect(_on_region_entered)
	_update_collectible_count()


func _process(delta: float) -> void:
	# Fade region label after 3 seconds
	if _region_fade_timer > 0:
		_region_fade_timer -= delta
		if _region_fade_timer <= 0 and region_label:
			var tween = create_tween()
			tween.tween_property(region_label, "modulate:a", 0.0, 1.0)


func _on_region_entered(region_id: String) -> void:
	var level_data = ContentLoader.get_level_data(region_id)
	if region_label:
		region_label.text = level_data.get("region_name", region_id)
		region_label.modulate.a = 1.0
		_region_fade_timer = 3.0
	_update_collectible_count()


func _update_collectible_count() -> void:
	if collectible_counter:
		var count = GameManager.inventory.get("collectibles", []).size()
		collectible_counter.text = str(count)
