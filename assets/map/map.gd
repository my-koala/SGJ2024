@tool
extends Node2D

const TRICKER_SCENE: PackedScene = preload("res://assets/actors/tricker/tricker.tscn")

const DoorNetwork: = preload("res://assets/props/door/door_network.gd")
const Monster: = preload("res://assets/actors/monster/monster.gd")
const Hunter: = preload("res://assets/actors/hunter/hunter.gd")
const Tricker: = preload("res://assets/actors/tricker/tricker.gd")

signal map_stopped(game_over: GameOver, score: int)

enum GameOver { DEAD, NO_KIDS }

@export
var player: Monster = null

@export
var door_network: DoorNetwork = null

@export
var global_scare_tricker_amount: float = 5.0
@export
var global_scare_threshold_a: float = 60.0
@export
var global_scare_threshold_b: float = 120.0
@export
var global_scare_threshold_c: float = 180.0
var _global_scare: float = 0

func get_global_scare() -> float:
	return _global_scare

func get_player_health_percent() -> float:
	return player._health / player.health

func get_player_candy_count() -> int:
	return _player_collector.get_collected_count()

func get_tricker_count() -> int:
	return _trickers.size()

func get_global_scare_threshold_percents() -> Array[float]:
	var total: float = 0.0
	var threshold_a: float = clampf((_global_scare - total) / global_scare_threshold_a, 0.0, 1.0)
	total += global_scare_threshold_a
	var threshold_b: float = clampf((_global_scare - total) / global_scare_threshold_b, 0.0, 1.0)
	total += global_scare_threshold_b
	var threshold_c: float = clampf((_global_scare - total) / global_scare_threshold_c, 0.0, 1.0)
	total += global_scare_threshold_c
	return [threshold_a, threshold_b, threshold_c]

@onready
var _trickers_container: Node2D = $actors/trickers as Node2D
var _trickers: Array[Tricker] = []

@onready
var _hunters_a_container: Node2D = $actors/hunters_a as Node2D
var _hunters_a: Array[Hunter] = []
var _hunters_a_free: bool = false

@onready
var _hunters_b_container: Node2D = $actors/hunters_b as Node2D
var _hunters_b: Array[Hunter] = []
var _hunters_b_free: bool = false

@onready
var _hunters_c_container: Node2D = $actors/hunters_c as Node2D
var _hunters_c: Array[Hunter] = []
var _hunters_c_free: bool = false

@onready
var _world_environment: WorldEnvironment = $world_environment as WorldEnvironment

@onready var _player_carrier: Carrier2D = player.get_node_or_null("carrier_2d") as Carrier2D
@onready var _player_collector: Collector2D = player.get_node_or_null("collector_2d") as Collector2D

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	player.died.connect(_on_player_died)
	
	for child: Node in _trickers_container.get_children():
		var tricker: Tricker = child as Tricker
		if is_instance_valid(tricker):
			tricker.scared_started.connect(_on_tricker_scared_started)
			tricker.tree_exiting.connect(_on_tricker_tree_exiting.bind(tricker))
			_trickers.append(tricker)
	
	for child: Node in _hunters_a_container.get_children():
		var hunter: Hunter = child as Hunter
		if is_instance_valid(hunter):
			_hunters_a.append(hunter)
			hunter.process_mode = Node.PROCESS_MODE_DISABLED
	for child: Node in _hunters_b_container.get_children():
		var hunter: Hunter = child as Hunter
		if is_instance_valid(hunter):
			_hunters_b.append(hunter)
			hunter.process_mode = Node.PROCESS_MODE_DISABLED
	for child: Node in _hunters_c_container.get_children():
		var hunter: Hunter = child as Hunter
		if is_instance_valid(hunter):
			_hunters_c.append(hunter)
			hunter.process_mode = Node.PROCESS_MODE_DISABLED

func _on_tricker_tree_exiting(tricker: Tricker) -> void:
	_trickers.erase(tricker)
	print("goodbye tricker...")

func _on_tricker_scared_started() -> void:
	_global_scare += global_scare_tricker_amount

func _on_player_died() -> void:
	var environment: Environment = _world_environment.environment
	var tween: Tween = create_tween()
	
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.set_parallel(false)
	tween.tween_property(environment, NodePath("adjustment_saturation"), 0.01, 0.75)
	tween.tween_property(environment, NodePath("adjustment_saturation"), 0.01, 1.0)
	await tween.finished
	map_stopped.emit(GameOver.DEAD, _player_collector.get_collected_count())
	process_mode = Node.PROCESS_MODE_DISABLED

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	_global_scare += delta
	if !_hunters_a_free && (_global_scare >= global_scare_threshold_a):
		_hunters_a_free = true
		for hunter: Hunter in _hunters_a:
			hunter.process_mode = Node.PROCESS_MODE_INHERIT
	if !_hunters_b_free && (_global_scare >= global_scare_threshold_b):
		_hunters_b_free = true
		for hunter: Hunter in _hunters_b:
			hunter.process_mode = Node.PROCESS_MODE_INHERIT
	if !_hunters_c_free && (_global_scare >= global_scare_threshold_c):
		_hunters_c_free = true
		for hunter: Hunter in _hunters_c:
			hunter.process_mode = Node.PROCESS_MODE_INHERIT
	
	if _trickers.is_empty():
		map_stopped.emit(GameOver.NO_KIDS, get_player_candy_count())
