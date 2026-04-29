class_name Intents
extends RefCounted

var move_dir: Vector2 = Vector2.ZERO
var raw_input: Vector2 = Vector2.ZERO
var wants_jump: bool = false
var wants_sprint: bool = false
var wants_sneak: bool = false
var wants_climb: bool = false
var wants_mantle: bool = false
var wants_vault: bool = false
var wants_glide: bool = false

func reset() -> void:
	move_dir = Vector2.ZERO
	raw_input = Vector2.ZERO
	wants_jump = false
	wants_sprint = false
	wants_sneak = false
	wants_climb = false
	wants_mantle = false
	wants_vault = false
	wants_glide = false
