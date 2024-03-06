extends Node

var CurrentTime : float = 0
var CurrentTime_Unscaled : float = 0

func _process(delta):
	CurrentTime += delta
	CurrentTime_Unscaled += delta / Engine.time_scale
