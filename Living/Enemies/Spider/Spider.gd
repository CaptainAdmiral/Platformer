extends Enemy


var speed = 200


# Called when the node enters the scene tree for the first time.
func _ready():
	setFacing(facing)


func _physics_process(delta):
	move_and_slide(motion, Vector2(0, -1))
		
	if is_on_floor() and (is_on_wall() or !$FallDetector.is_colliding()):
		motion.x = -motion.x
		if facing == Direction.RIGHT:
			setFacing(Direction.LEFT)
		else:
			setFacing(Direction.RIGHT)

func setFacing(direction):
	if direction == Direction.LEFT:
		motion = Vector2(speed, 0)
	elif direction == Direction.RIGHT:
		motion = Vector2(-speed, 0)
	if facing == direction:
		return
	facing = direction
	scale.x*=-1
