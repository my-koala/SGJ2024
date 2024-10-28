extends StaticBody2D

@export
var root: Node2D = null

@export
var active: bool = false

@onready
var _animation_player: AnimationPlayer = $animation_player as AnimationPlayer

var _candy_getters: int = 0

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_animation_player.play(&"closed")

func add_candy_getter() -> void:
	_candy_getters += 1

func remove_candy_getter() -> void:
	_candy_getters -= 1

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var current_animation: StringName = _animation_player.current_animation
	
	if _candy_getters > 0:
		# open
		if (current_animation != &"opening") && (current_animation != &"opened"):
			_animation_player.play(&"opening")
			_animation_player.queue(&"opened")
	else:
		if (current_animation != &"closing") && (current_animation != &"closed"):
			_animation_player.play(&"closing")
			_animation_player.queue(&"closed")
