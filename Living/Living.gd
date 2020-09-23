extends KinematicBody2D
class_name Living

export var maxHealth : int = 0
var health : float
var isDead = false
export var countsAsKill : bool = true
export var fallSpeed : int = 30
#Whether or not the player can pull with the grappling hook
export var canBePulled : bool = false
#A higher knockback multiplier will result in more knockback taken
export var knockbackMultiplier : float = 1
var motion = Vector2()
var Direction = Globals.Direction
export(Globals.Direction) var facing = Globals.Direction.RIGHT

# Called when the node enters the scene tree for the first time.
func _ready():
	health = maxHealth

#Sets the direction the entity is facing
#You should override this if inverting the scale is not desired such as
#When you have a node that should always be on the left/right side
func setFacing(direction) -> void:
	assert(direction == Direction.LEFT or direction == Direction.RIGHT)
	if facing == direction:
		return
	
	scale.x*=-1
	facing = direction
		
func _physics_process(delta):
	motion.y += fallSpeed
	
	if(is_on_floor() and motion.y > fallSpeed):
		motion.y = fallSpeed

#Directly decreases health by the given amount
func damage(amount : float) -> void:
	assert(amount > 0)
	health -= amount
	if health <= 0:
		setDead()

#Directly increases health by the given amount
func heal(amount : float) -> void:
	assert(amount > 0)
	health = min(maxHealth, health + amount)
	
#Called as a result of being damaged to allow entities to handle their own
#being hurt logic
func hurt(damage : Damage) -> bool:
	damage(damage.amount)
	if isDead and damage.source != null and damage.source.is_in_group("players"):
		damage.source.onKill(self)
	return true
	
#Called when hit if entitiy is part of "attackable" group
func onAttacked(damage : Damage) -> void:
	pass

#Adds a knockback vector to the players motion. If overwrite motion is true sets player motion instead
func addKnockback(knockback : Vector2, overwriteMotion : bool = false) -> void:
	if overwriteMotion:
		motion = Vector2(0,0)
	motion += knockback*knockbackMultiplier
	
#Marks the entity to be freed and handles death logic
func setDead() -> void:
	isDead = true
	queue_free()

