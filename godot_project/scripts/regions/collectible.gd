class_name Collectible
extends Area2D
## A collectible item — golden seeds, runes, crystals, etc.

signal collected(collectible_id: String)

@export var collectible_id: String = ""
@export var is_collected: bool = false

var _base_position: Vector2


func _ready() -> void:
	add_to_group("collectible")
	collision_layer = 16  # Collectibles layer
	collision_mask = 2    # Player layer
	_base_position = position

	body_entered.connect(_on_body_entered)

	if is_collected:
		visible = false
		set_deferred("monitoring", false)
	else:
		_start_float_animation()


func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if not body.is_in_group("player"):
		return

	is_collected = true
	collected.emit(collectible_id)
	GameManager.add_collectible(GameManager.current_region, collectible_id)
	_play_collect_effect()


func _start_float_animation() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(self, "position:y", _base_position.y - 4.0, 1.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", _base_position.y, 1.0) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _play_collect_effect() -> void:
	# Scale up and fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	visible = false
	set_deferred("monitoring", false)
