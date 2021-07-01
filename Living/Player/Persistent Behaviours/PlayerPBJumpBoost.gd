extends PersistentBehaviour

class_name PlayerPBJumpBoost

const JUMP_BOOST_SPEED = 60

func _init(player, duration).(player, "jump_boost", duration):
	pass
	

func update():
	if !Input.is_action_pressed("up"):
		set_finished()
	
	living.motion.y -= JUMP_BOOST_SPEED
	
	.update()
