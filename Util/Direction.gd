extends Node


enum DIRECTION {UP, DOWN, LEFT, RIGHT}
enum DIRECTION_X {LEFT=3, RIGHT=4}
enum DIRECTION_Y {UP=0, DOWN=1}
enum {UP, DOWN, LEFT, RIGHT}

func _ready():
	pass 

static func get_direction_from_input() -> Vector2:
	var x = 0
	var y = 0
	
	if Input.is_action_pressed("up"):
		y-=1
	if Input.is_action_pressed("down"):
		y+=1
	if Input.is_action_pressed("left"):
		x-=1
	if Input.is_action_pressed("right"):
		x+=1
												
	return Vector2(x, y).normalized()
	
static func get_input_from_direction(direction) -> String:
	if direction == Direction.LEFT:
		return "left"
	elif direction == Direction.RIGHT:
		return "right"
	elif direction == Direction.UP:
		return "up"
	elif direction == Direction.DOWN:
		return "down"
	return "err"
	
static func get_direction_to_mouse(node : Node2D) -> Vector2:
	return node.global_position.direction_to(node.get_global_mouse_position())
	
static func get_vector_for_direction(direction):
	if direction == Direction.LEFT:
		return Vector2(-1, 0)
	elif direction == Direction.RIGHT:
		return Vector2(1, 0)
	elif direction == Direction.UP:
		return Vector2(0, -1)
	elif direction == Direction.DOWN:
		return Vector2(0, 1)
	return Vector2(0, 0)
	
#Looking right because you left me
#Looking left because you ain’t treat me right
#Looking up because you let me down
#Looking down because you fucked me up
static func get_opposite_direction(direction):
	if direction == Direction.RIGHT:
		return Direction.LEFT
	elif direction == Direction.LEFT:
		return Direction.RIGHT
	elif direction == Direction.UP:
		return Direction.DOWN
	elif direction == Direction.DOWN:
		return Direction.UP
		
#Returns 1 if the direction coresponds to a positive change along the axis, else -1
static func get_sign_for_direction(direction) -> int:
	if direction == Direction.RIGHT or direction == Direction.DOWN:
		return 1
	else:
		return -1
