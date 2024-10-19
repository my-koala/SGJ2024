extends Area2D
class_name CollectorVacuum2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	pass
	# IDEA: test if collectable2d, add to some array
	# then in physics_process, apply a force every physics frame to every collectable_2d in array towards center
	# maybe export a force float for controlling power
	print("body entered! " + body.name)

func _on_body_exited(body: Node2D) -> void:
	pass
