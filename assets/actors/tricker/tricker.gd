@tool
extends Entity2D

const Door: = preload("res://assets/props/door/door.gd")
const DoorNetwork: = preload("res://assets/props/door/door_network.gd")

# BUG:
# nav paths aren't recalculated when outside nav region
# possible fix is to create two nav regions: grass and pavement, rather than navigation on pavement only

# TODO:
# scared state
# permanently home after X scares? (maybe some ui to indicate # of scares)

# TODO:
# assign each tricker a specific scream rather than random?

@export
var door_network: DoorNetwork = null

@export
var candy_scene: PackedScene = null
@export
var assigned_door: int = 0
@export
var door_index_skip: int = 1
var _door_index_target: int = 0
@export
var door_timer: float = 2.0
var _door_timer: float = 0.0

@export
var scare_factor: float = 0.0
@export
var scare_speed: float = 1.0
var _scare_persist: bool = false
var _scared: bool = false
var _scarer: Node2D = null
var _scare_fled: bool = false

@export
var scare_timer: float = 5.0
var _scare_timer: float = 0.0
var _scare_await_airborne: bool = false

@export
var candy_count: int = 0
@export
var navigate: bool = false
var _navigation_sync: bool = false

@export
var infinite_candy: bool = false

@onready
var _carriable: Carriable2D = $carriable_2d as Carriable2D
@onready
var _hurtbox: Area2D = $hurtbox_2d as Area2D
@onready
var _navigation_agent: NavigationAgent2D = $navigation_agent_2d as NavigationAgent2D
@onready
var _display_candy_label: Label = $avatar/display/candy/label as Label
@onready
var _display_scare: TextureProgressBar = $avatar/display/scare as TextureProgressBar
@onready
var _detector: Detector2D = $detector_2d as Detector2D
@onready
var _avatar_sprite: Sprite2D = $avatar/sprite_2d as Sprite2D
@onready
var _animation_player: AnimationPlayer = $animation_player as AnimationPlayer

@onready
var _lantern_light: PointLight2D = $detector_2d/lantern_light as PointLight2D

@onready
var _audio_screams: Array[AudioStreamPlayer2D] = [
	$audio/scream_1 as AudioStreamPlayer2D,
	$audio/scream_2 as AudioStreamPlayer2D,
	$audio/scream_3 as AudioStreamPlayer2D,
	$audio/scream_4 as AudioStreamPlayer2D,
	$audio/scream_5 as AudioStreamPlayer2D,
	$audio/scream_6 as AudioStreamPlayer2D,
	$audio/scream_7 as AudioStreamPlayer2D,
	$audio/scream_8 as AudioStreamPlayer2D,
	$audio/scream_9 as AudioStreamPlayer2D,
	$audio/scream_10 as AudioStreamPlayer2D,
	$audio/scream_11 as AudioStreamPlayer2D,
]

enum AIState {
	NONE,
	FIND_DOOR,
	GO_DOOR,
	AT_DOOR,
	SCARE,
	HOME,
}

var _ai_state_curr: AIState = AIState.NONE

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	body_entered.connect(_on_body_entered)
	_carriable.drop_kicked.connect(_on_carriable_drop_kicked)
	
	global_position = door_network.doors[assigned_door % door_network.doors.size()].global_position

func _on_carriable_drop_kicked() -> void:
	_audio_screams[randi_range(0, 10)].play()# scream

func _on_hurtbox_area_entered(area: Area2D) -> void:
	drop_candy()

func _on_body_entered(body: Node) -> void:
	# TODO: blood and gore on static body
	var rigid_body: RigidBody2D = body as RigidBody2D
	if !is_instance_valid(rigid_body):
		return
	if linear_velocity.length() > 256.0:
		drop_candy()
	elif rigid_body.linear_velocity.length() > 256.0:
		drop_candy()

func take_candy() -> void:
	if !infinite_candy:
		candy_count += 1

func drop_candy() -> void:
	if !infinite_candy && candy_count == 0:
		return
	
	if !infinite_candy:
		candy_count -= 1
	
	if is_instance_valid(candy_scene):
		var candy: Entity2D = candy_scene.instantiate() as Entity2D
		candy.global_position = global_position
		candy.air_height = air_height
		var impulse: Vector2 = 192.0 * Vector2(cos(randf() * TAU), sin(randf() * TAU))
		candy.apply_central_impulse(impulse)
		add_sibling.call_deferred(candy)
	
	# red flash
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.tween_property(_avatar_sprite, NodePath("modulate"), Color.RED, 0.05)
	tween.set_parallel(false)
	tween.tween_property(_avatar_sprite, NodePath("modulate"), Color.WHITE, 0.125)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	# candy stuff
	if infinite_candy:
		_display_candy_label.text = "x∞"
	else:
		_display_candy_label.text = "x" + str(candy_count)
	
	# scare stuff
	if _carriable.has_carrier():
		scare_factor = 1.0
	elif _detector.get_detectable_count() > 0:
		scare_factor = minf(scare_factor + (delta * scare_speed), 1.0)
	elif !_scare_persist:
		scare_factor = maxf(scare_factor - (delta * scare_speed), 0.0)
	_scared = is_equal_approx(scare_factor, 1.0)
	_display_scare.value = lerpf(_display_scare.min_value, _display_scare.max_value, scare_factor)
	_display_scare.visible = !is_zero_approx(scare_factor)
	
	move_speed = 48.0
	face_speed = 0.5
	
	# beeb boop
	match _ai_state_curr:
		AIState.NONE:
			_ai_state_curr = AIState.FIND_DOOR
			_door_index_target = assigned_door
		AIState.FIND_DOOR:
			# get next door
			_door_index_target += door_index_skip
			_door_index_target = _door_index_target % door_network.doors.size()
			
			_navigation_agent.target_position = door_network.doors[_door_index_target].root.global_position
			_ai_state_curr = AIState.GO_DOOR
		AIState.GO_DOOR:
			if _navigation_agent.is_navigation_finished():
				if !_navigation_agent.is_target_reachable():
					print("couldnt reach nav target (your nav map sucks)")
					# get another door i guess
					_ai_state_curr = AIState.FIND_DOOR
				else:
					door_network.doors[_door_index_target].add_candy_getter()
					_ai_state_curr = AIState.AT_DOOR
			
			if _scared:
				_ai_state_curr = AIState.SCARE
		AIState.AT_DOOR:
			# do some timer?
			_door_timer += delta
			if _door_timer > door_timer:
				door_network.doors[_door_index_target].remove_candy_getter()
				_door_timer = 0.0
				take_candy()
				_ai_state_curr = AIState.FIND_DOOR
			
			if _scared:
				door_network.doors[_door_index_target].remove_candy_getter()
				_door_timer = 0.0
				_ai_state_curr = AIState.SCARE
		AIState.SCARE:
			_scare_persist = true
			_scare_timer += delta
			
			if _detector.get_detectable_count() > 0:
				_scare_timer = 0.0
				if !is_instance_valid(_scarer):
					_scarer = _detector.get_detectable(0)
			
			if is_instance_valid(_scarer):
				var distance: float = global_position.distance_to(_scarer.global_position)
				var too_close: bool = distance < 64.0
				
				if distance < 64.0:
					_scare_timer = 0.0
					if _navigation_agent.is_navigation_finished():
						_scare_fled = false
				
				if !_scare_fled && !is_airborne():
					var flee_direction: Vector2 = -global_position.direction_to(_scarer.global_position)
					_navigation_agent.target_position = global_position + (flee_direction * 160.0)
					_scare_fled = true
			
			move_speed = 96.0
			face_speed = 4.0
			
			if _scare_timer > scare_timer:
				_scare_timer = 0.0
				_scare_persist = false
				_scarer = null
				_scare_fled = false
				# do some check for max scares?
				_ai_state_curr = AIState.FIND_DOOR
	
	if !_navigation_sync:
		_navigation_sync = true
	elif navigate && !_navigation_agent.is_navigation_finished() && !is_airborne():
		if linear_velocity.length_squared() < 0.1:
			# fix getting stuck by recalculating navigation
			_navigation_agent.navigation_layers = 0
			_navigation_agent.navigation_layers = 1
		var next_position: Vector2 = _navigation_agent.get_next_path_position()
		move_target_direction = global_position.direction_to(next_position)
		face_target_direction = move_target_direction.normalized()
	else:
		move_target_direction = Vector2.ZERO
	
	_detector.rotation = -face_direction.angle_to(Vector2.DOWN)
	
	if is_airborne():
		_lantern_light.enabled = false
	else:
		_lantern_light.enabled = true
	
	if linear_velocity.length() > 256.0 && is_airborne():
		_animation_player.play(&"spin")
	else:
		_animation_player.play(&"idle")
	
	super(delta)
