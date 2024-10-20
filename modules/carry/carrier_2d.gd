@tool
extends Node2D
class_name Carrier2D

# queue_cast -> next physics frame, raycast for pickups
# pick first pickup found (no hit inside)
# TODO: figure out drawing and moving pickupable.
# ysorting is a problem too
# no reparenting!!! keep scene tree clean and pristine!
# IDEA: export two RemoteTransform2D? one for physics body, other for visual sprite
# (necessary for proper ysorting)
# NOTE: on pickup, disable collision (only the body collision for the pickupable/tricker)
# keep hitbox so candy can drop on shake

signal carry_started(carriable: Carriable2D)
signal carry_stopped(carriable: Carriable2D)

@export
var enabled: bool = true

@export
var cast_position: Vector2 = Vector2.DOWN * 16.0

@export_flags_2d_physics
var collision_mask: int = 1 << 0

@export_group("Collide With", "collide_with_")
@export
var collide_with_areas: bool = true
@export
var collide_with_bodies: bool = false

var _queue_cast: bool = false
func cast() -> void:
	# Defer cast to physics frame.
	_queue_cast = true

func drop() -> void:
	if !is_instance_valid(_carriable):
		return
	
	carry_stopped.emit(_carriable)
	_carriable.carry_stopped.emit(self)
	_carriable._carrier = null
	_carriable = null

var _carriable: Carriable2D = null
func get_carriable() -> Carriable2D:
	return _carriable

func has_carriable() -> bool:
	return is_instance_valid(_carriable)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if !_queue_cast:
		return
	_queue_cast = false
	
	if !enabled:
		return
	
	if is_instance_valid(_carriable):
		return
	
	# Query a ray cast in physics space. TODO: exclude parent?
	var dss: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
	query.collide_with_areas = collide_with_areas
	query.collide_with_bodies = collide_with_bodies
	query.collision_mask = collision_mask
	query.from = global_position
	query.to = global_position + cast_position
	query.hit_from_inside = false
	query.exclude = []
	
	var result: Dictionary = dss.intersect_ray(query)
	if result.is_empty():
		return
	
	var carriable: Carriable2D = result["collider"] as Carriable2D
	if !is_instance_valid(carriable):
		return
	
	# Can't pick up something that's already picked up! (for now...)
	if is_instance_valid(carriable._carrier):
		return
	
	carriable._carrier = self
	_carriable = carriable
	
	carry_started.emit(_carriable)
	_carriable.carry_started.emit(self)
