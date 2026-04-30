extends Node

signal mouse_motion_received(relative: Vector2)

var _camera_rig: Node3D
var _broker: MovementBroker

var _climb_toggle: bool = false

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	_camera_rig = get_node_or_null("../../CameraRig")
	_broker = get_node_or_null("../MovementBroker")
	
	if _broker:
		_broker.state_changed.connect(_on_locomotion_state_changed)

func _on_locomotion_state_changed(_old_mode: int, new_mode: int) -> void:
	# Reset climb toggle if we mantle, do a regular floor jump, or perform an edge leap
	if new_mode == LocomotionState.ID.MANTLE \
	or new_mode == LocomotionState.ID.JUMP \
	or new_mode == LocomotionState.ID.EDGE_LEAP:
		_climb_toggle = false
	
	# Conditional reset for Wall Jump:
	# We want to stick to the wall (keep toggle) if we are jumping Up, Left, or Right.
	# We want to leave the wall (reset toggle) if we jump Away (Neutral or Back).
	elif new_mode == LocomotionState.ID.WALL_JUMP:
		var intents: Intents = get_intents()
		var is_jumping_to_stick: bool = intents.is_climbing_up or intents.is_climbing_left or intents.is_climbing_right
		if not is_jumping_to_stick:
			_climb_toggle = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_motion_received.emit(event.relative)
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			get_tree().quit() # Allow easy quitting if they press ESC twice
			
	if event.is_action_pressed("climb_debug"):
		_climb_toggle = !_climb_toggle

func get_intents() -> Intents:
	var intents: Intents = Intents.new()
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	intents.raw_input = input_dir
	intents.input_strength = input_dir.length()
	
	# Populate wish_dir (discrete semantic intent)
	var wd_x: int = 0
	if input_dir.x > 0.5: wd_x = 1
	elif input_dir.x < -0.5: wd_x = -1
	
	var wd_y: int = 0
	if input_dir.y < -0.5: wd_y = 1 # move_forward is negative Y in get_vector
	elif input_dir.y > 0.5: wd_y = -1
	
	intents.wish_dir = Vector2i(wd_x, wd_y)
	
	if _camera_rig and input_dir != Vector2.ZERO:
		var cam_basis: Basis = _camera_rig.global_transform.basis
		var forward: Vector3 = -cam_basis.z
		var right: Vector3 = cam_basis.x
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()
		
		# input_dir.y is negative when moving forward (since move_forward is the -Y axis of get_vector)
		var world_dir: Vector3 = (right * input_dir.x - forward * input_dir.y).normalized()
		intents.move_dir = Vector2(world_dir.x, world_dir.z)
	else:
		intents.move_dir = input_dir
		
	if Input.is_action_pressed("jump"):
		intents.wants_jump = true
		intents.wants_glide = true
	if Input.is_action_pressed("sprint") or Input.is_key_pressed(KEY_SHIFT):
		intents.wants_sprint = true
	
	# Use toggle for climbing
	intents.wants_climb = _climb_toggle
	
	if Input.is_action_pressed("mantle_debug"):
		intents.wants_mantle = true
	if Input.is_key_pressed(KEY_3):
		intents.wants_vault = true
	if Input.is_key_pressed(KEY_CTRL):
		intents.wants_sneak = true
	return intents
