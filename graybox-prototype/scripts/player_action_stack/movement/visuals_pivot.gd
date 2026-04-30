extends Node3D

@export var interpolation_speed: float = 20.0
@onready var _body: CharacterBody3D = $"../Body"
@onready var _broker: MovementBroker = $"../MovementBroker"

var _target_y_offset: float = 0.0

func _ready() -> void:
	set_as_top_level(true)
	set_process(false)
	set_physics_process(false)

## Explicit loop owner for visual interpolation (re-enabled by MovementBroker).
func _process(delta: float) -> void:
	if not is_instance_valid(_body): return
	
	if _broker:
		if _broker.get_current_mode() == LocomotionState.ID.SNEAK:
			_target_y_offset = -0.4
		else:
			_target_y_offset = 0.0
			
	global_position.x = _body.global_position.x
	global_position.z = _body.global_position.z
	global_position.y = lerpf(global_position.y, _body.global_position.y + _target_y_offset, interpolation_speed * delta)
	basis = basis.slerp(_body.basis, interpolation_speed * delta)
