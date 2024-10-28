@tool
extends EditorScript


# Called when the script is executed (using File -> Run in Script Editor).
func _run() -> void:
	print("-----")
	print(Vector2(0.0, 0.0).angle_to_point(Vector2(1.0, 0.0)))
	print(Vector2(0.0, 0.0).angle_to_point(Vector2(1.0, 1.0)))
	print(Vector2(0.0, 0.0).angle_to_point(Vector2(0.0, 1.0)))
	print(Vector2(0.0, 0.0).angle_to_point(Vector2(-1.0, 1.0)))
	print(Vector2(0.0, 0.0).angle_to_point(Vector2(-1.0, 0.0)))
	print(Vector2(0.0, 0.0).angle_to_point(Vector2(-1.0, -1.0)))
	print(Vector2(0.0, 0.0).angle_to_point(Vector2(0.0, -1.0)))
	print(Vector2(0.0, 0.0).angle_to_point(Vector2(1.0, -1.0)))
	
	print("=====")
	print(fposmod(-0.1 * PI, TAU))
