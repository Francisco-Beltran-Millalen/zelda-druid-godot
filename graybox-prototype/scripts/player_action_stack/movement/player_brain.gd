extends Node

signal mouse_motion_received(relative: Vector2)

@onready var _camera_rig: Node3D = $"../../CameraRig"

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_motion_received.emit(event.relative)
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			get_tree().quit() # Allow easy quitting if they press ESC twice

func get_intents() -> Intents:
	var intents: Intents = Intents.new()
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	intents.raw_input = input_dir
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
	if Input.is_action_pressed("climb_debug"):
		intents.wants_climb = true
	if Input.is_action_pressed("mantle_debug"):
		intents.wants_mantle = true
	if Input.is_key_pressed(KEY_3):
		intents.wants_vault = true
	if Input.is_key_pressed(KEY_CTRL):
		intents.wants_sneak = true
	return intents
