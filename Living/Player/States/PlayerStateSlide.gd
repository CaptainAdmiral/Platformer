extends PlayerState

class_name PlayerStateSlide

const SLIDE_START_SPEED = 800
const SLIDE_MIN_SPEED = 400
const SLIDE_SLOWDOWN = 0.96
const SLIDE_BOOST = 400 # How far the player has to be from a slideable gap to not slow down on the approach

func _init(player).(player, "slide","slide"):
	self.ground_only = true
	self.duration = 30
	
func on_start():
	.on_start()
	player.set_crouch(true)
	player.motion.x += player.getSignForDirection()*SLIDE_START_SPEED
	
func on_finish():
	.on_finish()
	player.set_crouch(false)
	
func is_valid():
	if !player.canStand():
		return true
	return .is_valid()
	
func priority():
	return 3
	
func is_transition_to_valid(newState : LivingState, ignorePriority = false):
	return player.canStand() and .is_transition_to_valid(newState, ignorePriority)

func update():
	# No friction if the player would slide into a hole they can't stand up in
	var space_state = player.get_world_2d().direct_space_state
	var collision = space_state.intersect_ray( \
			Vector2(player.position.x, player.position.y-player.get_node("Hitbox").shape.extents.y), \
			player.position + Vector2(player.getSignForDirection()*SLIDE_BOOST*(duration-frame)/duration, 0), \
			[player],1)
	
	if !collision:
		player.motion.x *= SLIDE_SLOWDOWN
		player.motion.x = player.getSignForDirection()*max(SLIDE_MIN_SPEED, abs(player.motion.x))
	else:
		player.motion.x = player.getSignForDirection()*max(SLIDE_START_SPEED, abs(player.motion.x))
	
	if player.is_swinging():
		stop()
		if is_current_state():
			player.hook.setDead()
		else:
			return
			
	.update()
