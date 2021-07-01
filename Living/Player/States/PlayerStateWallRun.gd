extends PlayerStateWallHug

class_name PlayerStateWallRun

const WALL_RUN_FLAT_ACCELERATION = 20
const WALL_RUN_CONVERSION_RATIO = 0.05

var wall_run_momentum = 0

func _init(player, wall_run_momentum).(player, "wall_run",""):
	self.wall_run_momentum = wall_run_momentum

func priority():
	return 3
	
func is_valid():
	return player.motion.y < 0 and .is_valid()
	
func update():
	if wall_run_momentum > 0:
		player.motion.y -= wall_run_momentum * WALL_RUN_CONVERSION_RATIO
		wall_run_momentum *= (1 - WALL_RUN_CONVERSION_RATIO)
		player.motion.y -= WALL_RUN_FLAT_ACCELERATION
		wall_run_momentum -= WALL_RUN_FLAT_ACCELERATION
	
	.update()
