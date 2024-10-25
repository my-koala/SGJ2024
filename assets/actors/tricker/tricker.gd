@tool
extends Entity2D

@export
var candy_scene: PackedScene = null

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

@export
var scare_factor: float = 0.0
@export
var scare_speed: float = 1.0

@export
var candy_count: int = 0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	body_entered.connect(_on_body_entered)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	drop_candy()

func _on_body_entered(body: Node) -> void:
	var rigid_body: RigidBody2D = body as RigidBody2D
	if !is_instance_valid(rigid_body):
		return
	if linear_velocity.length() > 256.0:
		drop_candy()
	elif rigid_body.linear_velocity.length() > 256.0:
		drop_candy()

@export
var test_position_a: Vector2 = Vector2.ZERO
@export
var test_position_b: Vector2 = Vector2.ZERO
var _test_position_goal: bool = false

@export
var navigate: bool = false
var _navigation_sync: bool = false

@export
var infinite_candy: bool = false

func take_candy() -> void:
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
	
	if infinite_candy:
		_display_candy_label.text = "x∞"
	else:
		_display_candy_label.text = "x" + str(candy_count)
	
	if _detector.get_detectable_count() > 0:
		scare_factor = minf(scare_factor + (delta * scare_speed), 1.0)
	else:
		scare_factor = maxf(scare_factor - (delta * scare_speed), 0.0)
	
	if is_equal_approx(scare_factor, 1.0):
		print("IM SCARED AHHH")
	
	_display_scare.value = lerpf(_display_scare.min_value, _display_scare.max_value, scare_factor)
	_display_scare.visible = !is_zero_approx(scare_factor)
	
	if !_navigation_sync:
		_navigation_sync = true
	elif navigate:
		if _navigation_agent.is_navigation_finished():
			_test_position_goal = !_test_position_goal
			if _test_position_goal:
				_navigation_agent.target_position = test_position_a
			else:
				_navigation_agent.target_position = test_position_b
		
		var next_position: Vector2 = _navigation_agent.get_next_path_position()
		move_target_direction = global_position.direction_to(next_position)
	
	if linear_velocity.length() > 256.0 && is_airborne():
		_animation_player.play(&"spin")
	else:
		_animation_player.play(&"idle")
	
	super(delta)
