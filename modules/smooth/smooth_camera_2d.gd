# code by my-koala ͼ•ᴥ•ͽ #
@tool
extends Camera2D
class_name SmoothCamera2D

# Simple physics interpolation solution for 2D camera.

@export
var target: Node2D = null

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
	
	if !is_instance_valid(target):
		return
	
	_transform_curr = target.global_transform

func _apply_transform() -> void:
	if !enabled:
		return
	
	var weight: float = Engine.get_physics_interpolation_fraction()
	global_transform = _transform_prev.interpolate_with(_transform_curr, weight)
