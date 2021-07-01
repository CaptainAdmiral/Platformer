extends PlayerStateWallHug

class_name PlayerStateWallSlide

const WALL_SLIDE_SPEED = 120

func _init(player).(player, "wall_slide",""):
	pass

func priority():
	return 2
	
func is_valid():
	return player.motion.y >= 0 and .is_valid()
	
func update():
	if player.motion.y > WALL_SLIDE_SPEED:
		player.motion.y = max(player.motion.y*0.9, WALL_SLIDE_SPEED)
		
	.update()
