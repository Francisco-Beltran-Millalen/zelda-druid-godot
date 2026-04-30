class_name LedgeService
extends BaseService

const MIN_DIRECTION_LENGTH_SQUARED: float = 0.001

@export var vault_detection_range: float = 1.4
@export var vault_body_half_height: float = 1.0
@export var vault_surface_clearance: float = 0.08
@export var vault_landing_probe_distance: float = 1.6
@export var vault_landing_probe_height: float = 2.0
@export var mantle_max_height: float = 2.5
@export var lateral_cast_reach: float = 1.5
@export var mantle_body_half_height: float = 1.0
@export var mantle_body_radius: float = 0.5
@export var mantle_forward_radius_multiplier: float = 2.0
@export var mantle_surface_clearance: float = 0.08
@export var mantle_edge_body_offset: float = 0.33
@export var mantle_edge_tolerance: float = 0.05
@export var climb_wall_angle_max_deg: float = 30.0   ## Max angle between facing and wall normal to allow climbing
@export var continue_climb_angle_max_deg: float = 45.0  ## Max angle to keep climbing (sticky after waist-cast angle increases at apex)

var _can_climb: bool = false
var _climb_normal: Vector3 = Vector3.ZERO
var _has_wall_left: bool = false
var _has_wall_right: bool = false
var _vault_landing_body_y: float = -INF
var _mantle_ledge_point: Vector3 = Vector3.ZERO
var _mantle_target_position: Vector3 = Vector3.ZERO
var _is_at_ledge_edge: bool = false

var _waist_cast: ShapeCast3D
var _head_cast: ShapeCast3D
var _down_cast: ShapeCast3D
var _vault_landing_cast: ShapeCast3D
var _left_cast: ShapeCast3D
var _right_cast: ShapeCast3D

func _ready() -> void:
	set_process(false)
	set_physics_process(false)
	
	_waist_cast = _create_forward_cast(0.5)
	_head_cast = _create_forward_cast(1.5)
	_down_cast = ShapeCast3D.new()
	
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.1
	_down_cast.shape = sphere
	_down_cast.target_position = Vector3(0, -mantle_max_height, 0)
	_down_cast.position = Vector3(0, mantle_max_height + 0.1, -1.0)
	_down_cast.collision_mask = 1
	add_child(_down_cast)

	_vault_landing_cast = ShapeCast3D.new()
	var vault_landing_sphere: SphereShape3D = SphereShape3D.new()
	vault_landing_sphere.radius = 0.1
	_vault_landing_cast.shape = vault_landing_sphere
	_vault_landing_cast.target_position = Vector3(0, -vault_landing_probe_height, 0)
	_vault_landing_cast.collision_mask = 1
	add_child(_vault_landing_cast)

	_left_cast  = _create_forward_cast(0.5)
	_right_cast = _create_forward_cast(0.5)

func _create_forward_cast(y_pos: float) -> ShapeCast3D:
	var cast: ShapeCast3D = ShapeCast3D.new()
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = 0.1
	cast.shape = sphere
	cast.target_position = Vector3(0, 0, -1.0)
	cast.position = Vector3(0, y_pos, 0)
	cast.collision_mask = 1
	add_child(cast)
	return cast

func update_facts(body_reader: BodyReader) -> void:
	_can_climb = false
	_climb_normal = Vector3.ZERO
	_vault_landing_body_y = -INF
	_mantle_ledge_point = Vector3.ZERO
	_mantle_target_position = Vector3.ZERO
	_is_at_ledge_edge = false

	var pos: Vector3 = body_reader.get_global_position()
	var facing: Vector3 = -body_reader.get_basis().z
	facing.y = 0.0
	if facing.length_squared() > MIN_DIRECTION_LENGTH_SQUARED:
		facing = facing.normalized()
	else:
		facing = Vector3.FORWARD

	_waist_cast.global_position = pos + Vector3(0, -0.2, 0)
	_head_cast.global_position = pos + Vector3(0, 0.6, 0)
	_waist_cast.target_position = facing
	_head_cast.target_position = facing
	_down_cast.global_position = pos + facing * 1.0 + Vector3.UP * mantle_max_height
	_vault_landing_cast.global_position = pos + facing * vault_landing_probe_distance + Vector3.UP * vault_landing_probe_height
	
	_waist_cast.force_shapecast_update()
	_head_cast.force_shapecast_update()
	_down_cast.force_shapecast_update()
	_vault_landing_cast.force_shapecast_update()
	
	var waist_hit: bool = _waist_cast.is_colliding()
	var head_hit: bool = _head_cast.is_colliding()
	var mantle_lip_in_range: bool = false
	var feet_y: float = pos.y - vault_body_half_height
	
	if waist_hit and not head_hit:
		_update_vault_landing_body_y(feet_y)
	
	if _down_cast.is_colliding():
		var down_point: Vector3 = _down_cast.get_collision_point(0)
		var mantle_rel_y: float = down_point.y - feet_y
		if mantle_rel_y > 0 and mantle_rel_y <= mantle_max_height:
			mantle_lip_in_range = true
			_mantle_ledge_point = down_point
			_is_at_ledge_edge = _is_at_mantle_edge(pos, down_point)
	
	if waist_hit:
		var normal: Vector3 = _waist_cast.get_collision_normal(0)
		var angle_to_wall: float = rad_to_deg(facing.angle_to(-normal))
		if angle_to_wall <= climb_wall_angle_max_deg:
			_climb_normal = normal
			if head_hit or mantle_lip_in_range:
				_can_climb = true

	if mantle_lip_in_range:
		_update_mantle_target(facing, pos)

	if _climb_normal != Vector3.ZERO:
		var right_dir: Vector3 = Vector3.UP.cross(_climb_normal).normalized()
		_left_cast.global_position  = pos + (-right_dir * 0.45)
		_right_cast.global_position = pos + (right_dir  * 0.45)
		_left_cast.target_position  = -_climb_normal * lateral_cast_reach
		_right_cast.target_position = -_climb_normal * lateral_cast_reach
		_left_cast.force_shapecast_update()
		_right_cast.force_shapecast_update()
		_has_wall_left  = _left_cast.is_colliding()
		_has_wall_right = _right_cast.is_colliding()
	else:
		_has_wall_left  = false
		_has_wall_right = false
		_left_cast.global_position  = pos
		_right_cast.global_position = pos
		_left_cast.target_position  = facing
		_right_cast.target_position = facing
		_left_cast.force_shapecast_update()
		_right_cast.force_shapecast_update()

## Exposes all ledge-related facts in a single data carrier.
func get_ledge_facts(body_reader: BodyReader) -> LedgeFacts:
	var facts: LedgeFacts = LedgeFacts.new()
	var pos: Vector3 = body_reader.get_global_position()
	var feet_y: float = pos.y - vault_body_half_height
	
	if _down_cast.is_colliding():
		var mantle_rel_y: float = _down_cast.get_collision_point(0).y - feet_y
		if mantle_rel_y > 0.01: # More permissive threshold for curved surfaces
			facts.lip_height = mantle_rel_y
	
	if _vault_landing_cast.is_colliding():
		facts.landing_height = _vault_landing_cast.get_collision_point(0).y - feet_y
		facts.is_occupied = true
	
	facts.is_at_mantle_edge = _is_at_ledge_edge
	facts.detection_range = vault_detection_range
	facts.wall_normal = _climb_normal
	facts.has_wall_left = _has_wall_left
	facts.has_wall_right = _has_wall_right
	facts.target_position = _mantle_target_position
	facts.ledge_point = _mantle_ledge_point
	
	return facts

func get_wall_point() -> Vector3:
	if _waist_cast.is_colliding():
		return _waist_cast.get_collision_point(0)
	return Vector3.ZERO

func can_climb() -> bool:
	return _can_climb

func get_climb_normal() -> Vector3:
	return _climb_normal

func has_wall_left() -> bool:
	return _has_wall_left

func has_wall_right() -> bool:
	return _has_wall_right

func can_continue_climbing() -> bool:
	if not _waist_cast.is_colliding():
		return false
	var normal: Vector3 = _waist_cast.get_collision_normal(0)
	var facing: Vector3 = _waist_cast.target_position.normalized()
	var angle: float = rad_to_deg(facing.angle_to(-normal))
	return angle <= continue_climb_angle_max_deg

func _is_at_mantle_edge(body_position: Vector3, ledge_point: Vector3) -> bool:
	var edge_body_y: float = ledge_point.y - mantle_edge_body_offset
	return body_position.y >= edge_body_y - mantle_edge_tolerance

func _update_vault_landing_body_y(feet_y: float) -> void:
	if not _vault_landing_cast.is_colliding():
		return
	var landing_point: Vector3 = _vault_landing_cast.get_collision_point(0)
	var landing_rel_y: float = landing_point.y - feet_y
	if landing_rel_y > vault_surface_clearance and landing_rel_y <= vault_detection_range + vault_surface_clearance:
		_vault_landing_body_y = landing_point.y + vault_body_half_height + vault_surface_clearance

func _update_mantle_target(fallback_forward: Vector3, body_position: Vector3) -> void:
	var mantle_forward: Vector3 = fallback_forward
	if _climb_normal != Vector3.ZERO:
		mantle_forward = -_climb_normal
		mantle_forward.y = 0.0
		if mantle_forward.length_squared() <= MIN_DIRECTION_LENGTH_SQUARED:
			mantle_forward = fallback_forward
	if mantle_forward.length_squared() > MIN_DIRECTION_LENGTH_SQUARED:
		mantle_forward = mantle_forward.normalized()
	else:
		mantle_forward = Vector3.FORWARD

	var mantle_forward_distance: float = mantle_body_radius * mantle_forward_radius_multiplier
	_mantle_target_position = body_position + mantle_forward * mantle_forward_distance
	_mantle_target_position.y = _mantle_ledge_point.y + mantle_body_half_height + mantle_surface_clearance
