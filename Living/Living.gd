extends KinematicBody2D
class_name Living

export var maxHealth : int = 0
export var health : float = 0
export var fallSpeed : int = 30
var motion = Vector2()
var Direction = Globals.Direction
export(Globals.Direction) var facing = Globals.Direction.RIGHT

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func setFacing(direction):
	assert(direction == Direction.LEFT or direction == Direction.RIGHT)
	if facing == direction:
		return
	
	scale.x*=-1
	facing = direction
		
func _physics_process(delta):
	motion.y += fallSpeed
	
	if(is_on_floor() and motion.y > fallSpeed):
		motion.y = fallSpeed
	
func damage(damage : float):
	assert(damage > 0)
	health -= damage
	if health <= 0:
		setDead()
	
func heal(amount : float):
	assert(amount > 0)
	health = min(maxHealth, health + amount)
	
func setDead():
	pass

