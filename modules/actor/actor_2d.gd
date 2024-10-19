# code by my-koala ͼ•ᴥ•ͽ #
@tool
extends RigidBody2D
class_name Actor2D

# basic actor controller for all game actors
# todo: powerups/modifiers/effects?

@export_group("Move")

## Move speed as units per second.
@export_range(0.0, 1.0, 0.05, "or_greater")
var move_speed: float = 64.0:
	get:
		return move_speed
	set(value):
		move_speed = maxf(value, 0.0)

## Move acceleration as units per second squared.
@export_range(0.0, 1.0, 0.05, "or_greater")
var move_acceleration: float = 256.0:
	get:
		return move_acceleration
	set(value):
		move_acceleration = maxf(value, 0.0)

## Move deceleration as units per second squared.
@export_range(0.0, 1.0, 0.05, "or_greater")
var move_deceleration: float = 512.0:
	get:
		return move_deceleration
	set(value):
		move_deceleration = maxf(value, 0.0)

var _move_active: bool = false

func is_move_active() -> bool:
	return _move_active

@export_group("Face")

## Face direction.
## Direction is always normalized.
@export
var face_direction: Vector2 = Vector2.DOWN:
	get:
		return face_direction
	set(value):
		if !value.is_zero_approx():
			face_direction = value.normalized()

## Face rotation speed towards face_target_direction as rotations per second.
@export_range(0.0, 1.0, 0.05, "or_greater")
var face_speed: float = 4.0:
	get:
		return face_speed
	set(value):
		face_speed = maxf(value, 0.0)

# Targets for controlling actor (via main)

## Move target direction to move towards.
## Direction is always zero or normalized.
@export
var move_target_direction: Vector2 = Vector2.ZERO:
	get:
		return move_target_direction
	set(value):
		move_target_direction = value.normalized()

## Face target direction to rotate face towards.
## Direction is always zero or normalized.
@export
var face_target_direction: Vector2 = Vector2.ZERO:
	get:
		return face_target_direction
	set(value):
		face_target_direction = value.normalized()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	# Move Logic #
	# Calculate necessary acceleration to move towards query direction.
	var move_query_velocity: Vector2 = move_target_direction * move_speed
	var move_query_acceleration: Vector2 = (move_query_velocity - linear_velocity) / delta
	if !move_target_direction.is_zero_approx():
		move_query_acceleration = move_query_acceleration.limit_length(move_acceleration)
		_move_active = true
	else:
		move_query_acceleration = move_query_acceleration.limit_length(move_deceleration)
		_move_active = false
	
	if !move_query_acceleration.is_zero_approx():
		apply_central_force(mass * move_query_acceleration)
	
	# Face Logic #
	if !face_target_direction.is_zero_approx():
		# Spherical interpolate towards face_target_direction.
		var face_query_speed: float = face_speed * TAU
		var theta: float = absf(face_direction.angle_to(face_target_direction))
		var weight: float = clampf((face_query_speed * delta) / theta, 0.0, 1.0)
		face_direction = face_direction.slerp(face_target_direction, weight)
