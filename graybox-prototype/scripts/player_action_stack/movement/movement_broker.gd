class_name MovementBroker
extends Node

signal state_changed(old_mode: int, new_mode: int)

@export var motor_map: Dictionary[int, NodePath] = {}
@onready var _brain: Node = $"../PlayerBrain"
@onready var _body: CharacterBody3D = $"../Body"
@onready var _stamina: StaminaComponent = $"../StaminaComponent"
@onready var _ground_service: GroundService = $"../Services/GroundService"
@onready var _ledge_service: LedgeService = $"../Services/LedgeService"
@onready var _stairs_service: StairsService = $"../Services/StairsService"
@onready var _ladder_service: LadderService = $"../Services/LadderService"

var _motors: Dictionary = {}
var _services: Array[BaseService] = []
var _body_reader: BodyReader
var _loco_state: LocomotionState

## Public API for state access
func get_current_mode() -> int:
	assert(_loco_state != null, "LocomotionState not initialized")
	return _loco_state.get_active_mode() if _loco_state else LocomotionState.ID.FALL

var _current_mode: int:
	get:
		return get_current_mode()

func get_body_reader() -> BodyReader:
	return _body_reader

func _ready() -> void:
	_body_reader = BodyReader.new(_body)
	_loco_state = LocomotionState.new()
	add_child(_loco_state)
	
	## Forward LocomotionState.state_changed as MovementBroker.state_changed
	_loco_state.state_changed.connect(func(o: int, n: int) -> void: state_changed.emit(o, n))

	for state_id in motor_map.keys():
		var path: NodePath = motor_map[state_id]
		if has_node(path):
			_motors[state_id] = get_node(path)
	
	if _ground_service: _services.append(_ground_service)
	if _ledge_service: _services.append(_ledge_service)
	if _stairs_service: _services.append(_stairs_service)
	if _ladder_service: _services.append(_ladder_service)
	
	# Auto-populate if map is empty (fallback for graybox ease)
	if _motors.is_empty():
		for child in get_children():
			if child is BaseMotor:
				var state_id: int = _guess_state_id(child.name)
				_motors[state_id] = child
	
	for m in _motors.values():
		if m is BaseMotor:
			m._broker = self
			
	if has_node("../VisualsPivot"):
		get_node("../VisualsPivot").set_process(true)

func _guess_state_id(motor_name: String) -> int:
	match motor_name:
		"WalkMotor": return LocomotionState.ID.WALK
		"SprintMotor": return LocomotionState.ID.SPRINT
		"FallMotor": return LocomotionState.ID.FALL
		"JumpMotor": return LocomotionState.ID.JUMP
		"AutoVaultMotor": return LocomotionState.ID.AUTO_VAULT
		"ClimbMotor": return LocomotionState.ID.CLIMB
		"MantleMotor": return LocomotionState.ID.MANTLE
		"StairsMotor": return LocomotionState.ID.STAIRS
		"LadderMotor": return LocomotionState.ID.LADDER
		"GlideMotor": return LocomotionState.ID.GLIDE
		"SneakMotor": return LocomotionState.ID.SNEAK
		"WallJumpMotor": return LocomotionState.ID.WALL_JUMP
		"EdgeLeapMotor": return LocomotionState.ID.EDGE_LEAP
	return LocomotionState.ID.IDLE

func _physics_process(delta: float) -> void:
	var intents: Intents = _brain.get_intents() if _brain and _brain.has_method("get_intents") else Intents.new()

	for s in _services:
		if s.has_method("update_facts"):
			s.update_facts(_body_reader)

	var best_proposal: TransitionProposal = null

	for m in _motors.values():
		if not m is BaseMotor:
			continue
		var proposals: Array[TransitionProposal] = m.gather_proposals(_current_mode, intents, _services, _stamina)
		for p in proposals:
			if best_proposal == null:
				best_proposal = p
			elif p.category > best_proposal.category:
				best_proposal = p
			elif p.category == best_proposal.category and p.override_weight > best_proposal.override_weight:
				best_proposal = p
			
	var new_mode: int = LocomotionState.ID.FALL
	if best_proposal != null:
		new_mode = best_proposal.target_state
		
	if new_mode != _current_mode:
		var old_mode: int = _current_mode
		_loco_state.set_state(new_mode)  ## SSoT write
		if _motors.has(old_mode) and _motors[old_mode].has_method("on_deactivate"):
			_motors[old_mode].on_deactivate(_body)
		if _motors.has(new_mode) and _motors[new_mode].has_method("on_activate"):
			_motors[new_mode].on_activate(_body)
		
	if _motors.has(_current_mode):
		var active_motor = _motors[_current_mode]
		if active_motor is BaseMotor:
			active_motor.tick(delta, intents, _body, _stamina, _services)

	if OS.is_debug_build() and has_node("/root/DebugOverlay"):
		var m_name: String = LocomotionState.ID.keys()[_current_mode]
		var spd: float = Vector2(_body.velocity.x, _body.velocity.z).length()
		var stamina_cur: float = _stamina.get_current() if _stamina else 0.0
		var stamina_max: float = _stamina.get_max() if _stamina else 100.0
		var stamina_pct: int = roundi(stamina_cur / stamina_max * 100.0)
		
		# Collect active intents for debugging
		var active_intents: Array[String] = []
		if intents.wants_jump: active_intents.append("Jump")
		if intents.wants_sprint: active_intents.append("Sprint")
		if intents.wants_sneak: active_intents.append("Sneak")
		if intents.wants_climb: active_intents.append("Climb")
		if intents.wants_mantle: active_intents.append("Mantle")
		if intents.wants_vault: active_intents.append("Vault")
		if intents.wants_glide: active_intents.append("Glide")
		
		var intents_str: String = " ".join(active_intents.map(func(s): return "[" + s + "]"))
		
		# Semantic direction debug
		var dir_str: String = ""
		if intents.is_moving_forward: dir_str += "F"
		if intents.is_moving_back: dir_str += "B"
		if intents.is_moving_left: dir_str += "L"
		if intents.is_moving_right: dir_str += "R"
		if dir_str == "": dir_str = "-"
		
		get_node("/root/DebugOverlay").push(1, {
			"state": m_name, 
			"speed": snappedf(spd, 0.1), 
			"vel_y": snappedf(_body.velocity.y, 0.1), 
			"stamina": "%d%%" % stamina_pct,
			"wish": dir_str,
			"str": "%.2f" % intents.input_strength,
			"intents": intents_str if intents_str != "" else "None"
		})
