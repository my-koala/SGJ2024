@tool
extends Entity2D

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

# TODO: move carry logic into Carrier2D, and export Entity2D instead

# TODO: add drop kicking wtfff

const HunterTarget: = preload("res://assets/actors/hunter/hunter_target.gd")

signal died()

@export
var player: bool = false

@onready
var _avatar: Node2D = $avatar as Node2D
@onready
var _carrier: Carrier2D = $carrier_2d as Carrier2D
@onready
var _carriable: Carriable2D = $carriable_2d as Carriable2D
@onready
var _animation_player: AnimationPlayer = $animation_player as AnimationPlayer
@onready
var _hunter_target: HunterTarget = $hunter_target as HunterTarget
@export
var health: float = 100.0
var _health: float = 100.0
@onready
var _audio_hurt: AudioStreamPlayer2D = $audio/hurt as AudioStreamPlayer2D
@onready
var _avatar_sprite: Sprite2D = $avatar/sprite_2d as Sprite2D

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	_health = health
	_hunter_target.hit.connect(_on_hunter_target_hit)
	_animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL

func _on_hunter_target_hit(damage: float) -> void:
	_health -= damage
	if _health <= 0.0:
		died.emit()
	_audio_hurt.play()
	
	# red flash
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.tween_property(_avatar_sprite, NodePath("modulate"), Color.RED, 0.05)
	tween.set_parallel(false)
	tween.tween_property(_avatar_sprite, NodePath("modulate"), Color.WHITE, 0.125)

var _input_move: Vector2 = Vector2.ZERO
var _input_carry: bool = false
var _input_drop: bool = false
var _input_dropkick: bool = false
var _input_shake: bool = false

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
	
	_input_carry = _input_carry || Input.is_action_just_pressed("pickup")
	_input_drop = _input_drop || Input.is_action_just_pressed("drop")
	_input_dropkick = _input_dropkick || Input.is_action_just_pressed("dropkick")
	_input_shake = Input.is_action_pressed("shake")

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if _health <= 0.0:
		# play death animation
		move_target_direction = Vector2.ZERO
		face_target_direction = Vector2.ZERO
		_animation_player.play(&"monster_a/death")
		_animation_player.advance(delta)
		#linear_velocity = Vector2.ZERO
		super(delta)
		return
	
	move_target_direction = _input_move
	if !_input_move.is_zero_approx():
		face_target_direction = _input_move
	
	var shake_anim: bool = false
	if _input_carry:
		_input_carry = false
		_carrier.grab()
	
	if _input_shake:
		shake_anim = true
	
	var drop_anim: bool = false
	if _input_drop:
		drop_anim = true
		_input_drop = false
	
	var dropkick_anim: bool = false
	if _input_dropkick:
		dropkick_anim = true
		_input_dropkick = false
	
	var angle: float = face_direction.angle_to(Vector2.DOWN)
	var blend_face: int = posmod(roundi(angle / (0.5 * PI)), 4)
	
	# TODO later: use an enum state machine instead of this string comparison mess
	
	var current_animation: StringName = &""
	var current_blend: float = 0.0
	if _animation_player.is_playing():
		current_animation = _animation_player.current_animation
		current_blend = _animation_player.current_animation_position / _animation_player.current_animation_length
	
	if current_animation.begins_with("monster_a/carry_pickup-"):
		pass
	elif current_animation.begins_with("monster_a/carry_drop-"):
		pass
	elif current_animation.begins_with("monster_a/carry_dropkick-"):
		pass
	elif _carrier.has_carriable():
		if _animation_player.is_playing() && !current_animation.begins_with("monster_a/carry"):
			_animation_player.play(&"monster_a/carry_pickup-" + str(blend_face))
		elif drop_anim:
			_animation_player.play(&"monster_a/carry_drop-" + str(blend_face))
		elif dropkick_anim:
			_animation_player.play(&"monster_a/carry_dropkick-" + str(blend_face))
		elif shake_anim:
			_animation_player.play(&"monster_a/carry_shake-0")
		elif !is_move_active():
			_animation_player.play(&"monster_a/carry_idle-" + str(blend_face))
		else:
			_animation_player.play(&"monster_a/carry_move-" + str(blend_face))
			if current_animation != _animation_player.current_animation && current_animation.begins_with("monster_a/carry_move-"):
				_animation_player.seek(current_blend * _animation_player.current_animation_length, true)
				_animation_player.advance(0.0)
	elif current_animation.begins_with("monster_a/carry"):
		pass# play drop?
		_animation_player.stop()
	else:
		if !is_move_active():
			_animation_player.play(&"monster_a/idle-" + str(blend_face))
		else:
			_animation_player.play(&"monster_a/move-" + str(blend_face))
			if current_animation != _animation_player.current_animation && current_animation.begins_with("monster_a/move-"):
				_animation_player.seek(current_blend * _animation_player.current_animation_length, true)
				_animation_player.advance(0.0)
	
	_animation_player.advance(delta)
	super(delta)
