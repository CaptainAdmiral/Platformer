extends PlayerState

class_name PlayerStateAirDrift

func _init(player).(player, "air_drift","run jump"):
	self.transition_animation = "run jump"
	self.air_only = true

func priority():
	return 1
	
func update():
	if !player.is_swinging():
		if !(Input.is_action_pressed("right") and Input.is_action_pressed("left")):
			if Input.is_action_pressed("right"):
				if player.motion.x < 0:
					player.motion.x *= player.AIR_FRICTION
				if player.motion.x < player.AIR_SPEED:
					player.motion.x = min(player.motion.x + player.AIR_ACCELERATION, player.AIR_SPEED)
					
			if Input.is_action_pressed("left"):
				if player.motion.x > 0:
					player.motion.x *= player.AIR_FRICTION
				if -player.motion.x < player.AIR_SPEED:
					player.motion.x = max(player.motion.x - player.AIR_ACCELERATION, -player.AIR_SPEED)
		
		if !(Input.is_action_pressed("right") or Input.is_action_pressed("left")):
			player.motion.x *= player.AIR_FRICTION
			
		if player.motion.y > 10 and sprite.animation != "fall":
			sprite.play("fall")
			sprite.set_frame(3)
			
	.update()
