class_name ClimbableSurface
extends Area2D
## Defines a climbable region — tree trunk, vine, ladder, wall.
## Player enters "climb" state when overlapping and pressing up/down.

@export var surface_type: String = "tree"  # tree, vine, ladder, wall


func _ready() -> void:
	add_to_group("climbable")
	collision_layer = 8   # Climbables layer
	collision_mask = 2    # Player layer
	# Visual highlight is handled by shader/modulate when player is near
