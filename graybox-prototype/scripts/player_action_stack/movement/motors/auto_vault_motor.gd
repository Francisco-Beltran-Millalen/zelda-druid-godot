class_name AutoVaultMotor
extends BaseMotor

const AUTO_VAULT_WEIGHT: int = 20

@export var vault_clearance: float = 0.25
@export var vault_min_rise: float = 0.3

var _rising: bool = false
var _impulse_applied: bool = false
var _just_activated: bool = false

func gather_proposals(current_mode: int, intents: Intents, services: Array[BaseService], _stamina: StaminaComponent) -> Array[TransitionProposal]:
	if _rising or (current_mode == LocomotionState.ID.AUTO_VAULT and _just_activated):
		return [TransitionProposal.new(LocomotionState.ID.AUTO_VAULT, TransitionProposal.Priority.FORCED, AUTO_VAULT_WEIGHT)]
	
	var ground: GroundService = _get_service(services, GroundService) as GroundService
	var ledge: LedgeService = _get_service(services, LedgeService) as LedgeService
	
	if ground != null and ground.is_on_floor() and ledge != null and intents.wants_vault:
		var facts: LedgeFacts = ledge.get_ledge_facts(_brain.get_body_reader())
		if facts.is_occupied and facts.landing_height != -INF and facts.landing_height <= facts.detection_range:
			return [TransitionProposal.new(LocomotionState.ID.AUTO_VAULT, TransitionProposal.Priority.PLAYER_REQUESTED, AUTO_VAULT_WEIGHT)]
	
	return []

func on_activate(_body: CharacterBody3D) -> void:
	_rising = true
	_just_activated = true
	_impulse_applied = false

func on_deactivate(_body: CharacterBody3D) -> void:
	_rising = false
	_impulse_applied = false

func tick(delta: float, _intents: Intents, body: CharacterBody3D, _stamina: StaminaComponent, services: Array[BaseService]) -> void:
	_just_activated = false
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

	if not _impulse_applied:
		var ledge: LedgeService = _get_service(services, LedgeService) as LedgeService
		var rise_needed: float = vault_min_rise
		if ledge != null:
			var facts: LedgeFacts = ledge.get_ledge_facts(_brain.get_body_reader())
			if facts.is_occupied:
				# Target landing height relative to feet + buffer
				var to_landing: float = facts.landing_height + 0.4 
				rise_needed = maxf(to_landing, vault_min_rise)
		
		# Strength multiplier: 1.2x ensures we clear the height even with physics friction
		body.velocity.y = sqrt(2.0 * gravity * rise_needed) * 1.2
		
		# Inject forward momentum so the vault feels "strong"
		var facing: Vector3 = -body.global_transform.basis.z
		facing.y = 0
		if facing.length_squared() > 0.001:
			facing = facing.normalized()
			var current_h_vel: Vector3 = Vector3(body.velocity.x, 0, body.velocity.z)
			var min_vault_speed: float = 5.0
			if current_h_vel.length() < min_vault_speed:
				body.velocity.x = facing.x * min_vault_speed
				body.velocity.z = facing.z * min_vault_speed
		
		_impulse_applied = true
		return

	# Maintain trajectory
	body.velocity.y -= gravity * delta

	if body.velocity.y <= 0.0 or body.is_on_floor():
		_rising = false
