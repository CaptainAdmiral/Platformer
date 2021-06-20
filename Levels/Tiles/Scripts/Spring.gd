extends Area2D


const POWER = 2000

enum DIRECTION { up, down, left, right }
export(DIRECTION) var direction


# Called when the node enters the scene tree for the first time.
func _ready():
	if direction == DIRECTION.up:
		rotation_degrees = 0
	elif direction == DIRECTION.down:
		rotation_degrees = 180
	elif direction == DIRECTION.left:
		rotation_degrees = 270
	elif direction == DIRECTION.right:
		rotation_degrees = 90


func onCollision(body):
	if body is Living:
		
		
		if direction == DIRECTION.up:
			body.position.y -= 64
			body.motion.y = -POWER
		elif direction == DIRECTION.down:
			body.motion.y = POWER
		elif direction == DIRECTION.left:
			body.motion.x = -POWER
		elif direction == DIRECTION.right:
			body.motion.x = POWER
