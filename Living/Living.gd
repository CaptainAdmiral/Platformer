extends KinematicBody2D
class_name Living

signal died # Emitted when any living is set dead, before queue_free()
signal hurt(damage) # Emitted when damaged by any source
signal state_changed # Emitted whenever the state changes
signal landed # Emitted on the first frame the entity touches the ground
signal left_ground # Emitted on the first frame the entity leaves the ground

var maxHealth : int = 1 setget setMaxHealth
var health : int
var isDead = false
var countsAsKill : bool = true
var fallSpeed : int = 30
var knockbackMultiplier : float = 1 # A higher knockback multiplier will result in more knockback taken
var manaOnKill : int = 0
var motion : Vector2 = Vector2()
var prevMotion : Vector2 = Vector2()
var freezeFrames : int
var handleOwnMovement : bool = false
var Direction = Globals.Direction
export(Globals.Direction) var facing = Globals.Direction.RIGHT
var onGround = false
var prevOnGround = false # Has whatever value onGround had last frame
var last_on_ground : int = 0
var last_in_air : int = 0
var state = null setget set_state
var persistent_behaviours = []

# Called when the node enters the scene tree for the first time.
func _ready():
	health = maxHealth
	if get_default_state() != null:
		state = get_default_state()
		state.on_start()
		
func _physics_process(_delta):
	if state != null:
		state.update()
		state.frame += 1
		
	for i in range(len(persistent_behaviours)-1,-1, -1):
		if persistent_behaviours[i].is_finished:
			remove_persistent_behaviour_at_index(i)
		else:
			persistent_behaviours[i].update()
	
	prevOnGround = onGround
	onGround = is_on_floor()
	
	if onGround:
		last_in_air += 1
		if !prevOnGround:
			on_land()
			last_on_ground = 0
	else:
		last_on_ground += 1
		if prevOnGround:
			on_leave_ground()
			last_in_air = 0
			
	
	if !freezeFrames:
		motion.y += fallSpeed
	
	if(is_on_floor() and motion.y > fallSpeed):
		motion.y = fallSpeed
	if !handleOwnMovement and !freezeFrames:
		prevMotion = motion
		motion = move_and_slide(motion, Vector2(0, -1))
		
	if freezeFrames:
		freezeFrames -= 1
		
func set_state(st):
	state = st
	emit_signal("state_changed")
	on_state_change()
		
# Called whenever the state changes, before the starting logic of the new state or the finishing logic for the old state.
# Any state changes made here should not use the state class's transitioning interface 
func on_state_change():
	pass

# Called whenever the old state finishes. Use of the state transitioning interface is safe.
func on_state_change_finished():
	pass

# Returns the default state the entity should return to if a state ends with no specified transition to another state
func get_default_state():
	return null
	
func has_persistent_behaviour(s : String):
	for pb in persistent_behaviours:
		if pb.name == s:
			return true
	return false

#Adds a persistent behaviour to be updated each frame
func add_persistent_behaviour(pb) :
	persistent_behaviours.append(pb)
	pb.on_start()
	
#Removes a persistent behaviour from the entity
func remove_persistent_behaviour(pb):
	var i = persistent_behaviours.find(pb)
	if i != -1:
		remove_persistent_behaviour_at_index(i)
		
#Removes a persistent behaviour from the entity	
func remove_persistent_behaviour_by_name(s : String):
	for i in range(len(persistent_behaviours)):
		if persistent_behaviours[i].name == s:
			remove_persistent_behaviour_at_index(i)
			return

#Removes a persistent behaviour from the entity	
func remove_persistent_behaviour_at_index(i : int):
	persistent_behaviours[i].on_finish()
	persistent_behaviours.remove(i)
	
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

#Looking right because you left me
#Looking left because you ain’t treat me right
#Looking up because you let me down
#Looking down because you fucked me up
func getOppositeDirection(direction = facing):
	if direction == Direction.RIGHT:
		return Direction.LEFT
	elif direction == Direction.LEFT:
		return Direction.RIGHT
	elif direction == Direction.UP:
		return Direction.DOWN
	elif direction == Direction.DOWN:
		return Direction.UP
		
#Returns 1 if the direction coresponds to a positive change along the axis, else -1
func getSignForDirection(direction = facing) -> int:
	if direction == Direction.RIGHT or direction == Direction.DOWN:
		return 1
	else:
		return -1
	
func setMaxHealth(amount : int) -> void:
	maxHealth = amount
	health = amount
		
#Does not add freeze frames to the existing number of frames, instead updates to whichever number is higher
func addFreezeFrames(frames : int):
# warning-ignore:narrowing_conversion
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
# warning-ignore:narrowing_conversion
	health = min(maxHealth, health + amount)
	
#Called as a result of being damaged to allow entities to handle their own
#being hurt logic
func hurt(damage : Damage) -> bool:
	emit_signal("hurt", damage)
	damage(damage.amount)
	if isDead and damage.source != null and damage.source.is_in_group("players"):
		damage.source.onKill(self)
	return true
	
#Called when hit if entitiy is part of "attackable" group
func onAttacked(_damage : Damage) -> void:
	pass

# Called on the first frame the entity touches the ground
func on_land():
	emit_signal("landed")
	
# Called on the first frame the entity touches the ground
func on_leave_ground():
	emit_signal("left_ground")

#Adds a knockback vector to the players motion. If overwrite motion is true sets player motion instead
func addKnockback(knockback : Vector2, overwriteMotion : bool = false) -> void:
	if overwriteMotion:
		motion = Vector2(0,0)
	motion += knockback*knockbackMultiplier
	
#Marks the entity to be freed and handles death logic
func setDead() -> void:
	isDead = true
	emit_signal("died")
	queue_free()

