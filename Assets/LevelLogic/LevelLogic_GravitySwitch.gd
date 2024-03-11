extends LevelLogic

@export var gravity_vector_default : Vector3 = Vector3.DOWN
@export var gravity_vectors_per_pickup : Array[Vector3]

func _ready():
	super()
	set_global_gravity_vector(gravity_vector_default)
	
	completion_pickups_changed.connect(func():
		set_global_gravity_vector(gravity_vectors_per_pickup[completion_pickups_current-1])
	)

func set_global_gravity_vector(new_vector : Vector3):
	var world = get_world_3d()
	if not world: return
	PhysicsServer3D.area_set_param(world.space, PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR, new_vector)
	get_tree().call_group("DecorationDebris", "set_sleeping",  false)
