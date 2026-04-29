class_name BodyReader
extends RefCounted

var _body: CharacterBody3D

func _init(body: CharacterBody3D) -> void:
	_body = body

func get_global_position() -> Vector3:
	return _body.global_position

func get_velocity() -> Vector3:
	return _body.velocity

func get_basis() -> Basis:
	return _body.basis

func is_on_floor() -> bool:
	return _body.is_on_floor()

func get_floor_normal() -> Vector3:
	return _body.get_floor_normal()
