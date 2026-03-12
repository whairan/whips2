class_name InteractableBase
extends Area2D
## Base class for all interactive jungle objects.

signal interacted(player: Node2D)
signal state_changed(new_state: String)

@export var prompt_text: String = "[E] Interact"
@export var is_active: bool = true
@export var region_state_key: String = ""

var _player_nearby: bool = false
var _base_position: Vector2
var _bounce_tween: Tween


func _ready() -> void:
	add_to_group("interactable")
	_base_position = position
	collision_layer = 4  # Interactables layer
	collision_mask = 2   # Player layer


func interact(player: Node2D) -> void:
	if not is_active:
		return
	interacted.emit(player)
	_on_interact(player)


## Override in subclasses for specific behavior.
func _on_interact(_player: Node2D) -> void:
	pass


func get_prompt_text() -> String:
	return prompt_text if is_active else ""


func activate() -> void:
	is_active = true
	visible = true
	state_changed.emit("active")


func deactivate() -> void:
	is_active = false
	state_changed.emit("inactive")


func on_player_nearby() -> void:
	_player_nearby = true
	if is_active:
		_start_proximity_bounce()


func on_player_left() -> void:
	_player_nearby = false
	_stop_proximity_bounce()


func _start_proximity_bounce() -> void:
	if _bounce_tween and _bounce_tween.is_valid():
		return
	_bounce_tween = create_tween().set_loops()
	_bounce_tween.tween_property(self, "position:y", _base_position.y - 3.0, 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_bounce_tween.tween_property(self, "position:y", _base_position.y, 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _stop_proximity_bounce() -> void:
	if _bounce_tween and _bounce_tween.is_valid():
		_bounce_tween.kill()
	position = _base_position


func set_state(state_name: String) -> void:
	state_changed.emit(state_name)
