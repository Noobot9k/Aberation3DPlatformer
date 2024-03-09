extends LevelLogic

@export var gravity_vector_default : Vector3 = Vector3.DOWN
@export var gravity_vectors_per_pickup : Array[Vector3]

func _ready():
	set_global_gravity_vector(gravity_vector_default)
	
	completion_pickups_changed.connect(func():
		set_global_gravity_vector(gravity_vectors_per_pickup[completion_pickups_current-1])
		pass
	)

func set_global_gravity_vector(new_vector : Vector3):
	PhysicsServer3D.area_set_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR, new_vector)
