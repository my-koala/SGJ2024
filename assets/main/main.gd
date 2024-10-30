extends Node

const Menu: = preload("res://assets/menu/menu.gd")
const Map: = preload("res://assets/map/map.gd")

const MapScene: PackedScene = preload("res://assets/map/map.tscn")

@onready
var _game: Node = $game as Node
@onready
var _menu: Menu = $gui/menu as Menu

var _map: Map = null

func _ready() -> void:
	_menu.play.connect(_on_menu_play)
	_menu.pause.connect(_on_menu_pause)
	_menu.resume.connect(_on_menu_resume)
	_menu.menu.connect(_on_menu_menu)
	_menu.quit.connect(_on_menu_quit)

func _process(delta: float) -> void:
	if is_instance_valid(_map):
		_menu.set_global_scare_threshold_percents(_map.get_global_scare_threshold_percents())
		_menu.set_player_health_percent(_map.get_player_health_percent())

func _on_map_game_over(state: Map.GameOver, score: int) -> void:
	if state == Map.GameOver.NO_KIDS:
		_menu.lose(score, false)
	if state == Map.GameOver.DEAD:
		_menu.lose(score, true)
	if is_instance_valid(_map):
		_map.process_mode = Node.PROCESS_MODE_DISABLED

func _on_menu_play() -> void:
	if !is_instance_valid(_map):
		_map = MapScene.instantiate()
		_map.game_over.connect(_on_map_game_over)
		_game.add_child(_map)

func _on_menu_pause() -> void:
	if is_instance_valid(_map):
		_map.process_mode = Node.PROCESS_MODE_DISABLED

func _on_menu_resume() -> void:
	if is_instance_valid(_map):
		_map.process_mode = Node.PROCESS_MODE_INHERIT

func _on_menu_menu() -> void:
	if is_instance_valid(_map):
		_map.queue_free()
		_map = null

func _on_menu_quit() -> void:
	if is_instance_valid(_map):
		_map.queue_free()
		_map = null
	get_tree().quit()
