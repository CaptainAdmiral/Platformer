extends PlayerState

class_name PlayerStateHurt

func _init(player).(player, "hurt",""):
	self.duration = 60

func priority():
	return 5
	
func update():
	.update()
