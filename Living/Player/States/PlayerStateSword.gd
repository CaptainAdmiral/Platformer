extends PlayerState

class_name PlayerStateSword

const STARTUP_FRAMES = 2
const ACTIVE_FRAMES = 3
const END_LAG_FRAMES = 16

func _init(player).(player, "sword",""):
	self.duration = STARTUP_FRAMES + ACTIVE_FRAMES + END_LAG_FRAMES

func priority():
	return 2
	
func update():
	if frame == STARTUP_FRAMES:
		pass #Spawn hitbox
	
	.update()
