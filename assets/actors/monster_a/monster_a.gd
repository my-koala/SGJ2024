@tool
extends Actor2D

# temporary monster script

# TODO: picking children up
# collecting candy
# TODO: move input to main, add actions to Actor

# on input, do a raycast for pickup
# if found one, pick up
# shake animation on action - enables a small hitbox?
# incidentally hits the picked up child
# if has no hitbox, then nothing happens, just shaking something lul
# compatible with other potential monster types that dont pick up (more freedom!)

# carry is "done", but could be cleaned up
# will probably consolidate code into a general Entity2D to include stuff like props/objects
# TODO: throwing will apply impulse to carriable
# TODO: maybe instead @export Entity2D in Carrier2D and Carriable2D, and move logic there
# carry affects momentum, height, collision exceptions, forces, all properties found on ACtor2D, so probs good idea

@export
var player: bool = false

@onready
var _avatar: Node2D = $avatar as Node2D
@onready
var _carrier: Carrier2D = $carry/carrier_2d as Carrier2D
@onready
var _carriable: Carriable2D = $carry/carriable_2d as Carriable2D
@onready
var _carry_remote_transform: RemoteTransform2D = $carry/carry_remote_transform_2d as RemoteTransform2D
@onready
var _carry_height_marker: Marker2D = $carry/carry_height_marker_2d as Marker2D

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_carrier.carry_started.connect(_on_carrier_carry_started)
	_carrier.carry_stopped.connect(_on_carrier_carry_stopped)
	_carriable.carry_started.connect(_on_carriable_carry_started)
	_carriable.carry_stopped.connect(_on_carriable_carry_stopped)

func _on_carrier_carry_started(carriable: Carriable2D) -> void:
	_carry_remote_transform.remote_path = _carry_remote_transform.get_path_to(carriable.owner)
	var physics_body: PhysicsBody2D = carriable.owner as PhysicsBody2D
	if is_instance_valid(physics_body):
		add_collision_exception_with(physics_body)

func _on_carrier_carry_stopped(carriable: Carriable2D) -> void:
	_carry_remote_transform.remote_path = NodePath()
	var physics_body: PhysicsBody2D = carriable.owner as PhysicsBody2D
	if is_instance_valid(physics_body):
		remove_collision_exception_with(physics_body)

func _on_carriable_carry_started(carrier: Carrier2D) -> void:
	freeze = true

func _on_carriable_carry_stopped(carrier: Carrier2D) -> void:
	freeze = false

var _input_move: Vector2 = Vector2.ZERO
var _input_carry: bool = false
var _input_drop: bool = false

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	
	if !player:
		return
	
	_input_move = Vector2.ZERO
	_input_move.x += int(Input.is_action_pressed("move_x+"))
	_input_move.x -= int(Input.is_action_pressed("move_x-"))
	_input_move.y += int(Input.is_action_pressed("move_y+"))
	_input_move.y -= int(Input.is_action_pressed("move_y-"))
	
	_input_carry = _input_carry || Input.is_action_just_pressed("carry")
	_input_drop = _input_drop || Input.is_action_just_pressed("drop")

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	#_animation_player.advance(delta)
	
	move_target_direction = _input_move
	
	if _input_carry:
		_input_carry = false
		_carrier.cast()
	
	if _input_drop:
		_input_drop = false
		_carrier.drop()
	
	super(delta)
	
	_avatar.position = Vector2(0.0, -air_height)
	
	if _carrier.has_carriable():
		var actor: Actor2D = _carrier.get_carriable().owner as Actor2D
		if is_instance_valid(actor):
			actor.air_height = _carry_remote_transform.global_position.y - _carry_height_marker.global_position.y
			var momentum: Vector2 = mass * linear_velocity
			var total_mass: float = mass + (actor.mass * 0.25)# arbitrary 0.25 for speeed
			linear_velocity = momentum / total_mass
