extends Node3D
class_name LevelLogic

signal completion_pickups_changed;

@export var completion_pickups_required : int = 3
var completion_pickups_current : int = 0

func aquire_completion_pickup(deltaPickups : int = 1):
	completion_pickups_current += deltaPickups
	completion_pickups_changed.emit()

func _ready():
	completion_pickups_changed.connect(func():
		if completion_pickups_current >= completion_pickups_required:
			LevelManager.go_to_next_level()
	)
