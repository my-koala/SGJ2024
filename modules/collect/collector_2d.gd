extends Area2D
class_name Collector2D

@export var vacuum_speed: float = 50.0 
var candy_list: Array = []
@export var collect_distance: float = 0.5

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	for collectable: Node2D in candy_list:
		if is_instance_valid(collectable):
			apply_vacuum(collectable)

func _on_body_entered(body: Node2D) -> void:
	if body is Collectable2D and is_instance_valid(body):
		candy_list.append(body)
		# print("Body entered: " + body.name)

func _on_body_exited(body: Node2D) -> void:
	if body in candy_list:
		candy_list.erase(body)
		# print("Body exited: " + body.name)

func apply_vacuum(collectable: RigidBody2D) -> void:
	var direction: Vector2 = global_position - collectable.global_position 
	var distance: float = direction.length()
	
	if distance < collect_distance: # IDK how far that actually is lol
		print("add the candy to the player in here")

	if distance > 1.0: # From what I've seen, this part makes it look nicer
		direction = direction.normalized()
		collectable.apply_force(direction * vacuum_speed, Vector2.ZERO) 
