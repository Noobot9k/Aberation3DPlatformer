extends Area3D

func touched(_other : Node3D):
	print("TOUCHED!")
	#if (_other.is_in_group("Player")):	# redundant if the area3D is set to only
										# test for the player group anyway.
	get_tree().call_group("level_handler", "aquire_completion_pickup", 1, global_transform)
	queue_free()
