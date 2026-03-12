extends Control
## Reference Library — In-game codex with unlockable math reference pages.

signal page_opened(page_id: String)
signal practice_requested(task_ids: Array)

@onready var page_list: ItemList = $HSplit/PageList
@onready var page_content: RichTextLabel = $HSplit/PageContent
@onready var search_bar: LineEdit = $SearchBar
@onready var practice_button: Button = $PracticeButton
@onready var back_button: Button = $BackButton

var _pages: Dictionary = {}  # page_id -> data
var _current_page_id: String = ""
var _filtered_ids: Array[String] = []


func _ready() -> void:
	_load_unlocked_pages()

	if search_bar:
		search_bar.text_changed.connect(_on_search)
	if page_list:
		page_list.item_selected.connect(_on_page_selected)
	if practice_button:
		practice_button.pressed.connect(_on_practice)
	if back_button:
		back_button.pressed.connect(func(): visible = false)


func _load_unlocked_pages() -> void:
	var all_pages = ContentLoader.get_all_reference_pages()
	_pages.clear()

	for page_id in all_pages.keys():
		if GameManager.has_reference_page(page_id):
			_pages[page_id] = all_pages[page_id]

	_refresh_list()


func _refresh_list(filter: String = "") -> void:
	if not page_list:
		return

	page_list.clear()
	_filtered_ids.clear()

	for page_id in _pages.keys():
		var page = _pages[page_id]
		var title = page.get("title", page_id)
		var topic = page.get("topic", "")

		# Filter by search text
		if not filter.is_empty():
			var search_text = (title + " " + topic).to_lower()
			if filter.to_lower() not in search_text:
				continue

		page_list.add_item(title)
		_filtered_ids.append(page_id)


func _on_search(text: String) -> void:
	_refresh_list(text)


func _on_page_selected(index: int) -> void:
	if index < 0 or index >= _filtered_ids.size():
		return

	_current_page_id = _filtered_ids[index]
	var page = _pages.get(_current_page_id, {})
	_display_page(page)
	page_opened.emit(_current_page_id)


func _display_page(page: Dictionary) -> void:
	if not page_content:
		return

	var text := ""
	text += "[font_size=22][b]%s[/b][/font_size]\n\n" % page.get("title", "")

	for section in page.get("sections", []):
		text += "[font_size=16][b]%s[/b][/font_size]\n" % section.get("heading", "")
		text += "%s\n\n" % section.get("content", "")

		# Examples
		for example in section.get("examples", []):
			text += "[color=#4488cc]Example:[/color] %s\n" % example.get("problem", "")
			var steps = example.get("steps", [])
			for step in steps:
				text += "  - %s\n" % step
			text += "[color=#44cc44]Answer:[/color] %s\n\n" % example.get("solution", "")

	# Common pitfalls
	var pitfalls = page.get("common_pitfalls", [])
	if not pitfalls.is_empty():
		text += "[font_size=16][b]Watch Out For[/b][/font_size]\n"
		for pitfall in pitfalls:
			text += "[color=#cc8844]Mistake:[/color] %s\n" % pitfall.get("mistake", "")
			text += "[color=#44cc44]Fix:[/color] %s\n\n" % pitfall.get("correction", "")

	page_content.text = text

	# Show practice button if tasks are linked
	if practice_button:
		practice_button.visible = not page.get("practice_task_ids", []).is_empty()


func _on_practice() -> void:
	var page = _pages.get(_current_page_id, {})
	var task_ids = page.get("practice_task_ids", [])
	if not task_ids.is_empty():
		practice_requested.emit(task_ids)


func open() -> void:
	_load_unlocked_pages()
	visible = true


func close() -> void:
	visible = false
