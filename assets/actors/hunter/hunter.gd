@tool
extends Entity2D

# TODO: fix detectable to use raycasting check
# add gun stuff

const HunterTarget := preload("hunter_target.gd")

@export
var patrol_waypoints: Array[Node2D] = []
var _patrol_waypoint: int = 0

@export
var navigate: bool = true
var _navigation_sync: bool = false

@export
var scare_speed: float = 1.0
var _scare_persist: bool = false
var _scare_factor: float = 0.0

@export
var scare_timer: float = 3.0
var _scare_timer: float = 0.0

@onready
var _gun_ray_cast: RayCast2D = $gun/ray_cast_2d as RayCast2D
@onready
var _gun_particles: CPUParticles2D = $avatar/sprite_2d/gun_sprite/gun_particles as CPUParticles2D
@onready
var _display_scare: TextureProgressBar = $avatar/display/scare as TextureProgressBar
@onready
var _animation_player: AnimationPlayer = $animation_player as AnimationPlayer
@onready
var _detector: Detector2D = $detector_2d as Detector2D
@onready
var _navigation_agent: NavigationAgent2D = $navigation_agent_2d as NavigationAgent2D
@onready
var _carriable: Carriable2D = $carriable_2d as Carriable2D

enum AIState { NONE, PATROL, CHASE, CHASE_LOST }
var _ai_state_curr: AIState = AIState.NONE

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	

@export
var shoot_pellets: int = 4
@export
var shoot_distance: float = 112.0
@export
var shoot_cooldown: float = 1.0
@export
var shoot_damage: float = 25.0
var _shoot_cooldown: float = 0.0
func shoot() -> void:
	for particle: int in shoot_pellets:
		_gun_particles.restart()
	if _gun_ray_cast.is_colliding():
		var hunter_target: HunterTarget = _gun_ray_cast.get_collider() as HunterTarget
		if is_instance_valid(hunter_target):
			hunter_target.hit.emit(shoot_damage)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	# scare stuff
	if _carriable.has_carrier() || _scare_persist:
		_scare_factor = 1.0
	elif _detector.get_detectable_count() > 0:
		_scare_factor = minf(_scare_factor + (delta * scare_speed), 1.0)
	else:
		_scare_factor = maxf(_scare_factor - (delta * scare_speed), 0.0)
	var scared: bool = is_equal_approx(_scare_factor, 1.0)
	_display_scare.value = lerpf(_display_scare.min_value, _display_scare.max_value, _scare_factor)
	_display_scare.visible = !is_zero_approx(_scare_factor)
	
	match _ai_state_curr:
		AIState.NONE:
			_ai_state_curr = AIState.PATROL
		AIState.PATROL:
			if !patrol_waypoints.is_empty():
				if _navigation_agent.is_navigation_finished():
					_patrol_waypoint = (_patrol_waypoint + 1) % patrol_waypoints.size()
				_navigation_agent.target_position = patrol_waypoints[_patrol_waypoint].global_position
			
			if scared:
				_ai_state_curr = AIState.CHASE
		AIState.CHASE:
			_scare_persist = true
			_scare_timer += delta
			_shoot_cooldown += delta
			
			if _detector.get_detectable_count() > 0:
				var scarer: Node2D = _detector.get_detectable(0)
				var distance: float = global_position.distance_to(scarer.global_position)
				
				if (distance < shoot_distance) && !is_airborne():
					_scare_timer = 0.0
					if _shoot_cooldown > shoot_cooldown:
						_shoot_cooldown = 0.0
						shoot.call_deferred()
				_navigation_agent.target_position = scarer.global_position
			
			if _scare_timer > scare_timer:
				_scare_timer = 0.0
				_scare_persist = false
				_ai_state_curr = AIState.PATROL
	
	if !_navigation_sync:
		_navigation_sync = true
	elif navigate && !_navigation_agent.is_navigation_finished() && !is_airborne():
		if linear_velocity.length_squared() < 0.1:
			# HACK: fix getting stuck by recalculating navigation
			_navigation_agent.navigation_layers = 0
			_navigation_agent.navigation_layers = 1
		var next_position: Vector2 = _navigation_agent.get_next_path_position()
		move_target_direction = global_position.direction_to(next_position)
		face_target_direction = move_target_direction.normalized()
	else:
		move_target_direction = Vector2.ZERO
	
	_detector.rotation = -face_direction.angle_to(Vector2.DOWN)
	_gun_ray_cast.rotation = -face_direction.angle_to(Vector2.DOWN)
	_gun_particles.rotation = -face_direction.angle_to(Vector2.DOWN)
	
	# animation
	var left: bool = absf(face_direction.angle_to(Vector2.LEFT)) < (PI / 2.0)
	var dir: String = "l" if left else "r"
	
	if linear_velocity.length() > 128.0 && is_airborne():
		_animation_player.play(StringName("hunter/spin-") + dir)
	elif !is_move_active():
		_animation_player.play(StringName("hunter/idle-" + dir))
	else:
		_animation_player.play(StringName("hunter/move-" + dir))
	
	super(delta)
