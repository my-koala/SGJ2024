# code by my-koala ͼ•ᴥ•ͽ #
@tool
extends RigidBody2D
class_name Entity2D

# Basic entity controller.
# TODO: rework deceleration as functional friction?
# TODO for other projects: reimplement air friction, ground friction (properly)
# move move stuff to actor specific scripts

const GRAVITY: float = 490.0

#region Move Properties

@export_group("Move")

## The entity's base move speed (in pixels per second).
@export_range(0.0, 1.0, 0.05, "or_greater", "hide_slider")
var move_speed: float = 64.0:
	get:
		return move_speed
	set(value):
		move_speed = maxf(value, 0.0)

## The entity's base move acceleration (in pixels per second squared).
@export_range(0.0, 1.0, 0.05, "or_greater", "hide_slider")
var move_acceleration: float = 256.0:
	get:
		return move_acceleration
	set(value):
		move_acceleration = maxf(value, 0.0)

## The entity's base move deceleration (in pixels per second squared).
@export_range(0.0, 1.0, 0.05, "or_greater", "hide_slider")
var move_deceleration: float = 2048.0:
	get:
		return move_deceleration
	set(value):
		move_deceleration = maxf(value, 0.0)

var _move_active: bool = false
func is_move_active() -> bool:
	return _move_active

#endregion
#region Face Properties

@export_group("Face")

## The entity's facing direction. Direction is normalized.
@export
var face_direction: Vector2 = Vector2.DOWN:
	get:
		return face_direction
	set(value):
		if !value.is_zero_approx():
			face_direction = value.normalized()

## The entity's speed when rotating towards face_target_direction (in rotations per second).
@export_range(0.0, 1.0, 0.05, "or_greater", "hide_slider")
var face_speed: float = 4.0:
	get:
		return face_speed
	set(value):
		face_speed = maxf(value, 0.0)

# Targets for controlling entity (via main)

## The target direction to move towards. Direction is normalized.
@export
var move_target_direction: Vector2 = Vector2.ZERO:
	get:
		return move_target_direction
	set(value):
		move_target_direction = value.normalized()

## The target direction to rotate facing towards. Direction is normalized.
@export
var face_target_direction: Vector2 = Vector2.ZERO:
	get:
		return face_target_direction
	set(value):
		face_target_direction = value.normalized()

#endregion
#region Air Properties

@export_group("Air")

## The simulated height from the ground (does not affect transform). This is read for offsetting visuals.
@export_range(0.0, 1.0, 0.05, "or_greater", "hide_slider")
var air_height: float = 0.0:
	get:
		return air_height
	set(value):
		air_height = maxf(value, 0.0)

## The velocity on the simualated height axis. Affected by gravity.
@export_range(-1.0, 1.0, 0.05, "or_greater", "or_less", "hide_slider")
var air_velocity: float = 0.0:
	get:
		return air_velocity
	set(value):
		air_velocity = value

## The coefficient for move acceleration while airborne.
@export_range(0.0, 1.0, 0.05)
var air_control: float = 0.125:
	get:
		return air_control
	set(value):
		air_control = clampf(value, 0.0, 1.0)

## The Node2D to apply air height to position (sets y).
@export
var air_transform: Node2D = null:
	get:
		return air_transform
	set(value):
		air_transform = value

func is_airborne() -> bool:
	return air_height > 0.0

var anchor_transform: Node2D = null

#endregion

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if Engine.is_editor_hint():
		return
	
	#if is_instance_valid(anchor_transform):
	#	state.transform = anchor_transform.global_transform

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	# Air Logic #
	if !freeze && (air_height > 0.0):
		air_velocity += GRAVITY * delta
		air_height = maxf(air_height - (air_velocity * delta), 0.0)
	else:
		air_velocity = 0.0
	
	# Modifier Logic #
	var move_speed_modifier: float = 1.0
	var move_acceleration_modifier: float = 1.0
	var move_deceleration_modifier: float = 1.0
	var face_speed_modifier: float = 1.0
	var air_control_modifier: float = 1.0
	
	# TODO: use and iterate through some array of modifiers?
	
	if is_airborne():
		move_acceleration_modifier *= air_control * air_control_modifier
		move_deceleration_modifier *= air_control * air_control_modifier
	
	# Move Logic #
	# Calculate necessary acceleration to move towards query direction.
	var move_query_velocity: Vector2 = move_target_direction * move_speed * move_speed_modifier
	var move_query_acceleration: Vector2 = (move_query_velocity - linear_velocity) / delta
	if !move_target_direction.is_zero_approx():
		move_query_acceleration = move_query_acceleration.limit_length(move_acceleration * move_acceleration_modifier)
		_move_active = true
	else:
		move_query_acceleration = move_query_acceleration.limit_length(move_deceleration * move_deceleration_modifier)
		_move_active = false
	
	if !move_query_acceleration.is_zero_approx():
		apply_central_force(mass * move_query_acceleration)
	
	# Face Logic #
	if !face_target_direction.is_zero_approx():
		# Spherical interpolate towards face_target_direction.
		var face_query_speed: float = face_speed * face_speed_modifier * TAU
		var theta: float = absf(face_direction.angle_to(face_target_direction))
		if !is_zero_approx(theta):
			var weight: float = clampf((face_query_speed * delta) / theta, 0.0, 1.0)
			face_direction = face_direction.slerp(face_target_direction, weight)
	
	if is_instance_valid(air_transform):
		air_transform.position.y = -air_height
