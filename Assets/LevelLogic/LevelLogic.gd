extends Node3D
class_name LevelLogic

signal completion_pickups_changed;

@export var completion_pickups_required : int = 3
var completion_pickups_current : int = 0

@onready var checkpoint : Vector3 = get_tree().get_first_node_in_group("Player").global_position

func aquire_completion_pickup(deltaPickups : int, checkpoint_transform : Transform3D):
	print("completion pickup aquired")
	checkpoint = checkpoint_transform * Vector3.UP * 1
	completion_pickups_current += deltaPickups
	completion_pickups_changed.emit()

#func player_voidout():
	#var player : CharacterController = get_tree().get_first_node_in_group("Player")
	#if player:
		#player.global_position = Vector3.ZERO

func body_voidout(body : Node3D):
	print("body voided out", body)
	body.global_position = checkpoint

func _ready():
	print("ready!")
	completion_pickups_changed.connect(func():
		print("completion pickups changed.")
		if completion_pickups_current >= completion_pickups_required:
			print("level complete")
			LevelManager.go_to_next_level()
	)
	print(completion_pickups_changed.get_connections()[0])
