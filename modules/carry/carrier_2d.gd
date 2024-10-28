@tool
extends RayCast2D
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

@export
var entity: Entity2D = owner as Entity2D

@export
var exclude: Array[CollisionObject2D] = []:
	get:
		return exclude
	set(value):
		for collision_object: CollisionObject2D in exclude:
			remove_exception(collision_object)
		exclude = value
		for collision_object: CollisionObject2D in exclude:
			add_exception(collision_object)

@export
var dropkick_impulse: float = 12000.0
@export
var dropkick_height_velocity: float = -64.0

@export
var remote_transform: RemoteTransform2D = null

@export
var remote_transform_offset: Node2D = null

var _carriable: Carriable2D = null

func get_carriable() -> Carriable2D:
	return _carriable

func has_carriable() -> bool:
	return is_instance_valid(_carriable)

func grab() -> void:
	if has_carriable() || !is_colliding():
		return
	
	var carriable: Carriable2D = get_collider() as Carriable2D
	if !is_instance_valid(carriable):
		return
	
	if carriable.has_carrier():
		return
	
	_carriable = carriable
	carriable._carrier = self
	
	remote_transform.remote_path = remote_transform.get_path_to(_carriable.entity)
	#_carriable.entity.anchor_transform = remote_transform
	entity.add_collision_exception_with(_carriable.entity)
	_carriable.entity.freeze = true

func drop() -> void:
	if !has_carriable():
		return
	
	remote_transform.remote_path = NodePath()
	#_carriable.entity.anchor_transform = null
	entity.remove_collision_exception_with(_carriable.entity)
	_carriable.entity.freeze = false
	
	_carriable._carrier = null
	_carriable = null

func dropkick(direction: Vector2) -> void:
	if !has_carriable():
		return
	
	remote_transform.remote_path = NodePath()
	entity.remove_collision_exception_with(_carriable.entity)
	_carriable.entity.freeze = false
	
	_carriable.entity.air_velocity = dropkick_height_velocity
	_carriable.entity.apply_central_impulse(direction * dropkick_impulse)
	
	_carriable.drop_kicked.emit()
	
	_carriable._carrier = null
	_carriable = null

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if has_carriable():
		var air_height: float = remote_transform.global_position.y
		air_height -= remote_transform_offset.global_position.y
		
		_carriable.entity.air_height = air_height
		
		var momentum: Vector2 = entity.mass * entity.linear_velocity
		var total_mass: float = entity.mass + (_carriable.entity.mass * 0.75)# arbitrary coeff for speeed
		entity.linear_velocity = momentum / total_mass
