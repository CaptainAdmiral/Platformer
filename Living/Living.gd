extends KinematicBody2D
class_name Living

var maxHealth : int = 1 setget setMaxHealth
var health : int
var isDead = false
var countsAsKill : bool = true
var fallSpeed : int = 30
#Whether or not the player can pull with the grappling hook
var canBePulled : bool = false
#A higher knockback multiplier will result in more knockback taken
var manaOnKill : int = 0
var knockbackMultiplier : float = 1
var motion = Vector2()
var freezeFrames : int
var handleOwnMovement : bool = false
var Direction = Globals.Direction
export(Globals.Direction) var facing = Globals.Direction.RIGHT
var onGround = false
var prevOnGround = false

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	health = maxHealth
		
func _physics_process(delta):
	prevOnGround = onGround
	onGround = is_on_floor()
	
	if !freezeFrames:
		motion.y += fallSpeed
	
	if(is_on_floor() and motion.y > fallSpeed):
		motion.y = fallSpeed
	if !handleOwnMovement and !freezeFrames:
		motion = move_and_slide(motion, Vector2(0, -1))
		
	if freezeFrames:
		freezeFrames -= 1
		
#Sets the direction the entity is facing
#You should override this if inverting the scale is not desired such as
#When you have a node that should always be on the left/right side
func setFacing(direction) -> void:
	assert(direction == Direction.LEFT or direction == Direction.RIGHT)
	if facing == direction:
		return
	
	scale.x*=-1
	facing = direction
	
func turnAround():
	if facing == Direction.RIGHT:
		setFacing(Direction.LEFT)
	elif facing == Direction.LEFT:
		setFacing(Direction.RIGHT)
		
#Returns 1 if the direction coresponds to a positive change along the axis, else -1
func getSignForDirection() -> int:
	if facing == Direction.RIGHT or facing == Direction.DOWN:
		return 1
	else:
		return -1
	
func setMaxHealth(amount : int) -> void:
	maxHealth = amount
	health = amount
		
#Does not add freeze frames to the existing number of frames, instead updates to whichever number is higher
func addFreezeFrames(frames : int):
	freezeFrames = max(frames, freezeFrames)

#Directly decreases health by the given amount
func damage(amount : int) -> void:
	assert(amount >= 0)
	health -= amount
	if health <= 0:
		setDead()

#Directly increases health by the given amount
func heal(amount : int) -> void:
	assert(amount >= 0)
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

