class_name SwitchTotem
extends InteractableBase
## A totem switch that toggles state and activates a linked object.

signal toggled(activated: bool)

@export var triggers_target: NodePath
@export var activated: bool = false


func _ready() -> void:
	super._ready()
	prompt_text = "[E] Activate Totem"
	_update_visual()


func _on_interact(_player: Node2D) -> void:
	activated = not activated
	_update_visual()
	toggled.emit(activated)

	# Activate linked target
	if not triggers_target.is_empty():
		var target = get_node_or_null(triggers_target)
		if target:
			if activated and target.has_method("activate"):
				target.activate()
			elif not activated and target.has_method("deactivate"):
				target.deactivate()

	state_changed.emit("activated" if activated else "deactivated")


func _update_visual() -> void:
	if activated:
		modulate = Color(1.0, 1.0, 0.7)  # Slight glow
		prompt_text = "[E] Deactivate Totem"
	else:
		modulate = Color(1.0, 1.0, 1.0)
		prompt_text = "[E] Activate Totem"
