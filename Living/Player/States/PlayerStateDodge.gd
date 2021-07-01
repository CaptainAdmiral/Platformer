extends PlayerState

class_name PlayerStateDodge

var _started_on_ground

func _init(player).(player, "dodge",""):
	self.duration = 60

func priority():
	return 0 if living.onGround else 2
	
func on_start():
	.on_start()
	_started_on_ground = living.onGround
	
func update():	
	if frame == 30 and living.onGround and Input.is_action_pressed("down"):
		player.isDodging = false
		transition_to(PlayerStateHeal.new(player), true)
		
	if _started_on_ground != living.onGround:
		stop()
		
	.update()
