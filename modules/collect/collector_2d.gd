extends Area2D
class_name Collector2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	pass
	# if body is Collectable2D, then uhh delete it (for now) and increment a int counter
	# we can do a ui to read this int later

func _on_body_exited(body: Node2D) -> void:
	pass
