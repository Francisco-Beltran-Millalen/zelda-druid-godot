extends Node

var panel_visible: bool = true
var _contexts: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		panel_visible = !panel_visible
		_update_visibility()

func register_context(context: BaseDebugContext) -> void:
	if context.panel_key >= 0:
		_contexts[context.panel_key] = context

func push(context_key: int, data: Dictionary) -> void:
	if not OS.is_debug_build() or not panel_visible:
		return
	if _contexts.has(context_key):
		_contexts[context_key].push_data(data)

func _update_visibility() -> void:
	# Normally we would show/hide a UI panel here
	pass
