extends Camera3D

@export var CameraFocus : CharacterBody3D
@export var FocusOffset : Vector3 = Vector3(0,1,0)
@export var Zoom : float = 6
@export var Angle_Pitch : float = 20
@export var Angle_Yaw : float = 0
@export var LerpSpeed_Horizontal : float = 5
@export var LerpSpeed_Vertical : float = .5
@export var CameraLeadTime_Horizontal : float = .333
@export var CameraLeadTime_Vertical : float = .25
@export var ReferenceChangeLerpSpeed : float = 6
@export var ObstructionAccomodationLerpSpeed : float = 6

@onready var view_occlusion_cast : ShapeCast3D = $ViewOcclusionCast

@onready var obstruction_zoom : float = Zoom
var current_offset : Vector3
var currentPos : Vector3
var gravity_basis : Basis = Basis();

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var up_direction_raw : Vector3 = CameraFocus.up_direction
	
	var gravity_basis_target : Basis = Basis.looking_at(Vector3.FORWARD, up_direction_raw)
	var reference_change_blend = 1-pow(0.5, delta * ReferenceChangeLerpSpeed)
	gravity_basis = gravity_basis.slerp(gravity_basis_target, reference_change_blend)
	var up_direction : Vector3 = gravity_basis * Vector3.UP
	
	var lead_horizontal : Vector3 = project_on_plane(CameraFocus.velocity * CameraLeadTime_Horizontal, up_direction)
	#var lead_vertical : Vector3 = (CameraFocus.velocity * CameraLeadTime_Vertical).project(up_direction)
	var offset : Vector3 = Vector3.FORWARD.rotated(Vector3.UP,  deg_to_rad(Angle_Yaw)).rotated(gravity_basis * Vector3.LEFT, deg_to_rad(Angle_Pitch))
	var focusPos : Vector3 = CameraFocus.global_position + gravity_basis * FocusOffset + lead_horizontal #+ lead_vertical
	
	var newPos : Vector3 = project_on_plane(currentPos, up_direction).lerp(project_on_plane(focusPos, up_direction), LerpSpeed_Horizontal * delta)
	var focusPos_vertical : Vector3 = focusPos.project(up_direction)
	var focusPos_vertical_signedDistance = focusPos_vertical.length() * focusPos_vertical.normalized().dot(up_direction)
	var currentPos_vertical : Vector3 = currentPos.project(up_direction)
	var currentPos_vertical_signedDistance = currentPos_vertical.length() * currentPos_vertical.normalized().dot(up_direction)
	
	if CameraFocus.is_on_floor() or CameraFocus.get("is_wall_running") or focusPos_vertical_signedDistance < currentPos_vertical_signedDistance: #focusPos.y < currentPos.y:
		#newPos.y = lerp(currentPos.y, focusPos.y, LerpSpeed_Horizontal * delta)
		newPos += up_direction * lerp(currentPos_vertical_signedDistance, focusPos_vertical_signedDistance, LerpSpeed_Horizontal * delta)
	else:
		#newPos.y = lerp(currentPos.y, focusPos.y, LerpSpeed_Vertical * delta)
		newPos += up_direction * lerp(currentPos_vertical_signedDistance, focusPos_vertical_signedDistance, LerpSpeed_Vertical * delta)
		pass
	currentPos = newPos
	
	offset = offset * -Zoom
	if not current_offset: current_offset = offset
	
	# view obstruction
	#var obstruction_zoom : float = Zoom
	refresh_view_occlusion_cast(offset)
	var obstruction_accomodation_blend = 1-pow(0.5, delta * ObstructionAccomodationLerpSpeed)
	if view_occlusion_cast.is_colliding():
		var results = view_occlusion_cast.collision_result
		for result in results:
			#result.point
			#result.normal
			
			var to_hitpoint : Vector3 = result.point - CameraFocus.global_position
			var distance_to_wall : float = to_hitpoint.project(result.normal).length()
			var target_offset : Vector3 = project_on_plane(offset, result.normal) + -result.normal * distance_to_wall
			current_offset = current_offset.lerp(target_offset, obstruction_accomodation_blend)
			
			var newResult = refresh_view_occlusion_cast(target_offset)
			if newResult:
				var to_hitpoint_new : Vector3 = result.point - CameraFocus.global_position
				var distance_to_hitpoint : float = (to_hitpoint_new).length()
				if distance_to_hitpoint < obstruction_zoom:
					obstruction_zoom = lerp(obstruction_zoom, distance_to_hitpoint, obstruction_accomodation_blend)
		pass
	else:
		current_offset = current_offset.lerp(offset, obstruction_accomodation_blend)
		obstruction_zoom = lerp(obstruction_zoom, Zoom, obstruction_accomodation_blend)
	
	var targetPos : Vector3 = currentPos + current_offset.limit_length(obstruction_zoom) #offset * -obstruction_zoom #Zoom
	global_position = targetPos
	look_at_from_position(global_position, currentPos, up_direction)

func project_on_plane(point : Vector3, plane : Vector3):
	return point - point.project(plane)

func refresh_view_occlusion_cast(offset : Vector3):
	view_occlusion_cast.global_basis = Basis()
	view_occlusion_cast.global_position = CameraFocus.global_position
	view_occlusion_cast.target_position = (CameraFocus.global_position + offset) - view_occlusion_cast.global_position # * -Zoom
	view_occlusion_cast.force_shapecast_update()
	
	if not view_occlusion_cast.is_colliding(): return null
	return view_occlusion_cast.collision_result[0]
