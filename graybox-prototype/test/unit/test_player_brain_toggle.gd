extends "res://addons/gut/test.gd"

var PlayerBrain = load("res://scripts/player_action_stack/movement/player_brain.gd")
var LocomotionState = load("res://scripts/player_action_stack/movement/locomotion_state.gd")

func test_climb_toggle():
	var brain = PlayerBrain.new()
	add_child_autofree(brain)
	
	# Initial state: toggle OFF
	var intents = brain.get_intents()
	assert_false(intents.wants_climb, "Initially wants_climb should be false")
	
	# Simulate '1' press (climb_debug action)
	var event = InputEventAction.new()
	event.action = "climb_debug"
	event.pressed = true
	brain._input(event)
	
	intents = brain.get_intents()
	assert_true(intents.wants_climb, "After press, wants_climb should be true (toggle ON)")
	
	# Simulate another '1' press
	brain._input(event)
	intents = brain.get_intents()
	assert_false(intents.wants_climb, "After second press, wants_climb should be false (toggle OFF)")

func test_climb_reset_on_wall_jump_away():
	var brain = PlayerBrain.new()
	add_child_autofree(brain)
	
	# Toggle ON
	var event = InputEventAction.new()
	event.action = "climb_debug"
	event.pressed = true
	brain._input(event)
	assert_true(brain.get_intents().wants_climb)
	
	# Simulate state change to WALL_JUMP while Neutral (Away)
	brain._on_locomotion_state_changed(LocomotionState.ID.CLIMB, LocomotionState.ID.WALL_JUMP)
	
	assert_false(brain.get_intents().wants_climb, "wants_climb should be reset to false on away wall jump")

func test_climb_stays_on_wall_jump_lateral():
	var brain = PlayerBrain.new()
	add_child_autofree(brain)
	
	# Toggle ON
	var event = InputEventAction.new()
	event.action = "climb_debug"
	event.pressed = true
	brain._input(event)
	
	# Simulate pressing LEFT (A)
	Input.action_press("move_left")
	assert_true(brain.get_intents().is_climbing_left)
	
	# Simulate state change to WALL_JUMP while holding LEFT
	brain._on_locomotion_state_changed(LocomotionState.ID.CLIMB, LocomotionState.ID.WALL_JUMP)
	
	assert_true(brain.get_intents().wants_climb, "wants_climb should stay true on lateral wall jump")
	
	Input.action_release("move_left")

func test_climb_reset_on_wall_jump_back():
	var brain = PlayerBrain.new()
	add_child_autofree(brain)
	
	# Toggle ON
	var event = InputEventAction.new()
	event.action = "climb_debug"
	event.pressed = true
	brain._input(event)
	
	# Simulate pressing BACK (S)
	Input.action_press("move_backward")
	assert_true(brain.get_intents().is_climbing_down)
	
	# Simulate state change to WALL_JUMP while holding BACK
	brain._on_locomotion_state_changed(LocomotionState.ID.CLIMB, LocomotionState.ID.WALL_JUMP)
	
	assert_false(brain.get_intents().wants_climb, "wants_climb should reset to false on backward wall jump")
	
	Input.action_release("move_backward")

func test_climb_reset_on_mantle():
	var brain = PlayerBrain.new()
	add_child_autofree(brain)
	
	# Toggle ON
	var event = InputEventAction.new()
	event.action = "climb_debug"
	event.pressed = true
	brain._input(event)
	
	# Simulate state change to MANTLE
	brain._on_locomotion_state_changed(LocomotionState.ID.CLIMB, LocomotionState.ID.MANTLE)
	
	assert_false(brain.get_intents().wants_climb, "wants_climb should be reset to false on mantle")

func test_climb_reset_on_edge_leap():
	var brain = PlayerBrain.new()
	add_child_autofree(brain)
	
	# Toggle ON
	var event = InputEventAction.new()
	event.action = "climb_debug"
	event.pressed = true
	brain._input(event)
	
	# Simulate state change to EDGE_LEAP
	brain._on_locomotion_state_changed(LocomotionState.ID.CLIMB, LocomotionState.ID.EDGE_LEAP)
	
	assert_false(brain.get_intents().wants_climb, "wants_climb should be reset to false on edge leap")
