extends KinematicBody2D
class_name Living

export var maxHealth : int = 0
var health : float
export var fallSpeed : int = 30
#Whether or not the player can pull with the grappling hook
export var canPull : bool = false
#A higher knockback multiplier will result in more knockback taken
export var knockbackMultiplier : float = 1
var motion = Vector2()
var Direction = Globals.Direction
export(Globals.Direction) var facing = Globals.Direction.RIGHT

# Called when the node enters the scene tree for the first time.
func _ready():
	health = maxHealth
	
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
		
func attack(target, damage, knockback = 1000):
	target.damage(damage)
	target.applyKnockback(self, knockback)
		
func applyKnockback(from : Living, amount : float, onlyXAxis = true) -> void:
	if onlyXAxis:
		motion.x = from.global_position.direction_to(global_position).x*amount*knockbackMultiplier
		motion.y -= 100
	else:
		motion = from.global_position.direction_to(global_position)*amount*knockbackMultiplier
	
func heal(amount : float):
	assert(amount > 0)
	health = min(maxHealth, health + amount)
	
func setDead():
	queue_free()

