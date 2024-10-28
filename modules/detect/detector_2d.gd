# code by my-koala ͼ•ᴥ•ͽ #
@tool
extends Node2D
class_name Detector2D

# TODO:
# add raycasting, detectable radius

const ROTATION_OFFSET: float = PI / 2.0

signal detectable_entered(detectable: Detectable2D)
signal detectable_exited(detectable: Detectable2D)

func get_detectables() -> Array[Detectable2D]:
	return _detectables.duplicate()

func get_detectable_count() -> int:
	return _detectables.size()

func get_detectable(index: int) -> Detectable2D:
	return _detectables[index]

@export
var enabled: bool = true

@export_range(0.0, 1024.0, 1.0, "or_greater")
var vision_radius: float = 256.0:
	get:
		return vision_radius
	set(value):
		vision_radius = maxf(value, 0.0)
		queue_redraw()

@export_range(0.0, 360.0, 1.0, "radians_as_degrees")
var vision_theta: float = 0.375 * TAU:
	get:
		return vision_theta
	set(value):
		vision_theta = clampf(value, 0.0, TAU)
		queue_redraw()

@export_exp_easing("attenuation", "positive_only")
var vision_attenuation: float = 0.75:
	get:
		return vision_attenuation
	set(value):
		vision_attenuation = maxf(0.0, value)
		queue_redraw()

@export_flags_2d_physics
var collision_mask: int = 1

@export
var debug_draw: bool = false:
	get:
		return debug_draw
	set(value):
		debug_draw = value
		queue_redraw()

var _detectables: Array[Detectable2D] = []

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	var detectables: Array[Detectable2D] = []
	if enabled:
		var exclude: Array[RID] = []
		
		var dss: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
		
		# first point check
		var point_query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
		point_query.collide_with_areas = true
		point_query.collide_with_bodies = false
		point_query.collision_mask = collision_mask
		point_query.exclude = exclude
		point_query.position = global_position
		var point_query_results: Array[Dictionary] = dss.intersect_point(point_query)
		for query_result: Dictionary in point_query_results:
			var rid: RID = query_result[&"rid"] as RID
			exclude.append(rid)
			
			var detectable: Detectable2D = query_result[&"collider"] as Detectable2D
			if !is_instance_valid(detectable):
				continue
			
			detectables.append(detectable)
		
		var shape_query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		shape_query.collide_with_areas = true
		shape_query.collide_with_bodies = false
		shape_query.collision_mask = collision_mask
		shape_query.exclude = exclude
		shape_query.margin = 0.0
		shape_query.motion = Vector2.ZERO
		var shape_rid: RID = PhysicsServer2D.circle_shape_create()
		PhysicsServer2D.shape_set_data(shape_rid, vision_radius)
		shape_query.shape_rid = shape_rid
		shape_query.transform = global_transform
		
		var shape_query_results: Array[Dictionary] = dss.intersect_shape(shape_query)
		for query_result: Dictionary in shape_query_results:
			var detectable: Detectable2D = query_result[&"collider"] as Detectable2D
			if !is_instance_valid(detectable):
				continue
			
			var theta: float = global_position.angle_to_point(detectable.global_position)
			if absf(angle_difference(theta, ROTATION_OFFSET + global_rotation)) > vision_theta / 2.0:
				continue# Outside vision cone #
				
			
			detectables.append(detectable)
		PhysicsServer2D.free_rid(shape_rid)
	
	# dont use attenuation (for now). just report detectable
	#var distance_squared: float = global_position.distance_squared_to(detectable.global_position)
	#var vision_power: float = pow(1.0 - (distance_squared / (vision_radius * vision_radius)), vision_attenuation)
	
	for detectable: Detectable2D in _detectables:
		if !detectables.has(detectable):
			_detectables.erase(detectable)
			detectable_exited.emit.call_deferred(detectable)
	
	for detectable: Detectable2D in detectables:
		if !_detectables.has(detectable):
			_detectables.append(detectable)
			detectable_entered.emit.call_deferred(detectable)

func _draw() -> void:
	if !debug_draw:
		return
	
	if is_zero_approx(vision_radius) || is_zero_approx(vision_theta):
		return
	
	const ARC_POINTS: int = 32
	#var color: Color = ProjectSettings.get_setting("debug/shapes/collision/shape_color", Color(1.0, 1.0, 1.0, 0.5))
	var color: Color = Color(1.0, 0.5, 0.5, 1.0)
	var color_fill: Color = color * Color(1.0, 1.0, 1.0, 0.5)
	var color_line: Color = color * Color(1.0, 1.0, 1.0, 1.0)
	
	if is_equal_approx(vision_theta, TAU):
		draw_circle(Vector2.ZERO, vision_radius, color_fill)
	else:
		var points: PackedVector2Array = []
		points.append(Vector2.ZERO)
		var point_theta: float = vision_theta / float(ARC_POINTS)
		for point: int in range(ARC_POINTS + 1):
			points.append(vision_radius * Vector2.from_angle(ROTATION_OFFSET + float(point) * point_theta - (vision_theta / 2.0)))
		draw_polygon(points, PackedColorArray([color_fill]))
	
	draw_arc(Vector2.ZERO, vision_radius, 0.0, TAU, ARC_POINTS, color_line, -1.0, false)
	var theta_a: float = ROTATION_OFFSET + (vision_theta / 2.0)
	var theta_b: float = ROTATION_OFFSET - (vision_theta / 2.0)
	var bound_a: Vector2 = vision_radius * Vector2.from_angle(theta_a)
	var bound_b: Vector2 = vision_radius * Vector2.from_angle(theta_b)
	draw_line(Vector2.ZERO, bound_a, color_line, -1.0, false)
	draw_line(Vector2.ZERO, bound_b, color_line, -1.0, false)
	var perc_75: float = vision_radius * (1.0 - pow(0.75, 1.0 / vision_attenuation))
	var perc_50: float = vision_radius * (1.0 - pow(0.50, 1.0 / vision_attenuation))
	var perc_25: float = vision_radius * (1.0 - pow(0.25, 1.0 / vision_attenuation))
	draw_arc(Vector2.ZERO, perc_75, theta_a, theta_b, ARC_POINTS, Color(color_line, 0.75), -1.0, false)
	draw_arc(Vector2.ZERO, perc_50, theta_a, theta_b, ARC_POINTS, Color(color_line, 0.50), -1.0, false)
	draw_arc(Vector2.ZERO, perc_25, theta_a, theta_b, ARC_POINTS, Color(color_line, 0.25), -1.0, false)
