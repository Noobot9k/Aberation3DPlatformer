extends Area3D

func touched(other : Node3D):
	print("TOUCHED!")
	#if (other.is_in_group("Player")):	# redundant if the area3D is set to only
										# test for the player group anyway.
	get_tree().call_group("level_handler", "aquire_completion_pickup")
	queue_free()
