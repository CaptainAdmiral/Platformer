extends Living


var speed = 300
var acceleration = 200


# Called when the node enters the scene tree for the first time.
func _ready():
	setFacing(facing)


func _physics_process(delta):
	motion = move_and_slide(motion, Vector2(0, -1))
	for player in $AttackHitbox.get_overlapping_bodies():
		player.damage(1)
		player.applyKnockback(self, 1000)
		
	if facing == Direction.RIGHT:
		motion.x = min(speed, motion.x+acceleration)
	elif facing == Direction.LEFT:
		motion.x = max(-speed, motion.x-acceleration)
		
	if is_on_floor() and (is_on_wall() or !$FallDetector.is_colliding()):	
		motion.x = -motion.x
		if facing == Direction.RIGHT:
			setFacing(Direction.LEFT)
		else:
			setFacing(Direction.RIGHT)


func _on_AttackHitbox_body_entered(player):
	player.damage(1)
	player.applyKnockback(self, 1000)
