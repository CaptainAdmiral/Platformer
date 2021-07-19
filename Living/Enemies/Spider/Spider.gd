extends Living

var speed = 300
var acceleration = 50


# Called when the node enters the scene tree for the first time.
func _ready():
	set_max_health(6)
	set_facing(facing)


func _physics_process(delta):
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
			set_facing(Direction.LEFT)
		else:
			set_facing(Direction.RIGHT)


func _on_AttackHitbox_body_entered(player):
	var ap = AttackProperties.new(self, 1, AttackProperties.TYPE.PHYSICAL)
