class_name FruitTree
extends InteractableBase
## A tree bearing countable fruit. Interaction triggers a counting/math task.

signal harvest_requested(fruit_type: String, count: int)

@export var fruit_type: String = "mango"
@export var fruit_count: int = 5
@export var harvested: bool = false

@onready var fruit_sprites: Node2D = $FruitSprites if has_node("FruitSprites") else null
@onready var tree_sprite: Sprite2D = $TreeSprite if has_node("TreeSprite") else null


func _ready() -> void:
	super._ready()
	prompt_text = "[E] Count %s" % fruit_type.capitalize()
	_update_fruit_display()


func _on_interact(_player: Node2D) -> void:
	if harvested:
		prompt_text = "Already harvested"
		return
	harvest_requested.emit(fruit_type, fruit_count)


func harvest() -> void:
	harvested = true
	prompt_text = "Harvested!"
	_animate_harvest()
	state_changed.emit("harvested")


func _update_fruit_display() -> void:
	if not fruit_sprites:
		return
	# Show/hide fruit child sprites based on count
	var i := 0
	for child in fruit_sprites.get_children():
		child.visible = i < fruit_count and not harvested
		i += 1


func _animate_harvest() -> void:
	if fruit_sprites:
		var tween = create_tween()
		tween.tween_property(fruit_sprites, "modulate:a", 0.0, 0.5)
		await tween.finished
		_update_fruit_display()
