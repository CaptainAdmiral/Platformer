extends PlayerState

class_name PlayerStateHurt

func _init(player).(player, "hurt",""):
	self.duration = 60
	self._priority = 5
	
func on_start():
	.on_start()
	_priority = 0
	
func update():
	.update()
