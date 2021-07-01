extends PlayerState

class_name PlayerStateHurt

func _init(player).(player, "hurt",""):
	self.duration = 60

func priority():
	return 5
	
func is_valid():
	return Input.is_action_pressed("down") and .is_valid()
	
func update():
	.update()
