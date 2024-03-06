extends Node3D
class_name LevelHandler

@export var completion_pickups_required : int = 3
var completion_pickups_current : int = 0

func aquire_completion_pickup(deltaPickups : int = 1):
	completion_pickups_current += deltaPickups
	completion_pickups_changed()

func completion_pickups_changed():
	if completion_pickups_current >= completion_pickups_required:
		LevelManager.go_to_next_level()
