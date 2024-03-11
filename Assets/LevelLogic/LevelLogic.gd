extends Node3D
class_name LevelLogic

signal completion_pickups_changed;

@export var completion_pickups_required : int = 3
var completion_pickups_current : int = 0

func aquire_completion_pickup(deltaPickups : int = 1):
	print("completion pickup aquired")
	completion_pickups_current += deltaPickups
	completion_pickups_changed.emit()

func _ready():
	print("ready!")
	completion_pickups_changed.connect(func():
		print("completion pickups changed.")
		if completion_pickups_current >= completion_pickups_required:
			print("level complete")
			LevelManager.go_to_next_level()
	)
	print(completion_pickups_changed.get_connections()[0])
