extends PlayerState

class_name PlayerStateRun

var direction

func _init(player, direction).(player, "run","run"):
	self.direction = direction
	self.ground_only = true
	
func on_start():
	if lastState == "idle":
		transition_animation = "run start"
	player.setFacing(direction)
	.on_start()
	
func priority():
	return 1
	
func is_transition_to_valid(newState : LivingState, ignorePriority = false):
	if newState.name == "run" and newState.direction != direction:
		return true
	return .is_transition_to_valid(newState, ignorePriority)
	
func is_valid():
	return living.onGround and Input.is_action_pressed(Direction.getInputFromDirection(direction)) and .is_valid()

func update():
	if direction == Direction.RIGHT:
		if player.motion.x < 0:
			player.motion.x *= player.GROUND_FRICTION
			player.motion.x += player.RUN_ACCELERATION
		if player.motion.x < player.RUN_SPEED:
			player.motion.x = min(player.motion.x + player.RUN_ACCELERATION, player.RUN_SPEED)
	elif direction == Direction.LEFT:
		if player.motion.x > 0:
			player.motion.x *= player.GROUND_FRICTION
			player.motion.x -= player.RUN_ACCELERATION
		if -player.motion.x < player.RUN_SPEED:
			player.motion.x = max(player.motion.x - player.RUN_ACCELERATION, -player.RUN_SPEED)
			
	if (frame >= 15 or abs(player.motion.x) >= player.RUN_SPEED*0.75) and InputBuffer.has_action("down"):
		transition_to(PlayerStateSlide.new(player))
		
	.update()
