extends Node3D
#class_name LevelManager

var level_current_index : int = 0
var levels_path_list : Array[String] = [
	"res://WorldScenes/level_1.tscn",
	"res://WorldScenes/level_2.tscn",
	"res://WorldScenes/level_3.tscn",
	"res://WorldScenes/EndCreditsScene.tscn",
]

func go_to_next_level():
	print("going to next level")
	go_to_level(level_current_index + 1)

func go_to_level(level_index : int):
	print("going to level of index", level_index, " ", levels_path_list[level_index])
	level_current_index = level_index
	get_tree().change_scene_to_file(levels_path_list[level_index])
	pass
