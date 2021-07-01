extends Reference


class_name LivingState

var name = ""
var animation : String = ""
var frame : int = 0
var duration : int = 0 # How many frames before the state returns to frame 0. If set to 0 the state will not loop.
var living : Living # The persistant thing that has the states; The state machine
var sprite : AnimatedSprite
var transition_animation : String = "" # The animation leading into the main state animation.
var lastState : String  = "" # The name of whatever state came before this one
var air_only : bool = false # If set to true state will not be considered valid on ground
var ground_only : bool = false # If set to true state will not be considered valid in air
var _priority : int = 1 setget ,priority

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func _init(living, name, sprite=null, animation = "", _priority=1):
	self.living = living
	self.name = name	
	self.sprite = sprite
	self.animation = animation
	self._priority = _priority

# Called whenever the state is transitioned to
func on_start() -> void:
	if transition_animation != "":
		sprite.play(transition_animation)
		sprite.connect("animation_finished", self, "_on_animation_finished")
	elif animation != "":
		sprite.play(animation)

# Called whenever the state is transitioned from
func on_finish() -> void:
	if transition_animation != "":
		sprite.disconnect("animation_finished", self, "_on_animation_finished")
	
func stop() -> void:
	transition_to(living.get_default_state(), true)

# The state to be transitioned to at the end of this states duration. If left as null will instead
# Transition to the living's default state
func get_next_state() -> LivingState:
	return null
	
# Is this the state the player is currently in?
func is_current_state() -> bool:
	return living.state == self

# Interface to be called by the SM class as appropriate (usually in physics update)
func update():
	if (duration > 0 and frame > duration):
		var nextState = get_next_state()
		if nextState != null:
			transition_to(nextState, true)
		else:
			transition_to(living.get_default_state(), true)
		return
			
	if !is_valid():
		stop()

# A transition into a state with the same or lower priority is usually not valid
# A higher priority means more states will cancel into this new state
func priority() -> int:
	return _priority

# Allow a transition from any of the states in the returned list
func interupts():
	return []

# Allow a transition to any of the states in the returned list
func interupted_by():
	return []

#Is it valid for this state to transition into the new state?
func is_transition_to_valid(newState : LivingState, ignorePriority = false) -> bool:
	if name in newState.interupts() or newState.name in interupted_by():
		return true
	if !newState.is_valid():
		return false
	return ignorePriority or newState.priority() > priority()
	
#Is it valid for this state to be transitioned into from the old state?
func is_transition_from_valid(oldState : LivingState) -> bool:
	return true
	
#Is the state still valid for the living
func is_valid():
	if ground_only and !living.onGround:
		return false
	elif air_only and living.onGround:
		return false
	return true
	
func transition_to(newState : LivingState, ignorePriority = false) -> bool:
	if is_transition_to_valid(newState, ignorePriority) and newState.is_transition_from_valid(self):
		on_finish()
		living.state = newState
		newState.lastState = name
		newState.on_start()
		living.on_state_change_finished()
		return true
	return false
	
func _on_animation_finished() -> void:
	if transition_animation != "":
		if sprite.animation == transition_animation:
			sprite.play(animation)
	
