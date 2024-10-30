@tool
extends Area2D
class_name Collector2D

signal collected()

@export var vacuum_force: float = 50.0 
@export var collect_distance: float = 16
var collectables: Array[Collectable2D] = []

var _collected_count: int = 0
func get_collected_count() -> int:
	return _collected_count

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	for collectable: Collectable2D in collectables:
		if !collectable.is_immune():
			apply_vacuum(collectable)

func _on_body_entered(body: Node2D) -> void:
	var collectable: Collectable2D = body as Collectable2D
	if is_instance_valid(collectable):
		collectables.append(collectable)

func _on_body_exited(body: Node2D) -> void:
	var collectable: Collectable2D = body as Collectable2D
	if is_instance_valid(collectable):
		collectables.erase(collectable)

func apply_vacuum(collectable: Collectable2D) -> void:
	var direction: Vector2 = collectable.global_position.direction_to(global_position)
	var distance_squared: float = collectable.global_position.distance_squared_to(global_position)
	
	if distance_squared < (collect_distance * collect_distance):
		_collected_count += 1
		collected.emit()
		collectable.queue_free()
	else:
		var force: float = vacuum_force / distance_squared
		collectable.apply_force(direction * vacuum_force, Vector2.ZERO) 
