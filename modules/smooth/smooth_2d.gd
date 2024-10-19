# code by my-koala ͼ•ᴥ•ͽ #
@tool
extends Node2D
class_name Smooth2D

# Simple physics interpolation solution.
# A problem with the engine's solution is that Y-Sort is not updated during interpolation.

@export
var enabled: bool = true

var _transform_curr: Transform2D = Transform2D()
var _transform_prev: Transform2D = Transform2D()

func _init() -> void:
	if Engine.is_editor_hint():
		return
	
	set_physics_process(true)
	set_process(true)

func _notification(what: int) -> void:
	if Engine.is_editor_hint():
		return
	
	match what:
		NOTIFICATION_PHYSICS_PROCESS:
			_refresh_transform.call_deferred()
		NOTIFICATION_PROCESS:
			_apply_transform.call_deferred()
		NOTIFICATION_RESET_PHYSICS_INTERPOLATION:
			_refresh_transform()
			_transform_prev = _transform_curr
			_apply_transform()

func _refresh_transform() -> void:
	_transform_prev = _transform_curr
	
	if !enabled:
		return
	
	var parent: Node2D = get_parent() as Node2D
	if !is_instance_valid(parent):
		return
	
	_transform_curr = parent.global_transform

func _apply_transform() -> void:
	if !enabled:
		return
	
	var weight: float = Engine.get_physics_interpolation_fraction()
	global_transform = _transform_prev.interpolate_with(_transform_curr, weight)
