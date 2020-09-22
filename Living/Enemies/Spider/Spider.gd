extends Living


var speed = 300
var acceleration = 50


# Called when the node enters the scene tree for the first time.
func _ready():
	setFacing(facing)


func _physics_process(delta):
	motion = move_and_slide(motion, Vector2(0, -1))
		
	if abs(motion.x) < speed:
		if facing == Direction.RIGHT:
			motion.x = min(speed, motion.x+acceleration)
		elif facing == Direction.LEFT:
			motion.x = max(-speed, motion.x-acceleration)
	else:
		motion.x *= 0.95
		
	if is_on_floor() and (is_on_wall() or !$FallDetector.is_colliding()):	
		motion.x = -motion.x
		if facing == Direction.RIGHT:
			setFacing(Direction.LEFT)
		else:
			setFacing(Direction.RIGHT)


func _on_AttackHitbox_body_entered(player):
	attack(player, 1, Vector2(global_position.direction_to(player.global_position).x*600, -600))
