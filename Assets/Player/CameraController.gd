extends Camera3D

@export var CameraFocus : CharacterBody3D
@export var FocusOffset : Vector3 = Vector3(0,1,0)
@export var Zoom : float = 6
@export var Angle_Pitch : float = deg_to_rad(20)
@export var Angle_Yaw : float = deg_to_rad(0)
@export var LerpSpeed_Horizontal : float = 5
@export var LerpSpeed_Vertical : float = .5
@export var CameraLeadTime_Horizontal : float = .333
@export var CameraLeadTime_Vertical : float = .25
@export var ReferenceChangeLerpSpeed : float = 6

var currentPos : Vector3
var last_gravity_basis : Basis = Basis();

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#Angle_Pitch = deg_to_rad(sin(Time.get_unix_time_from_system()*2)*15)
	
	var up_direction : Vector3 = CameraFocus.up_direction
	
	var gravity_basis : Basis = Basis.looking_at(Vector3.FORWARD, up_direction)
	var blend = 1-pow(0.5, delta * ReferenceChangeLerpSpeed)
	last_gravity_basis = last_gravity_basis.slerp(gravity_basis, blend)
	
	var lead_horizontal : Vector3 = project_on_plane(CameraFocus.velocity * CameraLeadTime_Horizontal, up_direction)
	#var lead_vertical : Vector3 = (CameraFocus.velocity * CameraLeadTime_Vertical).project(up_direction)
	var offset : Vector3 = last_gravity_basis * Vector3.FORWARD.rotated(Vector3.LEFT, Angle_Pitch).rotated(Vector3.UP,  Angle_Yaw)
	var focusPos : Vector3 = CameraFocus.global_position + last_gravity_basis * FocusOffset + lead_horizontal #+ lead_vertical
	
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
	var targetPos : Vector3 = currentPos + offset * -Zoom
	global_position = targetPos
	look_at_from_position(global_position, currentPos, up_direction)

func project_on_plane(point : Vector3, plane : Vector3):
	return point - point.project(plane)
