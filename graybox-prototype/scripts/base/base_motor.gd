class_name BaseMotor
extends Node

@warning_ignore("unused_private_class_variable")
var _brain: Node ## Reference to PlayerBrain or similar context provider.

## Gathers transition proposals for this motor based on current state and intents.
func gather_proposals(_current_mode: int, _intents: Intents, _services: Array[BaseService], _stamina: StaminaComponent) -> Array[TransitionProposal]:
	return []

## Ticks the motor. It is only called if this motor is active.
func tick(_delta: float, _intents: Intents, _body: CharacterBody3D, _stamina: StaminaComponent, _services: Array[BaseService]) -> void:
	assert(false, "Not implemented: tick")

## Shared service locator — avoids duplicating this helper in every concrete motor.
## Returns the first element in services that matches service_type, or null.
func _get_service(services: Array[BaseService], service_type: Variant) -> BaseService:
	for s in services:
		if is_instance_of(s, service_type):
			return s
	return null
