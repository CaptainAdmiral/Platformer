extends PlayerState

class_name PlayerStateWallHug

func _init(player, name, animation).(player, name, animation):
	self.air_only = true
	
func on_start():
	.on_start()
	for i in player.get_slide_count():
		var norm = player.get_slide_collision(i).normal
		
		if norm == Vector2(1, 0) and Input.is_action_pressed("left"):
			player.setFacing(Direction.LEFT)
			break
		if norm == Vector2(-1, 0) and Input.is_action_pressed("right"):
			player.setFacing(Direction.RIGHT)
			break
	
func is_valid():
	return player.is_on_wall() and .is_valid()
	
func update():
	if Input.is_action_pressed("right"):
		player.motion.x += 50
	if Input.is_action_pressed("left"):
		player.motion.x -= 50
	.update()
