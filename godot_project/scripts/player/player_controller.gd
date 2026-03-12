extends CharacterBody2D
## Player controller — movement, climbing, interaction.
## Uses a state machine for clean transitions between movement modes.

signal interacted_with(interactable: Node2D)
signal entered_climb(surface: Node2D)
signal exited_climb

enum State { IDLE, WALK, JUMP, FALL, CLIMB, SWING, INTERACT }

@export var walk_speed: float = 120.0
@export var climb_speed: float = 80.0
@export var jump_velocity: float = -250.0
@export var gravity: float = 600.0
@export var interact_radius: float = 40.0

var current_state: State = State.IDLE
var facing_direction: int = 1  # 1 = right, -1 = left
var nearby_interactable: Node2D = null
var current_climb_surface: Node2D = null
var _idle_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_area: Area2D = $InteractArea
@onready var interact_prompt: Label = $InteractPrompt


func _ready() -> void:
	interact_prompt.visible = false
	interact_area.body_entered.connect(_on_interact_area_body_entered)
	interact_area.body_exited.connect(_on_interact_area_body_exited)
	interact_area.area_entered.connect(_on_interact_area_area_entered)
	interact_area.area_exited.connect(_on_interact_area_area_exited)


func _physics_process(delta: float) -> void:
	# Don't process movement during puzzles or whiteboard
	if GameManager.puzzle_active or GameManager.whiteboard_open:
		return

	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.WALK:
			_process_walk(delta)
		State.JUMP:
			_process_airborne(delta)
		State.FALL:
			_process_airborne(delta)
		State.CLIMB:
			_process_climb(delta)
		State.INTERACT:
			pass  # Handled by interaction system

	move_and_slide()
	_update_animation()


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.puzzle_active or GameManager.whiteboard_open:
		return

	if event.is_action_pressed("interact") and nearby_interactable:
		_do_interact()
	elif event.is_action_pressed("jump") and current_state != State.CLIMB:
		if is_on_floor():
			velocity.y = jump_velocity
			_change_state(State.JUMP)


# --- State processors ---

func _process_idle(delta: float) -> void:
	_idle_timer += delta
	_apply_gravity(delta)

	var input_dir = _get_input_direction()
	if input_dir.x != 0:
		_change_state(State.WALK)
		_idle_timer = 0.0
	elif not is_on_floor():
		_change_state(State.FALL)
		_idle_timer = 0.0

	# Check for climb input
	if input_dir.y != 0 and _can_climb():
		_start_climb()


func _process_walk(delta: float) -> void:
	_apply_gravity(delta)
	_idle_timer = 0.0

	var input_dir = _get_input_direction()
	velocity.x = input_dir.x * walk_speed

	if input_dir.x != 0:
		facing_direction = sign(input_dir.x) as int
	elif is_on_floor():
		velocity.x = 0
		_change_state(State.IDLE)

	if not is_on_floor():
		_change_state(State.FALL)

	# Check for climb input
	if input_dir.y != 0 and _can_climb():
		_start_climb()


func _process_airborne(delta: float) -> void:
	_apply_gravity(delta)

	var input_dir = _get_input_direction()
	velocity.x = input_dir.x * walk_speed

	if input_dir.x != 0:
		facing_direction = sign(input_dir.x) as int

	if is_on_floor():
		if input_dir.x != 0:
			_change_state(State.WALK)
		else:
			velocity.x = 0
			_change_state(State.IDLE)

	# Can grab climbable while airborne
	if input_dir.y < 0 and _can_climb():
		_start_climb()


func _process_climb(_delta: float) -> void:
	var input_dir = _get_input_direction()
	velocity.x = input_dir.x * climb_speed * 0.5
	velocity.y = input_dir.y * climb_speed

	if input_dir.x != 0:
		facing_direction = sign(input_dir.x) as int

	# Exit climb
	if not _can_climb():
		_end_climb()
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity * 0.8
		_end_climb()
		_change_state(State.JUMP)


# --- Helpers ---

func _get_input_direction() -> Vector2:
	return Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, 500.0)  # Terminal velocity


func _can_climb() -> bool:
	# Check if overlapping a climbable surface
	for area in interact_area.get_overlapping_areas():
		if area.is_in_group("climbable"):
			current_climb_surface = area
			return true
	return false


func _start_climb() -> void:
	velocity.y = 0
	_change_state(State.CLIMB)
	entered_climb.emit(current_climb_surface)


func _end_climb() -> void:
	current_climb_surface = null
	_change_state(State.FALL)
	exited_climb.emit()


func _do_interact() -> void:
	if nearby_interactable and nearby_interactable.has_method("interact"):
		_change_state(State.INTERACT)
		nearby_interactable.interact(self)
		interacted_with.emit(nearby_interactable)
		# Return to idle after short delay
		await get_tree().create_timer(0.3).timeout
		if current_state == State.INTERACT:
			_change_state(State.IDLE)


func _change_state(new_state: State) -> void:
	current_state = new_state


func _update_animation() -> void:
	if not sprite:
		return

	sprite.flip_h = facing_direction < 0

	match current_state:
		State.IDLE:
			if _idle_timer > 5.0:
				sprite.play("idle_special")
			else:
				sprite.play("idle")
		State.WALK:
			sprite.play("walk")
		State.JUMP:
			sprite.play("jump")
		State.FALL:
			sprite.play("fall")
		State.CLIMB:
			var input = _get_input_direction()
			if input.length() > 0:
				sprite.play("climb")
			else:
				sprite.play("climb_idle")
		State.INTERACT:
			sprite.play("interact")


# --- Interaction detection ---

func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("interactable"):
		_set_nearby_interactable(body)


func _on_interact_area_body_exited(body: Node2D) -> void:
	if body == nearby_interactable:
		_clear_nearby_interactable()


func _on_interact_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactable"):
		_set_nearby_interactable(area)


func _on_interact_area_area_exited(area: Area2D) -> void:
	if area == nearby_interactable:
		_clear_nearby_interactable()


func _set_nearby_interactable(node: Node2D) -> void:
	nearby_interactable = node
	interact_prompt.visible = true
	if node.has_method("get_prompt_text"):
		interact_prompt.text = node.get_prompt_text()
	else:
		interact_prompt.text = "[E] Interact"
	# Proximity animation
	if node.has_method("on_player_nearby"):
		node.on_player_nearby()


func _clear_nearby_interactable() -> void:
	if nearby_interactable and nearby_interactable.has_method("on_player_left"):
		nearby_interactable.on_player_left()
	nearby_interactable = null
	interact_prompt.visible = false
