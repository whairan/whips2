extends Control
## Profile selection — create or load player profiles.

@onready var profile_list: ItemList = $VBox/ProfileList
@onready var new_profile_input: LineEdit = $VBox/HBox/NewProfileInput
@onready var create_button: Button = $VBox/HBox/CreateButton
@onready var load_button: Button = $VBox/LoadButton
@onready var delete_button: Button = $VBox/DeleteButton
@onready var back_button: Button = $VBox/BackButton

var _profiles: Array[String] = []


func _ready() -> void:
	_refresh_profiles()

	if create_button:
		create_button.pressed.connect(_on_create)
	if load_button:
		load_button.pressed.connect(_on_load)
	if delete_button:
		delete_button.pressed.connect(_on_delete)
	if back_button:
		back_button.pressed.connect(func(): SceneManager.go_to_title())
	if new_profile_input:
		new_profile_input.text_submitted.connect(func(_t): _on_create())


func _refresh_profiles() -> void:
	_profiles = SaveSystem.get_all_profiles()
	if profile_list:
		profile_list.clear()
		for p in _profiles:
			profile_list.add_item(p)


func _on_create() -> void:
	if not new_profile_input:
		return
	var name = new_profile_input.text.strip_edges()
	if name.is_empty():
		return
	if SaveSystem.profile_exists(name):
		return  # Profile already exists

	GameManager.new_profile(name)
	SceneManager.go_to_map()


func _on_load() -> void:
	if not profile_list:
		return
	var selected = profile_list.get_selected_items()
	if selected.is_empty():
		return

	var profile_name = _profiles[selected[0]]
	if GameManager.load_profile(profile_name):
		SceneManager.go_to_map()


func _on_delete() -> void:
	if not profile_list:
		return
	var selected = profile_list.get_selected_items()
	if selected.is_empty():
		return

	var profile_name = _profiles[selected[0]]
	SaveSystem.delete_save(profile_name)
	_refresh_profiles()
