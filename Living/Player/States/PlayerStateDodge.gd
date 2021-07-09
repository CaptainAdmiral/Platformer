extends PlayerState

class_name PlayerStateDodge

var _started_on_ground

func _init(player).(player, "dodge",""):
	self.duration = 60

func priority():
	return 0 if living.on_ground else 2
	
func on_start():
	.on_start()
	_started_on_ground = living.on_ground
	
func update():	
	if frame == 30 and living.on_ground and Input.is_action_pressed("down"):
		player.is_dodging = false
		transition_to(PlayerStateHeal.new(player), true)
		
	if _started_on_ground != living.on_ground:
		stop()
		
	.update()
