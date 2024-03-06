extends CharacterBody3D
class_name CharacterController

@export var Ability_Wallrun : bool = false

@export var move_speed : float = 10
@export var acceleration : float = 16.0
@export var deceleration : float = 32.0
@export var airAcceleration : float = 16.0
@export var wallRunAcceleration : float = 16
@export var runningSlerp_TurnRate : float = 4
@export var runningSlerp_LowSpeedMultiplier : float = 10

@export var jump_bufferMS : float = 200
@export var jump_cooldownMS : float = 100
@export var jump_force : float = 10.0
@export var jump_off_wall_force : float = 12.5
## must be <= jump_cooldownMS
@export var jump_coyote_timingMS : float = 100.0

@export var wall_run_magnet_force : float = 3.5
@export var wall_run_angle_max : float = deg_to_rad(100)
@export var wall_run_angle_min : float = deg_to_rad(65)

@export var gravity_jumping : float = 25
@export var gravity_falling : float = 50
@export var gravity_wall_running : float = 10
@export var gravity_wall_running_falling : float = 5

@export var visualRotationLerpSpeed : float = .25

var last_is_on_floor : bool = false
var last_is_wallrunning : bool = false
var last_is_on_floor_tick : float = 0
var last_is_wallrunning_tick : float = 0
var jump_input_last_tick : float = 0
var jump_last_tick : float = 0
var move_vector : Vector3
var facing_angle : float
var is_wall_running : bool = false

@onready var model : Node3D = get_node("Visual")
@onready var camera : Camera3D = get_viewport().get_camera_3d()

signal Jumped
signal Landed

func project_on_plane(point : Vector3, plane : Vector3):
	return point - point.project(plane)

func _physics_process(delta):
	var tick : float = ScaledTime.CurrentTime # Time.get_unix_time_from_system()
	
	var wall_angle : float = get_wall_normal().angle_to(Vector3.UP)
	is_wall_running = is_on_wall_only() and wall_angle < wall_run_angle_max and wall_angle > wall_run_angle_min and Ability_Wallrun
	
	if is_on_floor(): last_is_on_floor_tick = tick
	if is_wall_running: last_is_wallrunning_tick = tick
	
	# gravity
	if not is_on_floor():
		if is_wall_running: # and velocity.y < 0:
			if velocity.y > 0:
				velocity.y -= gravity_wall_running * delta
			else:
				velocity.y -= gravity_wall_running_falling * delta
			
			var maxJumpHeight = 0.5 * (jump_force * jump_force / gravity_jumping) # calculate normal max jump height
			var maxVertVel = sqrt(2*gravity_wall_running*maxJumpHeight) # clamp max vertical velocity to not exceed normal jump height
			velocity.y = clamp(velocity.y, -maxVertVel, maxVertVel)
		elif velocity.y >= 0 and Input.is_action_pressed("jump"):
			velocity.y -= gravity_jumping * delta
		else:
			velocity.y -= gravity_falling * delta
	
	# jumping
	if Input.is_action_just_pressed("jump"):
		jump_input_last_tick = tick
	
	if tick - jump_input_last_tick < jump_bufferMS/1000 and tick - jump_last_tick > jump_cooldownMS/1000:
		if (is_wall_running and last_is_wallrunning):# or tick - last_is_wallrunning_tick < jump_coyote_timingMS/1000:
			velocity = (get_wall_normal() + Vector3.UP).normalized() * jump_off_wall_force
			jump_input_last_tick = 0
			jump_last_tick = tick
			Jumped.emit()
		elif (is_on_floor() and last_is_on_floor) or tick - last_is_on_floor_tick < jump_coyote_timingMS/1000:
			# Make sure the player is on the floor for at least 2 frames or the floating disk won't reset.
			
			velocity.y = jump_force
			jump_input_last_tick = 0
			jump_last_tick = tick
			Jumped.emit()
	
	if last_is_on_floor != is_on_floor():
		last_is_on_floor = is_on_floor()
		if is_on_floor(): Landed.emit()
	
	# walking
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	move_vector = Vector3(input.x, 0, input.y)
	var camPivot = camera.get_parent_node_3d().get_parent_node_3d()
	var cameraFlattenedTransform : Transform3D = Transform3D().looking_at((camera.global_basis * Vector3.FORWARD) * Vector3(1,0,1))
	move_vector = cameraFlattenedTransform.basis * move_vector #camPivot.to_global(move_vector) - camPivot.to_global(Vector3.ZERO)
	if is_wall_running and move_vector.length() > 0:
		move_vector = project_on_plane(move_vector, get_wall_normal()).normalized() * move_vector.length()
	
	var rateOfVelocityChange : float = deceleration
	var turnedVelocity : Vector3 = Vector3(velocity.x, 0, velocity.z)
	if not is_on_floor():
		if is_wall_running:
			rateOfVelocityChange = wallRunAcceleration
		else:
			rateOfVelocityChange = airAcceleration
	elif input.length() > 0 and (velocity.length() <= 0 or move_vector.normalized().dot(velocity.normalized())>0):
		rateOfVelocityChange = acceleration
		var inverseSpeedAlpha = 1-(turnedVelocity.length() / move_speed)
		var blend = 1-pow(0.5, delta * runningSlerp_TurnRate * (1+inverseSpeedAlpha*runningSlerp_LowSpeedMultiplier))
		turnedVelocity = turnedVelocity.slerp(move_vector.normalized() * turnedVelocity.length(), blend)
	
	velocity.x = move_toward(turnedVelocity.x, move_vector.x * move_speed, rateOfVelocityChange * delta)
	velocity.z = move_toward(turnedVelocity.z, move_vector.z * move_speed, rateOfVelocityChange * delta)
	
	# wall running
	if is_wall_running and tick - jump_last_tick > jump_cooldownMS/1000:
		velocity = project_on_plane(velocity, get_wall_normal()) + -get_wall_normal() * wall_run_magnet_force
	
	if last_is_wallrunning != is_wall_running:
		last_is_wallrunning = is_wall_running
	
	move_and_slide()
	
	# rotate to face walking direction
	#if input.length() > 0:
	#	facing_angle = Vector2(velocity.z, velocity.x).angle()
	#	model.rotation.y = lerp_angle(model.rotation.y, facing_angle, visualRotationLerpSpeed)
	
	# void out
	if global_position.y < -5:
		game_over()

func game_over():
	get_tree().reload_current_scene()
