extends KinematicBody2D
class_name Living

signal died # Emitted when any living is set dead, before queue_free()
signal hurt(attackProperties) # Emitted when damaged by any source
signal post_hurt(attackProperties) # Emitted when damaged after hurt logic has completed
signal state_changed # Emitted whenever the state changes
signal landed # Emitted on the first frame the entity touches the ground
signal left_ground # Emitted on the first frame the entity leaves the ground

var max_health : int = 1 setget set_max_health
var health : int
var is_dead = false
var counts_as_kill : bool = true
var fall_speed : int = 30
var knockback_multiplier : float = 1 # A higher knockback multiplier will result in more knockback taken
var mana_on_kill : int = 0
var motion : Vector2 = Vector2()
var prev_motion : Vector2 = Vector2()
var snap_to_ground = false
var freeze_frames : int
var handle_own_movement : bool = false
export(Direction.DIRECTION_X) var facing = Direction.RIGHT
var on_ground = false
var prev_on_ground = false # Has whatever value onGround had last frame
var last_on_ground : int = 0
var last_in_air : int = 0
var state = null setget set_state
var persistent_behaviours = []

# Called when the node enters the scene tree for the first time.
func _ready():
	health = max_health
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
	
	prev_on_ground = on_ground
	on_ground = is_on_floor()
	
	if on_ground:
		last_in_air += 1
		if !prev_on_ground:
			on_land()
			last_on_ground = 0
	else:
		last_on_ground += 1
		if prev_on_ground:
			on_leave_ground()
			last_in_air = 0
	
	if abs(motion.x) < 20:
		motion.x = 0
	
	if !freeze_frames:
		if !on_ground:
			motion.y += fall_speed
		else:
			motion.y += 1
		
	
	if(is_on_floor() and motion.y > fall_speed):
		motion.y = fall_speed
	if !handle_own_movement and !freeze_frames:
		prev_motion = motion
		
		if snap_to_ground:
			motion = move_and_slide_with_snap(motion, Vector2(0, 100), Vector2(0, -1), true, 4, 0.79)
		else:
			motion = move_and_slide(motion, Vector2(0, -1))
		
	if freeze_frames:
		freeze_frames -= 1
		
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
func set_facing(direction) -> void:
	assert(direction == Direction.LEFT or direction == Direction.RIGHT)
	if facing == direction:
		return
	
	scale.x*=-1
	facing = direction
	
func turn_around():
	if facing == Direction.RIGHT:
		set_facing(Direction.LEFT)
	elif facing == Direction.LEFT:
		set_facing(Direction.RIGHT)
	
func set_max_health(amount : int) -> void:
	max_health = amount
	health = amount
		
#Does not add freeze frames to the existing number of frames, instead updates to whichever number is higher
func add_freeze_frames(frames : int):
# warning-ignore:narrowing_conversion
	freeze_frames = max(frames, freeze_frames)

#Directly decreases health by the given amount
func damage(amount : int) -> void:
	assert(amount >= 0)
	health -= amount
	if health <= 0:
		set_dead()

#Directly increases health by the given amount
func heal(amount : int) -> void:
	assert(amount >= 0)
# warning-ignore:narrowing_conversion
	health = min(max_health, health + amount)
	
#Called as a result of being damaged to allow entities to handle their own
#being hurt logic
func hurt(ap : AttackProperties) -> bool:
	emit_signal("hurt", ap)
	damage(ap.damage)
	add_knockback(ap.knockback, ap.knockback_overwrites_motion)
	if is_dead and ap.source != null and ap.source.is_in_group("players"):
		ap.source.on_kill(self)
	emit_signal("post_hurt", ap)
	return true
	
#Called when hit if entitiy is part of "attackable" group
func on_attacked(_ap : AttackProperties) -> void:
	pass

# Called on the first frame the entity touches the ground
func on_land():
	emit_signal("landed")
	
# Called on the first frame the entity touches the ground
func on_leave_ground():
	emit_signal("left_ground")

#Adds a knockback vector to the players motion. If overwrite motion is true sets player motion instead
func add_knockback(knockback : Vector2, overwriteMotion : bool = false) -> void:
	if overwriteMotion:
		motion = Vector2(0,0)
	motion += knockback*knockback_multiplier
	
#Marks the entity to be freed and handles death logic
func set_dead() -> void:
	is_dead = true
	emit_signal("died")
	queue_free()

