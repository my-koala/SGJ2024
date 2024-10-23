@tool
extends Entity2D
class_name Collectable2D

@export
var immune_time: float = 1.0
var _immune_time: float = 0.0

func is_immune() -> bool:
	return _immune_time < immune_time

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	pass
	if _immune_time > immune_time:
		return
	_immune_time += delta
	
	super(delta)
