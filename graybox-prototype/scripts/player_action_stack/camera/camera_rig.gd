extends Node3D

@export var landing_dip_intensity: float = 0.5
@export var landing_dip_recovery_speed: float = 8.0
@export var mouse_sensitivity: float = 0.003

var _current_dip: float = 0.0
var _yaw: float = 0.0
var _pitch: float = 0.0

@onready var _body: CharacterBody3D = $"../EntityController/Body"
@onready var _lens: SpringArm3D = $Lens

func _ready() -> void:
	# Registered visual-update loop owner — _process intentionally always-on (smooth camera interpolation).
	set_as_top_level(true)
	var broker = get_node_or_null("../EntityController/MovementBroker")
	if broker and broker.has_method("get_state_reader"):
		var state_reader = broker.get_state_reader()
		if state_reader:
			state_reader.state_changed.connect(_on_locomotion_state_changed)
	
	if has_node("../EntityController/PlayerBrain"):
		get_node("../EntityController/PlayerBrain").mouse_motion_received.connect(_on_mouse_motion)
	
	if _lens:
		_lens.spring_length = 4.0
		_lens.position = Vector3(0, 1.5, 0)

func _on_mouse_motion(relative: Vector2) -> void:
	_yaw -= relative.x * mouse_sensitivity
	_pitch -= relative.y * mouse_sensitivity
	_pitch = clampf(_pitch, -1.2, 1.2)

func _process(delta: float) -> void:
	if not is_instance_valid(_body): return
	
	global_position.x = _body.global_position.x
	global_position.z = _body.global_position.z
	
	_current_dip = lerpf(_current_dip, 0.0, landing_dip_recovery_speed * delta)
	
	# Smooth Y to handle stairs, and apply dip
	var target_y: float = _body.global_position.y - _current_dip
	global_position.y = lerpf(global_position.y, target_y, 15.0 * delta)
	
	rotation.y = _yaw
	if _lens:
		_lens.rotation.x = _pitch

func _on_locomotion_state_changed(old_mode: int, new_mode: int) -> void:
	# Fall is state 3, Walk is 1, Sprint is 2
	if old_mode == 3 and (new_mode == 1 or new_mode == 2):
		_current_dip += landing_dip_intensity
