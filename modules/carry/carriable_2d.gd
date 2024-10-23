@tool
extends Area2D
class_name Carriable2D

@export
var entity: Entity2D = null

var _carrier: Carrier2D = null

func get_carrier() -> Carrier2D:
	return _carrier

func has_carrier() -> bool:
	return is_instance_valid(_carrier)
