extends Node2D
## JungleMap — The full 55-region world map with fog of war.

signal region_selected(region_id: String)

const MAP_SIZE := Vector2(2048, 1536)
const MARKER_SIZE := Vector2(48, 48)

var region_markers: Dictionary = {}  # region_id -> MarkerNode
var _camera: Camera2D
var _fog_image: Image
var _fog_texture: ImageTexture
var _fog_sprite: Sprite2D

# Region positions on the map (simplified layout for MVP)
const REGION_POSITIONS := {
	"level_01": Vector2(1024, 1300),
	"level_02": Vector2(1200, 1250),
	"level_03": Vector2(1380, 1200),
	"level_04": Vector2(1300, 1080),
	"level_05": Vector2(1100, 1050),
	"level_06": Vector2(950, 1000),
}


func _ready() -> void:
	_setup_camera()
	_setup_fog()
	_create_region_markers()
	_update_fog()
	_draw_connections()


func _setup_camera() -> void:
	_camera = Camera2D.new()
	_camera.position = MAP_SIZE / 2
	_camera.zoom = Vector2(0.6, 0.6)
	_camera.position_smoothing_enabled = true
	add_child(_camera)
	_camera.make_current()


func _setup_fog() -> void:
	# Create fog of war as a dark overlay with holes for revealed regions
	_fog_image = Image.create(int(MAP_SIZE.x), int(MAP_SIZE.y), false, Image.FORMAT_RGBA8)
	_fog_image.fill(Color(0.03, 0.06, 0.03, 0.85))  # Dark jungle fog
	_fog_texture = ImageTexture.create_from_image(_fog_image)

	_fog_sprite = Sprite2D.new()
	_fog_sprite.texture = _fog_texture
	_fog_sprite.position = MAP_SIZE / 2
	_fog_sprite.z_index = 10
	add_child(_fog_sprite)


func _create_region_markers() -> void:
	var all_levels = ContentLoader.get_all_levels()

	for region_id in REGION_POSITIONS.keys():
		var pos = REGION_POSITIONS[region_id]
		var marker = _create_marker(region_id, pos)
		region_markers[region_id] = marker
		add_child(marker)


func _create_marker(region_id: String, pos: Vector2) -> Node2D:
	var marker = Node2D.new()
	marker.position = pos
	marker.name = region_id

	# Visual representation
	var bg = ColorRect.new()
	bg.size = MARKER_SIZE
	bg.position = -MARKER_SIZE / 2
	bg.mouse_filter = Control.MOUSE_FILTER_STOP

	# Color based on state
	if GameManager.is_region_restored(region_id):
		bg.color = Color(0.2, 0.8, 0.3, 0.9)  # Vibrant green
	elif GameManager.is_region_completed(region_id):
		bg.color = Color(0.6, 0.7, 0.3, 0.9)  # Yellow-green
	elif GameManager.is_region_available(region_id):
		bg.color = Color(0.5, 0.5, 0.4, 0.9)  # Muted available
	else:
		bg.color = Color(0.2, 0.2, 0.2, 0.5)  # Locked
		marker.visible = false  # Hidden by fog

	marker.add_child(bg)

	# Label
	var label = Label.new()
	var level_data = ContentLoader.get_level_data(region_id)
	label.text = level_data.get("region_name", region_id)
	label.position = Vector2(-40, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color.WHITE)
	marker.add_child(label)

	# Click detection
	var click_area = Button.new()
	click_area.flat = true
	click_area.size = MARKER_SIZE + Vector2(20, 20)
	click_area.position = -(MARKER_SIZE + Vector2(20, 20)) / 2
	click_area.pressed.connect(_on_marker_clicked.bind(region_id))
	click_area.mouse_filter = Control.MOUSE_FILTER_STOP
	marker.add_child(click_area)

	# Mastery stars
	var stars_label = Label.new()
	var mastery = _get_region_mastery(region_id)
	stars_label.text = "*".repeat(mastery)
	stars_label.position = Vector2(-12, -30)
	stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	marker.add_child(stars_label)

	return marker


func _get_region_mastery(region_id: String) -> int:
	# Calculate 0-3 stars based on skill mastery for this region
	var level_data = ContentLoader.get_level_data(region_id)
	var skill_tags = level_data.get("skill_tags", [])
	if skill_tags.is_empty():
		return 0

	var total_mastery := 0
	for tag in skill_tags:
		total_mastery += GameManager.get_mastery_level(tag)

	var avg = float(total_mastery) / skill_tags.size()
	if avg >= 3.5: return 3
	elif avg >= 2.0: return 2
	elif avg >= 1.0: return 1
	return 0


func _update_fog() -> void:
	# Clear fog around revealed regions
	_fog_image.fill(Color(0.03, 0.06, 0.03, 0.85))

	for region_id in GameManager.regions.keys():
		if region_id in REGION_POSITIONS:
			var pos = REGION_POSITIONS[region_id]
			_clear_fog_circle(pos, 120)

			# Show the marker
			if region_id in region_markers:
				region_markers[region_id].visible = true

	_fog_texture.update(_fog_image)


func _clear_fog_circle(center: Vector2, radius: int) -> void:
	for x in range(maxi(0, int(center.x) - radius), mini(int(MAP_SIZE.x), int(center.x) + radius)):
		for y in range(maxi(0, int(center.y) - radius), mini(int(MAP_SIZE.y), int(center.y) + radius)):
			var dist = Vector2(x, y).distance_to(center)
			if dist < radius:
				var alpha = clampf(dist / radius, 0.0, 1.0) * 0.85
				var current = _fog_image.get_pixel(x, y)
				if alpha < current.a:
					_fog_image.set_pixel(x, y, Color(current.r, current.g, current.b, alpha))


func _draw_connections() -> void:
	# Draw paths between connected regions
	var all_levels = ContentLoader.get_all_levels()
	for region_id in REGION_POSITIONS.keys():
		var level_data = ContentLoader.get_level_data(region_id)
		var connections = level_data.get("connections", {})
		var from_pos = REGION_POSITIONS[region_id]

		for direction in ["north", "south", "east", "west"]:
			var target = connections.get(direction)
			if target and target is String and target in REGION_POSITIONS:
				var to_pos = REGION_POSITIONS[target]
				var line = Line2D.new()
				line.add_point(from_pos)
				line.add_point(to_pos)
				line.width = 3.0
				line.default_color = Color(0.4, 0.3, 0.2, 0.6)
				line.z_index = -1
				add_child(line)


func _on_marker_clicked(region_id: String) -> void:
	if GameManager.is_region_available(region_id):
		region_selected.emit(region_id)
		SceneManager.change_scene_to_region(region_id)


func _unhandled_input(event: InputEvent) -> void:
	# Camera pan and zoom
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		_camera.position -= event.relative / _camera.zoom

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.zoom *= 1.1
			_camera.zoom = _camera.zoom.clamp(Vector2(0.3, 0.3), Vector2(2.0, 2.0))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.zoom *= 0.9
			_camera.zoom = _camera.zoom.clamp(Vector2(0.3, 0.3), Vector2(2.0, 2.0))

	if event.is_action_pressed("pause"):
		SceneManager.go_to_title()
