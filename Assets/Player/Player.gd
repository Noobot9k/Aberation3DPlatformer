extends CharacterBody3D
class_name CharacterController

@export var particles_running : GPUParticles3D
@export var particles_jumping : GPUParticles3D

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

@export var visualRotationLerpSpeed : float = 16

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
@onready var anim_player : AnimationPlayer = find_child("AnimationPlayer", true)

signal Jumped
signal Landed

func project_on_plane(point : Vector3, plane : Vector3):
	return point - point.project(plane)

func _physics_process(delta):
	
	var tick : float = ScaledTime.CurrentTime # Time.get_unix_time_from_system()
	
	#var gravity_scale = PhysicsServer3D.body_get_param(self, PhysicsServer3D.BODY_PARAM_GRAVITY_SCALE)
	var physics_space : RID = PhysicsServer3D.body_get_space(self)
	var gravity_vector : Vector3 = PhysicsServer3D.area_get_param(physics_space, PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR)
	up_direction = -gravity_vector.normalized()
	
	var wall_angle : float = get_wall_normal().angle_to(up_direction)
	is_wall_running = is_on_wall_only() and wall_angle < wall_run_angle_max and wall_angle > wall_run_angle_min and Ability_Wallrun
	
	if is_on_floor(): last_is_on_floor_tick = tick
	if is_wall_running: last_is_wallrunning_tick = tick
	
	# gravity
	if not is_on_floor():
		var velocity_vertical_signed : float = velocity.project(up_direction).length() * velocity.project(up_direction).normalized().dot(up_direction) # velocity.y
		if is_wall_running: # and velocity.y < 0:
			if velocity_vertical_signed > 0:
				#velocity.y -= gravity_wall_running * delta
				velocity += gravity_vector * gravity_wall_running * delta
			else:
				#velocity.y -= gravity_wall_running_falling * delta
				velocity +=  gravity_vector * gravity_wall_running_falling * delta
			
			var maxJumpHeight = 0.5 * (jump_force * jump_force / gravity_jumping) # calculate normal max jump height
			var maxVertVel = sqrt(2*gravity_wall_running*maxJumpHeight) # clamp max vertical velocity to not exceed normal jump height
			
			#velocity.y = clamp(velocity.y, -maxVertVel, maxVertVel)
			# these 3 lines do the same thing as the single line above but indipendent of which way is down.
			var projectedOnVector = velocity.project(gravity_vector.normalized())
			var projectedOnPlane = project_on_plane(velocity, gravity_vector.normalized())
			velocity = projectedOnPlane + projectedOnVector.limit_length(maxVertVel)
			
		elif velocity_vertical_signed >= 0 and Input.is_action_pressed("jump"):
			#velocity.y -= gravity_jumping * delta
			velocity += gravity_vector * gravity_jumping * delta
		else:
			#velocity.y -= gravity_falling * delta
			velocity += gravity_vector * gravity_falling * delta
	
	# jumping
	if Input.is_action_just_pressed("jump"):
		jump_input_last_tick = tick
	
	if tick - jump_input_last_tick < jump_bufferMS/1000 and tick - jump_last_tick > jump_cooldownMS/1000:
		if (is_wall_running and last_is_wallrunning):# or tick - last_is_wallrunning_tick < jump_coyote_timingMS/1000:
			velocity = (get_wall_normal() + up_direction).normalized() * jump_off_wall_force
			jump_input_last_tick = 0
			jump_last_tick = tick
			Jumped.emit()
		elif (is_on_floor() and last_is_on_floor) or tick - last_is_on_floor_tick < jump_coyote_timingMS/1000:
			# Make sure the player is on the floor for at least 2 frames or the floating disk won't reset.
			
			#velocity.y = jump_force
			velocity = project_on_plane(velocity, up_direction) + up_direction * jump_force
			
			jump_input_last_tick = 0
			jump_last_tick = tick
			Jumped.emit()
			
			if particles_jumping:
				particles_jumping.restart()
				particles_jumping.emitting = true
	
	if last_is_on_floor != is_on_floor():
		last_is_on_floor = is_on_floor()
		if is_on_floor(): Landed.emit()
	
	# walking
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	move_vector = Vector3(input.x, 0, input.y)
	#var camPivot = camera.get_parent_node_3d().get_parent_node_3d()
	var cameraFlattenedTransform : Basis = Basis.looking_at(project_on_plane(camera.global_basis * Vector3.FORWARD, up_direction), up_direction)
	move_vector = cameraFlattenedTransform * move_vector #camPivot.to_global(move_vector) - camPivot.to_global(Vector3.ZERO)
	if is_wall_running and project_on_plane(move_vector, get_wall_normal()).length() > 0.1:
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
	
	#velocity.x = move_toward(turnedVelocity.x, move_vector.x * move_speed, rateOfVelocityChange * delta)
	#velocity.z = move_toward(turnedVelocity.z, move_vector.z * move_speed, rateOfVelocityChange * delta)
	velocity = velocity.move_toward(velocity.project(up_direction) + move_vector * move_speed, rateOfVelocityChange * delta)
	
	# wall running
	if is_wall_running and tick - jump_last_tick > jump_cooldownMS/1000:
		velocity = project_on_plane(velocity, get_wall_normal()) + -get_wall_normal() * wall_run_magnet_force
	
	if last_is_wallrunning != is_wall_running:
		last_is_wallrunning = is_wall_running
	
	move_and_slide()
	
	# rotate to face walking direction
	var visualRotationBlend = 1-pow(0.5, delta * visualRotationLerpSpeed)
	if project_on_plane(velocity, up_direction).length() > 0.1: # input.length() > 0:
		#facing_angle = Vector2(velocity.z, velocity.x).angle()
		#model.rotation.y = lerp_angle(model.rotation.y, facing_angle, visualRotationLerpSpeed)
		global_basis = global_basis.slerp(Basis.looking_at(project_on_plane(velocity, up_direction), up_direction), visualRotationBlend)
	else:
		global_basis = global_basis.slerp(Basis.looking_at(global_basis * Vector3.FORWARD, up_direction), visualRotationBlend)
	
	# void out
	if global_position.y < -30:
		game_over()
	
	# particles
	if particles_running:
		var collision_radius = 0.4
		var collision_height = 1.8
		var collision_normal = Vector3.UP
		if is_on_floor():
			collision_normal = get_floor_normal()
		if is_wall_running:
			collision_normal = get_wall_normal()
		
		var pivot_pos = global_transform * (Vector3.DOWN * (collision_height/2 - collision_radius))
		var particle_pos = pivot_pos + -get_wall_normal() * collision_radius
		particles_running.global_position = particle_pos
		
		if is_on_floor() or last_is_wallrunning:
			particles_running.amount_ratio = input.limit_length(1).length()
		else:
			particles_running.amount_ratio = 0
	
	# animation
	if anim_player:
		if move_vector.length() > 0.1 and is_on_floor():
			anim_player.play("Running", -1, input.limit_length(1).length() * 2)
		else:
			anim_player.play("Idle", -1, .5)

func game_over():
	get_tree().reload_current_scene()
