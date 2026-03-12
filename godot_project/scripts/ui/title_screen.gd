extends Control
## Title screen — game entry point.

@onready var title_label: Label = $VBox/TitleLabel
@onready var play_button: Button = $VBox/PlayButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var quit_button: Button = $VBox/QuitButton


func _ready() -> void:
	if play_button:
		play_button.pressed.connect(_on_play)
		play_button.grab_focus()
	if settings_button:
		settings_button.pressed.connect(func(): SceneManager.go_to_settings())
	if quit_button:
		quit_button.pressed.connect(func(): get_tree().quit())


func _on_play() -> void:
	SceneManager.go_to_profile_select()
