@tool
extends Node2D

@export
var player: Entity2D = null

const TRICKER: PackedScene = preload("res://assets/actors/tricker/tricker.tscn")

@export
var candy_to_win: int = 16

@onready
var _candy_goal: Label = $canvas_layer/goal as Label

@onready
var _candy_count: Label = $canvas_layer/count as Label

@onready
var _animation_player: AnimationPlayer = $canvas_layer/animation_player as AnimationPlayer

@onready
var _button_spawn_kid: Button = $canvas_layer/spawn_kid as Button

@onready
var _power_slider: Slider = $canvas_layer/power/h_slider
@onready
var _power_label: Label = $canvas_layer/power as Label

@onready var _player_carrier: Carrier2D = player.get_node_or_null("carrier_2d") as Carrier2D
@onready var _player_collector: Collector2D = player.get_node_or_null("collector_2d") as Collector2D

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_button_spawn_kid.pressed.connect(_button_spawn_kid_pressed)
	_power_slider.min_value = _player_carrier.dropkick_impulse

var _won: bool = false

func _button_spawn_kid_pressed() -> void:
	var tricker: Entity2D = TRICKER.instantiate() as Entity2D
	tricker.global_position = player.global_position + (Vector2.DOWN * 16.0)
	tricker.set(&"infinite_candy", true)
	add_child(tricker)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var candy_count: int = _player_collector.get_collected_count()
	
	_candy_goal.text = "goal: collect " + str(candy_to_win) + " candy"
	_candy_count.text = "candy count: " + str(candy_count)
	
	_power_label.text = "dropkick power\n" + str(_player_carrier.dropkick_impulse)
	_player_carrier.dropkick_impulse = _power_slider.value
	
	if !_won && (candy_count >= candy_to_win):
		_won = true
		_animation_player.play(&"win")
