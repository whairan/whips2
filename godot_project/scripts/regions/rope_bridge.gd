class_name RopeBridge
extends InteractableBase
## A rope bridge that can be broken, building, or intact.

enum BridgeState { BROKEN, BUILDING, INTACT }

@export var bridge_state: BridgeState = BridgeState.BROKEN

@onready var collision_body: StaticBody2D = $BridgeBody if has_node("BridgeBody") else null
@onready var broken_sprite: Sprite2D = $BrokenSprite if has_node("BrokenSprite") else null
@onready var intact_sprite: Sprite2D = $IntactSprite if has_node("IntactSprite") else null


func _ready() -> void:
	super._ready()
	_update_state_visuals()


func _on_interact(_player: Node2D) -> void:
	match bridge_state:
		BridgeState.BROKEN:
			prompt_text = "The bridge is broken..."
		BridgeState.INTACT:
			prompt_text = "A sturdy vine bridge"


func rebuild() -> void:
	bridge_state = BridgeState.BUILDING
	_update_state_visuals()
	# Animate the building process
	var tween = create_tween()
	if intact_sprite:
		intact_sprite.visible = true
		intact_sprite.modulate.a = 0.0
		tween.tween_property(intact_sprite, "modulate:a", 1.0, 2.0)
	await tween.finished
	bridge_state = BridgeState.INTACT
	_update_state_visuals()
	state_changed.emit("intact")


func _update_state_visuals() -> void:
	match bridge_state:
		BridgeState.BROKEN:
			if broken_sprite: broken_sprite.visible = true
			if intact_sprite: intact_sprite.visible = false
			if collision_body: collision_body.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
			prompt_text = "[E] Examine broken bridge"
		BridgeState.BUILDING:
			prompt_text = "Building..."
		BridgeState.INTACT:
			if broken_sprite: broken_sprite.visible = false
			if intact_sprite: intact_sprite.visible = true
			if collision_body: collision_body.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT)
			prompt_text = "A sturdy vine bridge"
			is_active = false  # No longer interactive once built
