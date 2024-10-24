extends TextureRect
class_name PauseMenuGUI

@export var half_full_threshold: int = 50
@export var full_threshold: int = 100

@export var side_profile_node: TextureRect
@export var second_profile_node: TextureRect
@export var buttons_node: Node

@export var face_start_position: Vector2 = Vector2(-500, 100)
@export var face_end_position: Vector2 = Vector2(0, 0)
@export var face_slide_duration: float = 0.1

@export var background_start_position: Vector2 = Vector2(-500, 100)
@export var background_end_position: Vector2 = Vector2(-4, 0)
@export var background_slide_duration: float = 0.15

@export var buttons_start_position: Vector2 = Vector2(-500, 100)
@export var buttons_end_position: Vector2 = Vector2(0, 0)
@export var buttons_slide_duration: float = 0.2

func _ready() -> void:
	side_profile_node.position = face_start_position
	second_profile_node.position = background_start_position
	buttons_node.position = buttons_start_position

func update_side_profile(value: int) -> void:
	var texture: ImageTexture = ImageTexture.new()
	var backgroundTexture: ImageTexture = ImageTexture.new()

	if value < half_full_threshold:
		texture.create_from_image(load("res://assets/menu/Monster Side Profiles/Side_Profile_empty.png"))
		backgroundTexture.create_from_image(load("res://assets/menu/Monster Side Profiles/side_profile_background.png"))
	elif value < full_threshold:
		texture.create_from_image(load("res://assets/menu/Monster Side Profiles/Side_Profile_half.png"))
		backgroundTexture.create_from_image(load("res://assets/menu/Monster Side Profiles/Side_Profile_half-background.png"))
	else:
		texture.create_from_image(load("res://assets/menu/Monster Side Profiles/Side_Profile_stuffed.png"))
		backgroundTexture.create_from_image(load("res://assets/menu/Monster Side Profiles/Side_Profile_stuffed-background.png"))
		
	side_profile_node.texture = texture
	second_profile_node.texture = backgroundTexture

func show_slide() -> void:
	# Ensure both nodes are visible before sliding
	side_profile_node.visible = true
	second_profile_node.visible = true
	buttons_node.visible = true

	# Create tweens to animate both nodes in parallel
	var tween1: Tween = create_tween()
	var tween2: Tween = create_tween()
	var tween3: Tween = create_tween()

	# Slide both nodes to the end position
	tween1.tween_property(
		side_profile_node, "position", face_end_position, face_slide_duration
	)
	tween2.tween_property(
		second_profile_node, "position", background_end_position, background_slide_duration
	)
	tween3.tween_property(
		buttons_node, "position", buttons_end_position, buttons_slide_duration
	)

func hide_reset() -> void:
	# Reset both nodes to the start position and hide them
	side_profile_node.position = face_start_position
	second_profile_node.position = background_start_position
	buttons_node.position = buttons_end_position

	side_profile_node.visible = false
	second_profile_node.visible = false
