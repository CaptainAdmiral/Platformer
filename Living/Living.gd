extends KinematicBody2D
class_name Living

export var maxHealth : int = 0
var health : float
var isDead = false
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
	
func damage(damage : float) -> void:
	assert(damage > 0)
	health -= damage
	if health <= 0:
		setDead()
		
func attack(target, damage : float, knockback : Vector2) -> void:
	if !target.hurt():
		return

	target.damage(damage)
	target.setKnockback(knockback)
	
func hurt() -> bool:
	return true
	
func setKnockback(knockback : Vector2) -> void:
	motion = knockback*knockbackMultiplier
	
func addKnockback(knockback : Vector2) -> void:
	motion += knockback*knockbackMultiplier
	
func heal(amount : float) -> void:
	assert(amount > 0)
	health = min(maxHealth, health + amount)
	
func setDead() -> void:
	queue_free()

