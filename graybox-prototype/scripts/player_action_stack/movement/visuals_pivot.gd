extends Node3D

@export var interpolation_speed: float = 20.0
@onready var _body: CharacterBody3D = $"../Body"
var _target_y_offset: float = 0.0
var _state_reader: LocomotionStateReader

func _ready() -> void:
	set_as_top_level(true)
	set_physics_process(false)
	var broker = get_node_or_null("../MovementBroker")
	if broker and broker.has_method("get_state_reader"):
		_state_reader = broker.get_state_reader()

## Explicit loop owner for visual interpolation.
func _process(delta: float) -> void:
	if not is_instance_valid(_body): return
	
	if _state_reader:
		if _state_reader.get_current_mode() == LocomotionState.ID.SNEAK:
			_target_y_offset = -0.4
		else:
			_target_y_offset = 0.0
			
	global_position.x = _body.global_position.x
	global_position.z = _body.global_position.z
	global_position.y = lerpf(global_position.y, _body.global_position.y + _target_y_offset, interpolation_speed * delta)
	basis = basis.slerp(_body.basis, interpolation_speed * delta)
