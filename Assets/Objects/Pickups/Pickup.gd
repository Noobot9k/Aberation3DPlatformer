extends Area3D

func touched(other : Node3D):
	if (other.is_in_group("Player")):
		get_tree().call_group("level_handler", "aquire_completion_pickup")
		queue_free()
