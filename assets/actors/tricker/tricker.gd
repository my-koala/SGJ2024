@tool
extends Entity2D

@export
var candy_scene: PackedScene = null

@onready
var _carriable: Carriable2D = $carriable_2d as Carriable2D

@onready
var _hurtbox: Area2D = $hurtbox_2d as Area2D

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if is_instance_valid(candy_scene):
		var candy: Entity2D = candy_scene.instantiate() as Entity2D
		candy.global_position = global_position
		candy.air_height = air_height
		var impulse: Vector2 = 192.0 * Vector2(cos(randf() * TAU), sin(randf() * TAU))
		candy.apply_central_impulse(impulse)
		add_sibling.call_deferred(candy)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	super(delta)
	
