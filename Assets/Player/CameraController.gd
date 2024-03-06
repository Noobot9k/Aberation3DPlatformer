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

var currentPos : Vector3

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#Angle_Pitch = deg_to_rad(sin(Time.get_unix_time_from_system()*2)*15)
	var lead_horizontal : Vector3 = CameraFocus.velocity * CameraLeadTime_Horizontal * Vector3(1,0,1)
	var lead_vertical : Vector3 = CameraFocus.velocity * CameraLeadTime_Vertical * Vector3(0,1,0)
	var offset : Vector3 = Vector3.FORWARD.rotated(Vector3.LEFT, Angle_Pitch).rotated(Vector3.UP,  Angle_Yaw)
	var focusPos : Vector3 = CameraFocus.global_position + FocusOffset + lead_horizontal #+ lead_vertical
	
	var newPos : Vector3 = currentPos.lerp(focusPos * Vector3(1,0,1), LerpSpeed_Horizontal * delta)
	if CameraFocus.is_on_floor() or CameraFocus.get("is_wall_running") or focusPos.y < currentPos.y:
		newPos.y = lerp(currentPos.y, focusPos.y, LerpSpeed_Horizontal * delta)
	else:
		newPos.y = lerp(currentPos.y, focusPos.y, LerpSpeed_Vertical * delta)
	currentPos = newPos
	var targetPos : Vector3 = currentPos + offset * -Zoom
	global_position = targetPos
	look_at_from_position(global_position, currentPos)
